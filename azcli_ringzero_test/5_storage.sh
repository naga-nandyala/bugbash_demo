#!/usr/bin/env bash
#
# 5_storage.sh — Test Azure Storage by creating an account, container, and blob
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

banner "Azure Storage"
TEST_PASSED=false

# ── CREATE ──
step_create "Creating storage account: ${STORAGE_NAME}"
if ! az storage account create \
    --resource-group "${RG_NAME}" \
    --name "${STORAGE_NAME}" \
    --sku "Standard_LRS" \
    --kind "StorageV2" \
    --location "${LOCATION}" \
    --min-tls-version "TLS1_2" \
    --allow-blob-public-access false \
    -o none 2>&1; then
    fail "Azure Storage — account creation failed"
    cleanup_rg_if_we_created_it
    exit 1
fi
pass "Storage account created"

# ── VERIFY EXISTS ──
step_verify_exists "Verifying storage account..."
SA_STATE=$(az storage account show --resource-group "${RG_NAME}" --name "${STORAGE_NAME}" \
    --query "provisioningState" -o tsv 2>/dev/null || echo "UNKNOWN")
if [[ "${SA_STATE}" == "Succeeded" ]]; then
    pass "Storage account verified (state: ${SA_STATE})"
else
    fail "Storage account state: ${SA_STATE}"
fi

# Create container + blob for deeper verification
STORAGE_KEY=$(az storage account keys list \
    --resource-group "${RG_NAME}" --account-name "${STORAGE_NAME}" \
    --query "[0].value" -o tsv 2>/dev/null || echo "")

if [[ -n "${STORAGE_KEY}" ]]; then
    step_create "Creating blob container: ${CONTAINER_NAME}"
    az storage container create --name "${CONTAINER_NAME}" \
        --account-name "${STORAGE_NAME}" --account-key "${STORAGE_KEY}" -o none 2>&1 || true

    step_create "Uploading test blob..."
    echo "Ring Zero test - $(date -u +%Y-%m-%dT%H:%M:%SZ)" | az storage blob upload \
        --container-name "${CONTAINER_NAME}" --name "test.txt" \
        --account-name "${STORAGE_NAME}" --account-key "${STORAGE_KEY}" \
        --data @- --overwrite -o none 2>&1 || true

    step_verify_exists "Verifying blob exists..."
    BLOB_EXISTS=$(az storage blob exists --container-name "${CONTAINER_NAME}" --name "test.txt" \
        --account-name "${STORAGE_NAME}" --account-key "${STORAGE_KEY}" \
        --query "exists" -o tsv 2>/dev/null || echo "false")
    if [[ "${BLOB_EXISTS}" == "true" ]]; then
        pass "Blob verified"
    else
        warn "Blob not found (account still works)"
    fi
fi

# ── SHOW ──
step_show "Storage account details:"
az storage account show --resource-group "${RG_NAME}" --name "${STORAGE_NAME}" \
    --query "{name:name, location:location, sku:sku.name, kind:kind, state:provisioningState}" -o table 2>/dev/null || true

TEST_PASSED=true

# ── DELETE ──
step_delete "Deleting storage account: ${STORAGE_NAME}"
if az storage account delete --resource-group "${RG_NAME}" --name "${STORAGE_NAME}" --yes 2>/dev/null; then
    pass "Storage account deleted"
else
    warn "Could not delete storage account"
fi

# ── VERIFY DELETED ──
step_verify_deleted "Verifying storage account is gone..."
if az storage account show --resource-group "${RG_NAME}" --name "${STORAGE_NAME}" -o none 2>/dev/null; then
    warn "Storage account still exists"
else
    pass "Storage account deletion confirmed"
fi

cleanup_rg_if_we_created_it

if ${TEST_PASSED}; then
    banner "✅ Azure Storage — PASSED"
    exit 0
else
    banner "❌ Azure Storage — FAILED"
    exit 1
fi
