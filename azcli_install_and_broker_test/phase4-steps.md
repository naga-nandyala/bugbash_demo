# Phase 4 — Ring Zero Test

### Step 1 — Install Azure CLI via Homebrew tap
> Phases 2 and 3 uninstall Azure CLI. Re-install it via the Azure/azure-cli Homebrew cask tap so we have a working `az` for Ring Zero testing.
[auto]
```
brew tap Azure/azure-cli 2>/dev/null || true
brew install --cask azure-cli
which az
az --version
```

### Step 2 — Login
> Login to Azure using your personal VSE tenant if available, otherwise fall back to the azclitools tenant. A browser prompt will open. Complete the login and select the tenant if prompted.
[interactive]
```
source ../.env
TENANT_ID="${PERSONAL_VSE_TENANT_ID:-$AZCLITOOLS_TENANT_ID}"
echo "Logging in to tenant: ${TENANT_ID}"
az login --tenant "${TENANT_ID}"
az account show --output table
```

### Step 3 — Run integrated Ring Zero test
> Run the Ring Zero integrated test script that deploys all 8 foundational Azure services (Log Analytics, Key Vault, Storage Account, NSG, VNet + Subnet, Virtual Machine, DNS Zone, Service Principal) as an interconnected architecture in a single resource group, verifies them, then asks for confirmation before cleanup. Requires an active az login session.
[interactive]
```
cd ../azcli_ringzero_integrated
./integrated_test.sh
```
