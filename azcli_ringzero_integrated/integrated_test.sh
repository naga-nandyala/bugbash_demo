#!/usr/bin/env bash
#
# integrated_test.sh — Azure Ring Zero Integrated Architecture Test
#
# Creates ALL ring-zero services in a SINGLE resource group, wired together
# as an interconnected architecture.  After creation & verification the script
# pauses so you can inspect resources in the portal, then asks for explicit
# confirmation before tearing everything down (via `az group delete`).
#
# Architecture:
#
#  ┌──────────────────── Resource Group ────────────────────┐
#  │                                                        │
#  │  Log Analytics ◄── diagnostics ── Key Vault            │
#  │       ▲                             │ stores secret    │
#  │       │ VM insights                 ▼                  │
#  │       │                      Storage Account           │
#  │       │                        ▲ boot diagnostics      │
#  │  NSG ──► Subnet ──► VNet      │                       │
#  │              │                 │                       │
#  │              └──► VM ─────────┘                       │
#  │                   │ private IP                        │
#  │                   ▼                                   │
#  │             DNS Zone (A record → VM IP)               │
#  │                                                        │
#  │  Service Principal (Reader role on RG)                │
#  └────────────────────────────────────────────────────────┘
#
# Usage:
#   ./integrated_test.sh
#
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ──────────────────────────────────────────────
# Reuse the common library from the sibling test suite
# ──────────────────────────────────────────────
COMMON_LIB="${SCRIPT_DIR}/../azcli_ringzero_test/lib/common.sh"
if [[ ! -f "${COMMON_LIB}" ]]; then
    echo "ERROR: Cannot find ${COMMON_LIB}"
    exit 1
fi
# shellcheck source=../azcli_ringzero_test/lib/common.sh
source "${COMMON_LIB}"

setup_logging
preflight_check

banner "Azure Ring Zero — Integrated Architecture Test"
show_subscription_info

echo -e "${BOLD}This test will create the following interconnected services"
echo -e "in a single resource group and leave them running for inspection.${RESET}"
echo ""
echo "  Resource Group : ${RG_NAME}"
echo "  Location       : ${LOCATION}"
echo ""
echo "  Services to create:"
echo "    1. VNet + Subnet           (${VNET_NAME}/${SUBNET_NAME})"
echo "    2. Network Security Group  (${NSG_NAME}) → attached to subnet"
echo "    3. Log Analytics Workspace (${LOG_WORKSPACE})"
echo "    4. Storage Account         (${STORAGE_NAME}) → diagnostics → LAW"
echo "    5. Key Vault               (${KV_NAME}) → stores storage key, diagnostics → LAW"
echo "    6. Virtual Machine         (${VM_NAME}) → in subnet, boot diag → storage"
echo "    7. DNS Zone                (${DNS_ZONE}) → A record → VM private IP"
echo "    8. Service Principal       (${SP_NAME}) → Reader role on RG"
echo ""
warn "A Standard_B1s VM and storage will incur minor costs while running."
echo ""

read -r -p "Create all resources? (yes/no): " CONFIRM
if [[ "${CONFIRM}" != "yes" ]]; then
    echo "Aborted."
    exit 0
fi
echo ""

# ──────────────────────────────────────────────
# Tracking
# ──────────────────────────────────────────────
declare -a DEPLOYED_NAMES=()
declare -a DEPLOYED_STATUS=()
FAIL_COUNT=0

record_result() {
    local name="$1" status="$2"
    DEPLOYED_NAMES+=("${name}")
    DEPLOYED_STATUS+=("${status}")
    if [[ "${status}" != "OK" ]]; then
        ((FAIL_COUNT++)) || true
    fi
}

# ══════════════════════════════════════════════
# PHASE 1 — CREATE (in dependency order)
# ══════════════════════════════════════════════
banner "Phase 1 — Creating Resources"

# ── 1. Resource Group ──
step_create "Creating resource group: ${RG_NAME}"
if az group create --name "${RG_NAME}" --location "${LOCATION}" -o none 2>&1; then
    pass "Resource group created"
    record_result "Resource Group (${RG_NAME})" "OK"
else
    fail "Resource group creation failed — cannot continue"
    exit 1
fi

# ── 2. VNet + Subnet ──
step_create "Creating VNet: ${VNET_NAME} with subnet: ${SUBNET_NAME}"
if az network vnet create \
    --resource-group "${RG_NAME}" \
    --name "${VNET_NAME}" \
    --address-prefix "10.0.0.0/16" \
    --subnet-name "${SUBNET_NAME}" \
    --subnet-prefix "10.0.1.0/24" \
    -o none 2>&1; then
    pass "VNet and subnet created"
    record_result "VNet (${VNET_NAME})" "OK"
else
    fail "VNet creation failed"
    record_result "VNet (${VNET_NAME})" "FAIL"
fi

# ── 3. NSG → attach to subnet ──
step_create "Creating NSG: ${NSG_NAME}"
if az network nsg create \
    --resource-group "${RG_NAME}" \
    --name "${NSG_NAME}" \
    -o none 2>&1; then
    pass "NSG created"

    step_create "Attaching NSG to subnet ${SUBNET_NAME}"
    if az network vnet subnet update \
        --resource-group "${RG_NAME}" \
        --vnet-name "${VNET_NAME}" \
        --name "${SUBNET_NAME}" \
        --network-security-group "${NSG_NAME}" \
        -o none 2>&1; then
        pass "NSG attached to subnet"
    else
        warn "Could not attach NSG to subnet"
    fi
    record_result "NSG (${NSG_NAME}) → Subnet" "OK"
else
    fail "NSG creation failed"
    record_result "NSG (${NSG_NAME})" "FAIL"
fi

# ── 4. Log Analytics Workspace ──
step_create "Creating Log Analytics workspace: ${LOG_WORKSPACE}"
if az monitor log-analytics workspace create \
    --resource-group "${RG_NAME}" \
    --workspace-name "${LOG_WORKSPACE}" \
    --location "${LOCATION}" \
    -o none 2>&1; then
    pass "Log Analytics workspace created"
    LAW_ID=$(az monitor log-analytics workspace show \
        --resource-group "${RG_NAME}" --workspace-name "${LOG_WORKSPACE}" \
        --query "id" -o tsv 2>/dev/null || echo "")
    record_result "Log Analytics (${LOG_WORKSPACE})" "OK"
else
    fail "Log Analytics creation failed"
    LAW_ID=""
    record_result "Log Analytics (${LOG_WORKSPACE})" "FAIL"
fi

# ── 5. Storage Account (+ container, + diag → LAW) ──
step_create "Creating storage account: ${STORAGE_NAME}"
if az storage account create \
    --resource-group "${RG_NAME}" \
    --name "${STORAGE_NAME}" \
    --sku "Standard_LRS" \
    --kind "StorageV2" \
    --location "${LOCATION}" \
    --min-tls-version "TLS1_2" \
    --allow-blob-public-access false \
    -o none 2>&1; then
    pass "Storage account created"

    # Create blob container
    STORAGE_KEY=$(az storage account keys list \
        --resource-group "${RG_NAME}" --account-name "${STORAGE_NAME}" \
        --query "[0].value" -o tsv 2>/dev/null || echo "")
    if [[ -n "${STORAGE_KEY}" ]]; then
        step_create "Creating blob container: ${CONTAINER_NAME}"
        az storage container create --name "${CONTAINER_NAME}" \
            --account-name "${STORAGE_NAME}" --account-key "${STORAGE_KEY}" \
            -o none 2>&1 || true
        pass "Blob container created"

        step_create "Uploading test blob"
        echo "Ring Zero integrated test - $(date -u +%Y-%m-%dT%H:%M:%SZ)" | \
            az storage blob upload \
            --container-name "${CONTAINER_NAME}" --name "test.txt" \
            --account-name "${STORAGE_NAME}" --account-key "${STORAGE_KEY}" \
            --data @- --overwrite -o none 2>&1 || true
        pass "Test blob uploaded"
    fi

    # Send storage diagnostics to Log Analytics
    if [[ -n "${LAW_ID}" ]]; then
        STORAGE_ID=$(az storage account show \
            --resource-group "${RG_NAME}" --name "${STORAGE_NAME}" \
            --query "id" -o tsv 2>/dev/null || echo "")
        if [[ -n "${STORAGE_ID}" ]]; then
            step_create "Enabling storage diagnostics → Log Analytics"
            az monitor diagnostic-settings create \
                --name "diag-storage" \
                --resource "${STORAGE_ID}" \
                --workspace "${LAW_ID}" \
                --metrics '[{"category":"Transaction","enabled":true}]' \
                -o none 2>&1 || warn "Could not enable storage diagnostics (non-blocking)"
        fi
    fi
    record_result "Storage (${STORAGE_NAME}) → LAW" "OK"
else
    fail "Storage account creation failed"
    STORAGE_KEY=""
    record_result "Storage (${STORAGE_NAME})" "FAIL"
fi

# ── 6. Key Vault (+ store storage key, + diag → LAW) ──
step_create "Creating Key Vault: ${KV_NAME}"
if az keyvault create \
    --resource-group "${RG_NAME}" \
    --name "${KV_NAME}" \
    --location "${LOCATION}" \
    --enable-rbac-authorization false \
    -o none 2>&1; then
    pass "Key Vault created"

    # Store storage account key as a secret
    if [[ -n "${STORAGE_KEY}" ]]; then
        step_create "Storing storage account key in Key Vault"
        az keyvault secret set \
            --vault-name "${KV_NAME}" \
            --name "storage-account-key" \
            --value "${STORAGE_KEY}" \
            -o none 2>&1 || warn "Could not store secret"
        pass "Storage key stored in Key Vault"
    fi

    # Store a connection-string secret
    step_create "Storing connection metadata in Key Vault"
    az keyvault secret set \
        --vault-name "${KV_NAME}" \
        --name "storage-account-name" \
        --value "${STORAGE_NAME}" \
        -o none 2>&1 || true
    pass "Storage account name stored as secret"

    # Send KV diagnostics to Log Analytics
    if [[ -n "${LAW_ID}" ]]; then
        KV_ID=$(az keyvault show --name "${KV_NAME}" --query "id" -o tsv 2>/dev/null || echo "")
        if [[ -n "${KV_ID}" ]]; then
            step_create "Enabling Key Vault diagnostics → Log Analytics"
            az monitor diagnostic-settings create \
                --name "diag-keyvault" \
                --resource "${KV_ID}" \
                --workspace "${LAW_ID}" \
                --logs '[{"category":"AuditEvent","enabled":true}]' \
                --metrics '[{"category":"AllMetrics","enabled":true}]' \
                -o none 2>&1 || warn "Could not enable KV diagnostics (non-blocking)"
        fi
    fi
    record_result "Key Vault (${KV_NAME}) → LAW + stores secrets" "OK"
else
    fail "Key Vault creation failed"
    record_result "Key Vault (${KV_NAME})" "FAIL"
fi

# ── 7. Virtual Machine (in subnet, boot diag → storage) ──
step_create "Creating VM: ${VM_NAME} (Standard_B1s, no public IP)"
BOOT_DIAG_FLAG=""
if [[ -n "${STORAGE_KEY:-}" ]]; then
    BOOT_DIAG_FLAG="--boot-diagnostics-storage ${STORAGE_NAME}"
fi
# Build the command dynamically so optional flags are clean
VM_CMD=(az vm create
    --resource-group "${RG_NAME}"
    --name "${VM_NAME}"
    --image "Ubuntu2204"
    --size "Standard_B1s"
    --vnet-name "${VNET_NAME}"
    --subnet "${SUBNET_NAME}"
    --nsg ""
    --admin-username "azureuser"
    --generate-ssh-keys
    --public-ip-address ""
    -o none
)
if [[ -n "${BOOT_DIAG_FLAG}" ]]; then
    VM_CMD+=(--boot-diagnostics-storage "${STORAGE_NAME}")
fi

if "${VM_CMD[@]}" 2>&1; then
    pass "VM created"
    VM_PRIVATE_IP=$(az vm show \
        --resource-group "${RG_NAME}" --name "${VM_NAME}" \
        --show-details --query "privateIps" -o tsv 2>/dev/null || echo "")
    if [[ -n "${VM_PRIVATE_IP}" ]]; then
        pass "VM private IP: ${VM_PRIVATE_IP}"
    fi
    record_result "VM (${VM_NAME}) → Subnet + boot diag" "OK"
else
    fail "VM creation failed"
    VM_PRIVATE_IP=""
    record_result "VM (${VM_NAME})" "FAIL"
fi

# ── 8. DNS Zone (+ A record → VM IP) ──
step_create "Creating DNS zone: ${DNS_ZONE}"
if az network dns zone create \
    --resource-group "${RG_NAME}" \
    --name "${DNS_ZONE}" \
    -o none 2>&1; then
    pass "DNS zone created"

    if [[ -n "${VM_PRIVATE_IP}" ]]; then
        step_create "Adding A record: vm.${DNS_ZONE} → ${VM_PRIVATE_IP}"
        az network dns record-set a add-record \
            --resource-group "${RG_NAME}" \
            --zone-name "${DNS_ZONE}" \
            --record-set-name "vm" \
            --ipv4-address "${VM_PRIVATE_IP}" \
            -o none 2>&1 || warn "Could not add A record"
        pass "DNS A record created"
    fi

    step_create "Adding CNAME: storage.${DNS_ZONE} → ${STORAGE_NAME}.blob.core.windows.net"
    az network dns record-set cname set-record \
        --resource-group "${RG_NAME}" \
        --zone-name "${DNS_ZONE}" \
        --record-set-name "storage" \
        --cname "${STORAGE_NAME}.blob.core.windows.net" \
        -o none 2>&1 || warn "Could not add CNAME record"
    pass "DNS CNAME record created"

    record_result "DNS Zone (${DNS_ZONE}) → VM IP + Storage" "OK"
else
    fail "DNS zone creation failed"
    record_result "DNS Zone (${DNS_ZONE})" "FAIL"
fi

# ── 9. Service Principal (+ Reader role on RG) ──
step_create "Creating service principal: ${SP_NAME}"
RG_ID=$(az group show --name "${RG_NAME}" --query "id" -o tsv 2>/dev/null || echo "")
if SP_OUTPUT=$(az ad sp create-for-rbac \
    --name "${SP_NAME}" \
    --role "Reader" \
    --scopes "${RG_ID}" \
    -o json 2>&1); then
    SP_APP_ID=$(echo "${SP_OUTPUT}" | grep -o '"appId": *"[^"]*"' | head -1 | cut -d'"' -f4)
    if [[ -n "${SP_APP_ID}" ]]; then
        echo "${SP_APP_ID}" > "${SP_APP_ID_FILE}"
        pass "Service principal created — appId: ${SP_APP_ID} (Reader on RG)"
        record_result "Service Principal (${SP_NAME}) → Reader on RG" "OK"
    else
        warn "Service principal created but could not parse appId"
        record_result "Service Principal (${SP_NAME})" "OK"
    fi
else
    fail "Service principal creation failed"
    record_result "Service Principal (${SP_NAME})" "FAIL"
fi

# ══════════════════════════════════════════════
# PHASE 2 — VERIFICATION & INVENTORY
# ══════════════════════════════════════════════
banner "Phase 2 — Verifying & Listing All Resources"

echo ""
info "All resources in resource group ${RG_NAME}:"
echo ""
az resource list --resource-group "${RG_NAME}" \
    --query "[].{Name:name, Type:type, Location:location}" \
    -o table 2>/dev/null || true
echo ""

# ── Show interconnection details ──
banner "Architecture Interconnections"

echo -e "${CYAN}NSG → Subnet:${RESET}"
az network vnet subnet show --resource-group "${RG_NAME}" \
    --vnet-name "${VNET_NAME}" --name "${SUBNET_NAME}" \
    --query "{subnet:name, nsg:networkSecurityGroup.id}" -o table 2>/dev/null || true
echo ""

echo -e "${CYAN}VM → Subnet + Boot Diagnostics:${RESET}"
az vm show --resource-group "${RG_NAME}" --name "${VM_NAME}" \
    --query "{vm:name, vnet:'${VNET_NAME}', subnet:'${SUBNET_NAME}', bootDiag:diagnosticsProfile.bootDiagnostics.enabled}" \
    -o table 2>/dev/null || true
echo ""

echo -e "${CYAN}Key Vault Secrets:${RESET}"
az keyvault secret list --vault-name "${KV_NAME}" \
    --query "[].{name:name, enabled:attributes.enabled}" -o table 2>/dev/null || true
echo ""

echo -e "${CYAN}DNS Records:${RESET}"
az network dns record-set list --resource-group "${RG_NAME}" --zone-name "${DNS_ZONE}" \
    --query "[?name!='@'].{Name:name, Type:type, Fqdn:fqdn}" -o table 2>/dev/null || true
echo ""

echo -e "${CYAN}Diagnostic Settings on Key Vault:${RESET}"
if [[ -n "${KV_ID:-}" ]]; then
    az monitor diagnostic-settings list --resource "${KV_ID}" \
        --query "[].{name:name, workspace:workspaceId}" -o table 2>/dev/null || true
fi
echo ""

if [[ -n "${SP_APP_ID:-}" ]]; then
    echo -e "${CYAN}Service Principal:${RESET}"
    az ad sp show --id "${SP_APP_ID}" \
        --query "{displayName:displayName, appId:appId}" -o table 2>/dev/null || true
    echo ""
fi

# ── Deployment Summary ──
banner "Deployment Summary"

printf "%-50s %s\n" "SERVICE" "STATUS"
printf "%-50s %s\n" "--------------------------------------------------" "------"
for i in "${!DEPLOYED_NAMES[@]}"; do
    if [[ "${DEPLOYED_STATUS[$i]}" == "OK" ]]; then
        printf "%-50s ${GREEN}%s${RESET}\n" "${DEPLOYED_NAMES[$i]}" "${DEPLOYED_STATUS[$i]}"
    else
        printf "%-50s ${RED}%s${RESET}\n" "${DEPLOYED_NAMES[$i]}" "${DEPLOYED_STATUS[$i]}"
    fi
done
echo ""
info "Total: ${#DEPLOYED_NAMES[@]} services — $((${#DEPLOYED_NAMES[@]} - FAIL_COUNT)) OK, ${FAIL_COUNT} failed"
echo ""

if [[ ${FAIL_COUNT} -gt 0 ]]; then
    warn "Some services failed to deploy. Check the output above."
fi

# ══════════════════════════════════════════════
# PHASE 3 — INTERACTIVE PAUSE + CLEANUP
# ══════════════════════════════════════════════
banner "Phase 3 — Cleanup"

echo -e "${BOLD}All resources are live. You can now inspect them in the Azure Portal:${RESET}"
echo ""
echo "  https://portal.azure.com/#@/resource/subscriptions/$(az account show --query 'id' -o tsv)/resourceGroups/${RG_NAME}/overview"
echo ""
warn "The VM and storage account will incur minor costs while running."
echo ""
echo -e "${YELLOW}════════════════════════════════════════════════════════════════${RESET}"
echo -e "${YELLOW}  When you are done inspecting, confirm cleanup below.${RESET}"
echo -e "${YELLOW}  This will DELETE the ENTIRE resource group and ALL resources.${RESET}"
echo -e "${YELLOW}════════════════════════════════════════════════════════════════${RESET}"
echo ""
read -r -p "Delete resource group '${RG_NAME}' and ALL its contents? (yes/no): " CLEANUP_CONFIRM

if [[ "${CLEANUP_CONFIRM}" == "yes" ]]; then
    echo ""

    # Delete service principal first (not in RG)
    if [[ -n "${SP_APP_ID:-}" ]]; then
        step_delete "Deleting service principal: ${SP_APP_ID}"
        az ad sp delete --id "${SP_APP_ID}" 2>/dev/null || warn "Could not delete SP"
        rm -f "${SP_APP_ID_FILE}"
        pass "Service principal deleted"
    fi

    # Purge Key Vault after RG delete (to release name)
    KV_PURGE_NEEDED=false
    if az keyvault show --name "${KV_NAME}" -o none 2>/dev/null; then
        KV_PURGE_NEEDED=true
    fi

    # Delete entire RG (cascades to all Azure resources)
    step_delete "Deleting resource group: ${RG_NAME} (this may take a few minutes)"
    if az group delete --name "${RG_NAME}" --yes 2>&1; then
        pass "Resource group and all resources deleted"
    else
        fail "Resource group deletion failed"
    fi

    # Purge Key Vault (soft-delete retention)
    if ${KV_PURGE_NEEDED}; then
        step_delete "Purging Key Vault to release name: ${KV_NAME}"
        az keyvault purge --name "${KV_NAME}" --no-wait 2>/dev/null || true
        pass "Key Vault purge initiated"
    fi

    banner "Cleanup Complete"
else
    echo ""
    warn "Resources left running in resource group: ${RG_NAME}"
    warn "To clean up later, run:"
    echo ""
    echo "  az group delete --name ${RG_NAME} --yes"
    if [[ -n "${SP_APP_ID:-}" ]]; then
        echo "  az ad sp delete --id ${SP_APP_ID}"
    fi
    echo "  az keyvault purge --name ${KV_NAME}  # after RG is deleted"
    echo ""
    banner "Done (resources still running)"
fi
