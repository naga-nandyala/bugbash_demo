#!/usr/bin/env bash
#
# main.sh — Azure Ring Zero Services Test Orchestrator
#
# Runs selected service tests in order and tracks results.
# Each test follows the lifecycle: Create → Verify → Show → Delete → Verify.
#
# When run via main.sh, a shared resource group is pre-created so individual
# scripts reuse it (via ensure_rg) instead of each creating and deleting its own.
# main.sh handles the final RG cleanup.
#
# Usage:
#   ./main.sh              # Run all tests
#   ./main.sh 1 3 5        # Run only tests 1, 3, 5
#   ./1_entra_id.sh        # Run a single test standalone (self-cleaning)
#
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# ──────────────────────────────────────────────
# Test registry: number → script → display name
# ──────────────────────────────────────────────
declare -a SCRIPTS=(
    "1_entra_id.sh"
    "2_arm.sh"
    "3_dns.sh"
    "4_networking.sh"
    "5_storage.sh"
    "6_compute.sh"
    "7_keyvault.sh"
    "8_monitor.sh"
)
declare -a NAMES=(
    "Entra ID (Service Principal)"
    "ARM (Resource Group)"
    "Azure DNS"
    "Azure Networking (VNet + NSG)"
    "Azure Storage"
    "Azure Compute (VM)"
    "Azure Key Vault"
    "Azure Monitor"
)

# ──────────────────────────────────────────────
# Parse which tests to run
# ──────────────────────────────────────────────
SELECTED=()
if [[ $# -eq 0 ]]; then
    SELECTED=(1 2 3 4 5 6 7 8)
else
    for arg in "$@"; do
        if [[ "${arg}" -ge 1 && "${arg}" -le 8 ]] 2>/dev/null; then
            SELECTED+=("${arg}")
        else
            echo "ERROR: Invalid test number '${arg}'. Valid range: 1-8"
            exit 1
        fi
    done
fi

# ──────────────────────────────────────────────
# Preflight
# ──────────────────────────────────────────────
setup_logging

preflight_check
banner "Azure Ring Zero Services Test"
show_subscription_info

info "Tests to run: ${SELECTED[*]}"
echo ""
warn "Each test will: Create → Verify → Show → Delete → Verify resources."
echo ""

read -r -p "Proceed with this subscription? (yes/no): " CONFIRM
if [[ "${CONFIRM}" != "yes" ]]; then
    echo "Aborted."
    exit 0
fi

echo ""

# ──────────────────────────────────────────────
# Results tracking
# ──────────────────────────────────────────────
declare -a RESULT_NAMES=()
declare -a RESULT_STATUS=()

# ──────────────────────────────────────────────
# Run selected tests
# ──────────────────────────────────────────────
TOTAL=${#SELECTED[@]}
CURRENT=0

for TEST_NUM in "${SELECTED[@]}"; do
    ((CURRENT++)) || true
    IDX=$((TEST_NUM - 1))
    SCRIPT="${SCRIPTS[$IDX]}"
    NAME="${NAMES[$IDX]}"

    info "[${CURRENT}/${TOTAL}] Running: ${NAME}"

    if bash "${SCRIPT_DIR}/${SCRIPT}"; then
        RESULT_NAMES+=("${NAME}")
        RESULT_STATUS+=("PASS")
    else
        RESULT_NAMES+=("${NAME}")
        RESULT_STATUS+=("FAIL")
    fi
done

# ──────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────
banner "Results Summary"

PASS_COUNT=0
FAIL_COUNT=0

printf "%-35s %s\n" "SERVICE" "STATUS"
printf "%-35s %s\n" "-----------------------------------" "------"

for i in "${!RESULT_NAMES[@]}"; do
    if [[ "${RESULT_STATUS[$i]}" == "PASS" ]]; then
        printf "%-35s ${GREEN}%s${RESET}\n" "${RESULT_NAMES[$i]}" "${RESULT_STATUS[$i]}"
        ((PASS_COUNT++)) || true
    else
        printf "%-35s ${RED}%s${RESET}\n" "${RESULT_NAMES[$i]}" "${RESULT_STATUS[$i]}"
        ((FAIL_COUNT++)) || true
    fi
done

echo ""
info "Total: $((PASS_COUNT + FAIL_COUNT)) tests — ${PASS_COUNT} passed, ${FAIL_COUNT} failed"
echo ""

if [[ ${FAIL_COUNT} -gt 0 ]]; then
    warn "Some tests failed. Check the output above for details."
    exit 1
else
    echo -e "${GREEN}${BOLD}All Ring Zero service tests passed!${RESET}"
fi
