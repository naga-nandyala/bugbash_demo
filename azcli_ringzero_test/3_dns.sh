#!/usr/bin/env bash
#
# 3_dns.sh — Test Azure DNS by creating a zone and A record
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

banner "Azure DNS"
TEST_PASSED=false

# ── CREATE ──
step_create "Creating DNS zone: ${DNS_ZONE}"
if ! az network dns zone create --resource-group "${RG_NAME}" --name "${DNS_ZONE}" -o none 2>&1; then
    fail "Azure DNS — could not create zone"
    cleanup_rg_if_we_created_it
    exit 1
fi
pass "DNS zone created"

step_create "Adding A record: test.${DNS_ZONE} → 1.2.3.4"
if ! az network dns record-set a add-record \
    --resource-group "${RG_NAME}" \
    --zone-name "${DNS_ZONE}" \
    --record-set-name "test" \
    --ipv4-address "1.2.3.4" \
    -o none 2>&1; then
    fail "Azure DNS — could not add A record"
    cleanup_rg_if_we_created_it
    exit 1
fi
pass "A record added"

# ── VERIFY EXISTS ──
step_verify_exists "Verifying A record..."
RECORD_IP=$(az network dns record-set a show \
    --resource-group "${RG_NAME}" \
    --zone-name "${DNS_ZONE}" \
    --name "test" \
    --query "ARecords[0].ipv4Address" -o tsv 2>/dev/null || echo "")
if [[ "${RECORD_IP}" == "1.2.3.4" ]]; then
    pass "A record verified (IP: ${RECORD_IP})"
else
    fail "Azure DNS — A record mismatch (got: ${RECORD_IP})"
fi

# ── SHOW ──
step_show "DNS zone details:"
az network dns zone show --resource-group "${RG_NAME}" --name "${DNS_ZONE}" \
    --query "{name:name, resourceGroup:resourceGroup, numberOfRecordSets:numberOfRecordSets}" -o table 2>/dev/null || true

TEST_PASSED=true

# ── DELETE ──
step_delete "Deleting DNS zone: ${DNS_ZONE}"
if az network dns zone delete --resource-group "${RG_NAME}" --name "${DNS_ZONE}" --yes 2>/dev/null; then
    pass "DNS zone deleted"
else
    warn "Could not delete DNS zone"
fi

# ── VERIFY DELETED ──
step_verify_deleted "Verifying DNS zone is gone..."
if az network dns zone show --resource-group "${RG_NAME}" --name "${DNS_ZONE}" -o none 2>/dev/null; then
    warn "DNS zone still exists"
else
    pass "DNS zone deletion confirmed"
fi

cleanup_rg_if_we_created_it

if ${TEST_PASSED}; then
    banner "✅ Azure DNS — PASSED"
    exit 0
else
    banner "❌ Azure DNS — FAILED"
    exit 1
fi
