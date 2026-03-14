#!/usr/bin/env bash
#
# 4_networking.sh — Test Azure Networking by creating a VNet, subnet, and NSG
#
# Lifecycle: Create → Verify → Show → Delete → Verify deletion
# Auto-creates resource group if needed; cleans it up if it created it.
#
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
setup_logging

preflight_check
ensure_rg

banner "Azure Networking"
TEST_PASSED=false

# ── CREATE ──
step_create "Creating VNet: ${VNET_NAME} with subnet: ${SUBNET_NAME}"
if ! az network vnet create \
    --resource-group "${RG_NAME}" \
    --name "${VNET_NAME}" \
    --address-prefix "10.0.0.0/16" \
    --subnet-name "${SUBNET_NAME}" \
    --subnet-prefix "10.0.0.0/24" \
    -o none 2>&1; then
    fail "Azure Networking — VNet creation failed"
    cleanup_rg_if_we_created_it
    exit 1
fi
pass "VNet and subnet created"

step_create "Creating NSG: ${NSG_NAME}"
if ! az network nsg create \
    --resource-group "${RG_NAME}" \
    --name "${NSG_NAME}" \
    -o none 2>&1; then
    fail "Azure Networking — NSG creation failed"
    cleanup_rg_if_we_created_it
    exit 1
fi
pass "NSG created"

# ── VERIFY EXISTS ──
step_verify_exists "Verifying VNet..."
VNET_STATE=$(az network vnet show --resource-group "${RG_NAME}" --name "${VNET_NAME}" \
    --query "provisioningState" -o tsv 2>/dev/null || echo "UNKNOWN")
if [[ "${VNET_STATE}" == "Succeeded" ]]; then
    pass "VNet verified (state: ${VNET_STATE})"
else
    fail "VNet state: ${VNET_STATE}"
fi

step_verify_exists "Verifying NSG..."
NSG_STATE=$(az network nsg show --resource-group "${RG_NAME}" --name "${NSG_NAME}" \
    --query "provisioningState" -o tsv 2>/dev/null || echo "UNKNOWN")
if [[ "${NSG_STATE}" == "Succeeded" ]]; then
    pass "NSG verified (state: ${NSG_STATE})"
else
    fail "NSG state: ${NSG_STATE}"
fi

# ── SHOW ──
step_show "VNet details:"
az network vnet show --resource-group "${RG_NAME}" --name "${VNET_NAME}" \
    --query "{name:name, addressSpace:addressSpace.addressPrefixes[0], subnets:subnets[0].name, state:provisioningState}" -o table 2>/dev/null || true
step_show "NSG details:"
az network nsg show --resource-group "${RG_NAME}" --name "${NSG_NAME}" \
    --query "{name:name, resourceGroup:resourceGroup, state:provisioningState}" -o table 2>/dev/null || true

if [[ "${VNET_STATE}" == "Succeeded" && "${NSG_STATE}" == "Succeeded" ]]; then
    TEST_PASSED=true
fi

# ── DELETE ──
step_delete "Deleting NSG: ${NSG_NAME}"
if az network nsg delete --resource-group "${RG_NAME}" --name "${NSG_NAME}" 2>/dev/null; then
    pass "NSG deleted"
else
    warn "Could not delete NSG"
fi

step_delete "Deleting VNet: ${VNET_NAME}"
if az network vnet delete --resource-group "${RG_NAME}" --name "${VNET_NAME}" 2>/dev/null; then
    pass "VNet deleted"
else
    warn "Could not delete VNet"
fi

# ── VERIFY DELETED ──
step_verify_deleted "Verifying VNet is gone..."
if az network vnet show --resource-group "${RG_NAME}" --name "${VNET_NAME}" -o none 2>/dev/null; then
    warn "VNet still exists"
else
    pass "VNet deletion confirmed"
fi

step_verify_deleted "Verifying NSG is gone..."
if az network nsg show --resource-group "${RG_NAME}" --name "${NSG_NAME}" -o none 2>/dev/null; then
    warn "NSG still exists"
else
    pass "NSG deletion confirmed"
fi

cleanup_rg_if_we_created_it

if ${TEST_PASSED}; then
    banner "✅ Azure Networking — PASSED"
    exit 0
else
    banner "❌ Azure Networking — FAILED"
    exit 1
fi
