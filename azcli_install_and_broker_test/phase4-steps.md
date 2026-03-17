# Phase 4 — Ring Zero Test

### Step 1 — Run integrated Ring Zero test
> Run the Ring Zero integrated test script that deploys all 8 foundational Azure services (Log Analytics, Key Vault, Storage Account, NSG, VNet + Subnet, Virtual Machine, DNS Zone, Service Principal) as an interconnected architecture in a single resource group, verifies them, then asks for confirmation before cleanup. Requires an active az login session.
[interactive]
```
cd ../azcli_ringzero_integrated
./integrated_test.sh
```
