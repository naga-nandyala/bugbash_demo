#!/usr/bin/env bash
#
# 7_keyvault.sh — Test Azure Key Vault by creating a vault and storing a secret
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

banner "Azure Key Vault"
TEST_PASSED=false

# ── CREATE ──
step_create "Creating Key Vault: ${KV_NAME}"
if ! az keyvault create \
    --resource-group "${RG_NAME}" \
    --name "${KV_NAME}" \
    --location "${LOCATION}" \
    --enable-rbac-authorization false \
    -o none 2>&1; then
    fail "Azure Key Vault — vault creation failed"
    cleanup_rg_if_we_created_it
    exit 1
fi
pass "Key Vault created"

step_create "Setting test secret..."
SECRET_VALUE="ring-zero-test-$(date +%s)"
if ! az keyvault secret set \
    --vault-name "${KV_NAME}" \
    --name "test-secret" \
    --value "${SECRET_VALUE}" \
    -o none 2>&1; then
    fail "Azure Key Vault — could not set secret"
    cleanup_rg_if_we_created_it
    exit 1
fi
pass "Secret stored"

# ── VERIFY EXISTS ──
step_verify_exists "Retrieving and verifying secret..."
RETRIEVED=$(az keyvault secret show --vault-name "${KV_NAME}" --name "test-secret" \
    --query "value" -o tsv 2>/dev/null || echo "")
if [[ "${RETRIEVED}" == "${SECRET_VALUE}" ]]; then
    pass "Secret value verified (round-trip match)"
    TEST_PASSED=true
else
    fail "Secret value mismatch"
fi

# ── SHOW ──
step_show "Key Vault details:"
az keyvault show --name "${KV_NAME}" \
    --query "{name:name, resourceGroup:resourceGroup, location:location, sku:properties.sku.name}" -o table 2>/dev/null || true
step_show "Secret details:"
az keyvault secret show --vault-name "${KV_NAME}" --name "test-secret" \
    --query "{name:name, contentType:contentType, enabled:attributes.enabled}" -o table 2>/dev/null || true

# ── DELETE ──
step_delete "Deleting Key Vault: ${KV_NAME}"
if az keyvault delete --name "${KV_NAME}" --resource-group "${RG_NAME}" 2>/dev/null; then
    pass "Key Vault deleted (soft-delete)"
    # Purge to fully remove (avoids name conflicts on re-run)
    info "Purging Key Vault to release the name..."
    az keyvault purge --name "${KV_NAME}" --no-wait 2>/dev/null || true
else
    warn "Could not delete Key Vault"
fi

# ── VERIFY DELETED ──
step_verify_deleted "Verifying Key Vault is gone..."
if az keyvault show --name "${KV_NAME}" -o none 2>/dev/null; then
    warn "Key Vault still exists (soft-delete retention)"
else
    pass "Key Vault deletion confirmed"
fi

cleanup_rg_if_we_created_it

if ${TEST_PASSED}; then
    banner "✅ Azure Key Vault — PASSED"
    exit 0
else
    banner "❌ Azure Key Vault — FAILED"
    exit 1
fi
