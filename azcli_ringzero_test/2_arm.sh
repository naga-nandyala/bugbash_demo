#!/usr/bin/env bash
#
# 2_arm.sh — Test Azure Resource Manager by creating a resource group
#
# Lifecycle: Create → Verify → Show → Delete → Verify deletion
#
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
setup_logging

preflight_check

banner "Azure Resource Manager (ARM)"
TEST_PASSED=false

# ── CREATE ──
step_create "Creating resource group: ${RG_NAME} in ${LOCATION}"
if ! az group create --name "${RG_NAME}" --location "${LOCATION}" -o none 2>&1; then
    fail "ARM — could not create resource group"
    exit 1
fi
pass "Resource group created"

# ── VERIFY EXISTS ──
step_verify_exists "Verifying resource group exists..."
RG_STATE=$(az group show --name "${RG_NAME}" --query "properties.provisioningState" -o tsv 2>/dev/null || echo "UNKNOWN")
if [[ "${RG_STATE}" == "Succeeded" ]]; then
    pass "Resource group verified (state: ${RG_STATE})"
else
    fail "ARM — resource group state: ${RG_STATE}"
    exit 1
fi

# ── SHOW ──
step_show "Resource group details:"
az group show --name "${RG_NAME}" --query "{name:name, location:location, state:properties.provisioningState}" -o table 2>/dev/null || true

TEST_PASSED=true

# ── DELETE ──
step_delete "Deleting resource group: ${RG_NAME}"
if az group delete --name "${RG_NAME}" --yes --no-wait 2>/dev/null; then
    pass "Resource group deletion initiated (async)"
else
    warn "Could not delete resource group"
fi

# ── VERIFY DELETED ──
step_verify_deleted "Verifying resource group is being deleted..."
sleep 3
RG_CHECK=$(az group show --name "${RG_NAME}" --query "properties.provisioningState" -o tsv 2>/dev/null || echo "NotFound")
if [[ "${RG_CHECK}" == "NotFound" ]]; then
    pass "Resource group deleted"
elif [[ "${RG_CHECK}" == "Deleting" ]]; then
    pass "Resource group deletion in progress"
else
    warn "Resource group still in state: ${RG_CHECK}"
fi

if ${TEST_PASSED}; then
    banner "✅ ARM — PASSED"
    exit 0
else
    banner "❌ ARM — FAILED"
    exit 1
fi
