#!/usr/bin/env bash
#
# 6_compute.sh — Test Azure Compute by creating a small VM
#
# Lifecycle: Create → Verify → Show → Delete → Verify deletion
# Auto-creates resource group + VNet/subnet if needed.
#
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
setup_logging

preflight_check
ensure_rg

banner "Azure Compute"
TEST_PASSED=false

# Ensure VNet/subnet exists (prerequisite for VM)
_VNET_CREATED=false
if ! az network vnet show --resource-group "${RG_NAME}" --name "${VNET_NAME}" -o none 2>/dev/null; then
    info "Creating prerequisite VNet: ${VNET_NAME}"
    az network vnet create --resource-group "${RG_NAME}" --name "${VNET_NAME}" \
        --address-prefix "10.0.0.0/16" --subnet-name "${SUBNET_NAME}" \
        --subnet-prefix "10.0.0.0/24" -o none 2>&1
    _VNET_CREATED=true
fi

# ── CREATE ──
step_create "Creating VM: ${VM_NAME} (Standard_B1s — may take a few minutes)"
if ! az vm create \
    --resource-group "${RG_NAME}" \
    --name "${VM_NAME}" \
    --image "Ubuntu2204" \
    --size "Standard_B1s" \
    --vnet-name "${VNET_NAME}" \
    --subnet "${SUBNET_NAME}" \
    --admin-username "azureuser" \
    --generate-ssh-keys \
    --public-ip-address "" \
    --nsg "" \
    -o none 2>&1; then
    fail "Azure Compute — VM creation failed"
    if ${_VNET_CREATED}; then
        az network vnet delete --resource-group "${RG_NAME}" --name "${VNET_NAME}" 2>/dev/null || true
    fi
    cleanup_rg_if_we_created_it
    exit 1
fi
pass "VM created"

# ── VERIFY EXISTS ──
step_verify_exists "Verifying VM..."
VM_STATE=$(az vm show --resource-group "${RG_NAME}" --name "${VM_NAME}" \
    --query "provisioningState" -o tsv 2>/dev/null || echo "UNKNOWN")
if [[ "${VM_STATE}" == "Succeeded" ]]; then
    pass "VM verified (state: ${VM_STATE})"
    TEST_PASSED=true
else
    fail "VM state: ${VM_STATE}"
fi

# ── SHOW ──
step_show "VM details:"
az vm show --resource-group "${RG_NAME}" --name "${VM_NAME}" \
    --query "{name:name, size:hardwareProfile.vmSize, os:storageProfile.imageReference.offer, state:provisioningState}" -o table 2>/dev/null || true

# ── DELETE ──
step_delete "Deleting VM: ${VM_NAME} (and associated resources)"
if az vm delete --resource-group "${RG_NAME}" --name "${VM_NAME}" --yes --force-deletion yes 2>/dev/null; then
    pass "VM deleted"
else
    warn "Could not delete VM"
fi

# Clean up VM-associated resources (disk, NIC)
info "Cleaning up associated resources..."
for nic in $(az network nic list --resource-group "${RG_NAME}" --query "[?contains(name,'${VM_NAME}')].name" -o tsv 2>/dev/null); do
    az network nic delete --resource-group "${RG_NAME}" --name "${nic}" 2>/dev/null || true
done
for disk in $(az disk list --resource-group "${RG_NAME}" --query "[?contains(name,'${VM_NAME}')].name" -o tsv 2>/dev/null); do
    az disk delete --resource-group "${RG_NAME}" --name "${disk}" --yes 2>/dev/null || true
done

# Clean up VNet if we created it
if ${_VNET_CREATED}; then
    step_delete "Deleting prerequisite VNet: ${VNET_NAME}"
    az network vnet delete --resource-group "${RG_NAME}" --name "${VNET_NAME}" 2>/dev/null || true
fi

# ── VERIFY DELETED ──
step_verify_deleted "Verifying VM is gone..."
if az vm show --resource-group "${RG_NAME}" --name "${VM_NAME}" -o none 2>/dev/null; then
    warn "VM still exists"
else
    pass "VM deletion confirmed"
fi

cleanup_rg_if_we_created_it

if ${TEST_PASSED}; then
    banner "✅ Azure Compute — PASSED"
    exit 0
else
    banner "❌ Azure Compute — FAILED"
    exit 1
fi
