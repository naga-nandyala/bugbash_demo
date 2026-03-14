#!/usr/bin/env bash
#
# 8_monitor.sh — Test Azure Monitor by creating a Log Analytics workspace
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

banner "Azure Monitor"
TEST_PASSED=false

# ── CREATE ──
step_create "Creating Log Analytics workspace: ${LOG_WORKSPACE}"
if ! az monitor log-analytics workspace create \
    --resource-group "${RG_NAME}" \
    --workspace-name "${LOG_WORKSPACE}" \
    --location "${LOCATION}" \
    -o none 2>&1; then
    fail "Azure Monitor — workspace creation failed"
    cleanup_rg_if_we_created_it
    exit 1
fi
pass "Log Analytics workspace created"

# ── VERIFY EXISTS ──
step_verify_exists "Verifying workspace..."
LAW_STATE=$(az monitor log-analytics workspace show \
    --resource-group "${RG_NAME}" --workspace-name "${LOG_WORKSPACE}" \
    --query "provisioningState" -o tsv 2>/dev/null || echo "UNKNOWN")
if [[ "${LAW_STATE}" == "Succeeded" ]]; then
    pass "Workspace verified (state: ${LAW_STATE})"
    TEST_PASSED=true
else
    fail "Workspace state: ${LAW_STATE}"
fi

# ── SHOW ──
step_show "Log Analytics workspace details:"
az monitor log-analytics workspace show \
    --resource-group "${RG_NAME}" --workspace-name "${LOG_WORKSPACE}" \
    --query "{name:name, resourceGroup:resourceGroup, sku:sku.name, retentionDays:retentionInDays, state:provisioningState}" -o table 2>/dev/null || true

# ── DELETE ──
step_delete "Deleting Log Analytics workspace: ${LOG_WORKSPACE}"
if az monitor log-analytics workspace delete \
    --resource-group "${RG_NAME}" --workspace-name "${LOG_WORKSPACE}" \
    --yes --force 2>/dev/null; then
    pass "Workspace deleted"
else
    warn "Could not delete workspace"
fi

# ── VERIFY DELETED ──
step_verify_deleted "Verifying workspace is gone..."
if az monitor log-analytics workspace show \
    --resource-group "${RG_NAME}" --workspace-name "${LOG_WORKSPACE}" -o none 2>/dev/null; then
    warn "Workspace still exists (may take time)"
else
    pass "Workspace deletion confirmed"
fi

cleanup_rg_if_we_created_it

if ${TEST_PASSED}; then
    banner "✅ Azure Monitor — PASSED"
    exit 0
else
    banner "❌ Azure Monitor — FAILED"
    exit 1
fi
