#!/usr/bin/env bash
#
# common.sh — Shared helpers for Ring Zero service test scripts
#
# Sourced by each individual test script and the main orchestrator.
# Provides: color output, pass/fail helpers, config variables, preflight checks.
#

# ──────────────────────────────────────────────
# Logging — tee all output to a timestamped log file
# ──────────────────────────────────────────────
# Log dir: logs_ringzero_test_<whoami>/ (sibling to scripts)
# Log file: <scriptname>_<YYYYMMDD_HHMMSS>.log
LOG_DIR="${SCRIPT_DIR}/../logs_ringzero_test_$(whoami)"

setup_logging() {
    local caller_script
    caller_script=$(basename "${BASH_SOURCE[1]}" .sh)
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    mkdir -p "${LOG_DIR}"
    LOG_FILE="${LOG_DIR}/${caller_script}_${timestamp}.log"
    # Tee stdout+stderr to log file, stripping ANSI codes for the file copy
    exec > >(tee >(sed 's/\x1b\[[0-9;]*m//g' >> "${LOG_FILE}")) 2>&1
}

# ──────────────────────────────────────────────
# Colors & output helpers
# ──────────────────────────────────────────────
BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

info()   { echo -e "${CYAN}ℹ ${BOLD}$*${RESET}"; }
pass()   { echo -e "${GREEN}✅ PASS${RESET} — $*"; }
fail()   { echo -e "${RED}❌ FAIL${RESET} — $*"; }
warn()   { echo -e "${YELLOW}⚠  $*${RESET}"; }
banner() { echo -e "\n${BOLD}════════════════════════════════════════${RESET}"; echo -e "${BOLD}  $*${RESET}"; echo -e "${BOLD}════════════════════════════════════════${RESET}\n"; }

# ──────────────────────────────────────────────
# Configuration — shared resource naming
# ──────────────────────────────────────────────
# USER_PREFIX = first 5 chars of whoami (repeatable, e.g. "nagan")
# UNIQUE_ID   = USER_PREFIX + 3 random digits (for globally unique names)
#
# Resources scoped to RG use USER_PREFIX (repeatable across runs).
# Globally unique names (storage, keyvault, DNS zone, SP) use UNIQUE_ID.
export USER_PREFIX="${USER_PREFIX:-$(whoami | tr -dc '[:alnum:]' | head -c 5 | tr '[:upper:]' '[:lower:]')}"
export UNIQUE_ID="${UNIQUE_ID:-${USER_PREFIX}$(( RANDOM % 900 + 100 ))}"

export LOCATION="${LOCATION:-australiaeast}"

# RG and RG-scoped resources — use UNIQUE_ID to avoid conflicts
# when multiple participants share the same subscription
export RG_NAME="${RG_NAME:-rg-ringzero-${UNIQUE_ID}}"
export VNET_NAME="${VNET_NAME:-vnet-${UNIQUE_ID}}"
export SUBNET_NAME="${SUBNET_NAME:-subnet-${UNIQUE_ID}}"
export NSG_NAME="${NSG_NAME:-nsg-${UNIQUE_ID}}"
export VM_NAME="${VM_NAME:-vm-${UNIQUE_ID}}"
export LOG_WORKSPACE="${LOG_WORKSPACE:-law-${UNIQUE_ID}}"
export CONTAINER_NAME="${CONTAINER_NAME:-testcontainer}"

# Globally unique resources — also use UNIQUE_ID
export DNS_ZONE="${DNS_ZONE:-ringzero${UNIQUE_ID}.test}"
export STORAGE_NAME="${STORAGE_NAME:-st${UNIQUE_ID}}"
export KV_NAME="${KV_NAME:-kv-${UNIQUE_ID}}"
export SP_NAME="${SP_NAME:-sp-ringzero-${UNIQUE_ID}}"

# File used to pass the SP app ID between scripts (written by 1_entra_id.sh, read by cleanup)
export SP_APP_ID_FILE="${SP_APP_ID_FILE:-/tmp/ringzero-sp-appid-${UNIQUE_ID}}"

# ──────────────────────────────────────────────
# Preflight — check az CLI and login
# ──────────────────────────────────────────────
preflight_check() {
    if ! command -v az &>/dev/null; then
        echo "ERROR: Azure CLI (az) is not installed. Install it from https://aka.ms/installazurecli"
        exit 1
    fi
    if ! az account show &>/dev/null; then
        echo "ERROR: Not logged in to Azure. Run 'az login' first."
        exit 1
    fi
}

show_subscription_info() {
    local sub_name sub_id
    sub_name=$(az account show --query "name" -o tsv)
    sub_id=$(az account show --query "id" -o tsv)
    echo ""
    info "Subscription:   ${sub_name}"
    info "ID:             ${sub_id}"
    info "Location:       ${LOCATION}"
    info "Resource Group: ${RG_NAME}"
    echo ""
}

# ──────────────────────────────────────────────
# Exit-code convention for individual scripts
# ──────────────────────────────────────────────
# exit 0 = PASS
# exit 1 = FAIL

# ──────────────────────────────────────────────
# Lifecycle step labels
# ──────────────────────────────────────────────
step_create()          { echo -e "${CYAN}[CREATE]${RESET}  $*"; }
step_verify_exists()   { echo -e "${CYAN}[VERIFY]${RESET}  $*"; }
step_show()            { echo -e "${CYAN}[SHOW]${RESET}    $*"; }
step_delete()          { echo -e "${CYAN}[DELETE]${RESET}  $*"; }
step_verify_deleted()  { echo -e "${CYAN}[VERIFY]${RESET}  $*"; }

# ──────────────────────────────────────────────
# Resource group prerequisite helpers
# ──────────────────────────────────────────────
# Scripts 3-8 call ensure_rg at the start and cleanup_rg at the end.
# If the RG already existed, we leave it alone.
_RG_CREATED_BY_US=false

ensure_rg() {
    if az group show --name "${RG_NAME}" -o none 2>/dev/null; then
        local rg_state
        rg_state=$(az group show --name "${RG_NAME}" --query "properties.provisioningState" -o tsv 2>/dev/null || echo "")
        if [[ "${rg_state}" == "Deleting" ]]; then
            info "Resource group ${RG_NAME} is being deleted — waiting..."
            az group wait --name "${RG_NAME}" --deleted --timeout 300 2>/dev/null || true
            info "Creating prerequisite resource group: ${RG_NAME}"
            az group create --name "${RG_NAME}" --location "${LOCATION}" -o none 2>&1
            _RG_CREATED_BY_US=true
        else
            info "Resource group ${RG_NAME} already exists — reusing"
        fi
    else
        info "Creating prerequisite resource group: ${RG_NAME}"
        az group create --name "${RG_NAME}" --location "${LOCATION}" -o none 2>&1
        _RG_CREATED_BY_US=true
    fi
}

cleanup_rg_if_we_created_it() {
    if ${_RG_CREATED_BY_US}; then
        info "Deleting prerequisite resource group: ${RG_NAME}"
        az group delete --name "${RG_NAME}" --yes --no-wait 2>/dev/null || true
    fi
}
