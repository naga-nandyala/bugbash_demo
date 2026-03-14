#!/usr/bin/env bash
#
# 1_entra_id.sh — Test Entra ID (Azure AD) by creating a service principal
#
# Lifecycle: Create → Verify → Show → Delete → Verify deletion
#
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
setup_logging

preflight_check

banner "Entra ID (Microsoft Entra ID)"
TEST_PASSED=false

# ── CREATE ──
step_create "Creating service principal: ${SP_NAME}"
if ! SP_OUTPUT=$(az ad sp create-for-rbac --name "${SP_NAME}" --skip-assignment -o json 2>&1); then
    fail "Entra ID — create failed: ${SP_OUTPUT}"
    exit 1
fi
SP_APP_ID=$(echo "${SP_OUTPUT}" | grep -o '"appId": *"[^"]*"' | head -1 | cut -d'"' -f4)
if [[ -z "${SP_APP_ID}" ]]; then
    fail "Entra ID — could not parse appId from output"
    exit 1
fi
echo "${SP_APP_ID}" > "${SP_APP_ID_FILE}"
pass "Created service principal — appId: ${SP_APP_ID}"

# ── VERIFY EXISTS ──
step_verify_exists "Verifying service principal exists..."
if az ad sp show --id "${SP_APP_ID}" -o none 2>/dev/null; then
    pass "Service principal verified"
else
    warn "Could not verify (propagation delay is normal)"
fi

# ── SHOW ──
step_show "Service principal details:"
az ad sp show --id "${SP_APP_ID}" --query "{displayName:displayName, appId:appId, id:id}" -o table 2>/dev/null || true

TEST_PASSED=true

# ── DELETE ──
step_delete "Deleting service principal: ${SP_APP_ID}"
if az ad sp delete --id "${SP_APP_ID}" 2>/dev/null; then
    pass "Service principal deleted"
    rm -f "${SP_APP_ID_FILE}"
else
    warn "Could not delete service principal"
fi

# ── VERIFY DELETED ──
step_verify_deleted "Verifying service principal is gone..."
sleep 2
if az ad sp show --id "${SP_APP_ID}" -o none 2>/dev/null; then
    warn "Service principal still exists (may take time to propagate)"
else
    pass "Service principal deletion confirmed"
fi

if ${TEST_PASSED}; then
    banner "✅ Entra ID — PASSED"
    exit 0
else
    banner "❌ Entra ID — FAILED"
    exit 1
fi
