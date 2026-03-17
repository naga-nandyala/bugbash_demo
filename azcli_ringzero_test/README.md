# Azure Ring Zero — Service Validation Suite

Validate Azure's foundational Ring Zero services using the Azure CLI. Designed as a **capstone exercise** for bug bash participants running against their own VS Enterprise Azure subscriptions.

## What are Ring Zero Services?

Ring Zero services are the foundational infrastructure that Azure itself depends on. If any of them go down, virtually every other Azure service is affected.

| # | Service | What it provides |
|---|---------|-----------------|
| 1 | **Entra ID** (Azure AD) | Identity and authentication for all Azure services |
| 2 | **Azure Resource Manager** (ARM) | Control plane for provisioning and managing resources |
| 3 | **Azure DNS** | Name resolution underpinning Azure's networking |
| 4 | **Azure Networking** | Virtual networks, subnets, network security groups |
| 5 | **Azure Storage** | Object/blob storage used internally by many services |
| 6 | **Azure Compute** | Hypervisor and fabric controller for VMs |
| 7 | **Azure Key Vault** | Secrets and certificate management |
| 8 | **Azure Monitor** | Telemetry, metrics, and log analytics pipeline |

## Prerequisites

- [Azure CLI](https://aka.ms/installazurecli) installed
- Logged in: `az login`
- An active Azure subscription (VS Enterprise recommended)

## Quick Start

```bash
cd azcli_ringzero_test/
./main.sh                # Run all 8 service tests
```

The script will:

1. Show your current subscription and ask for confirmation
2. Run each test through the full lifecycle: **Create → Verify → Show → Delete → Verify deletion**
3. Print a color-coded pass/fail summary
4. Log all output to `logs_ringzero_test_<whoami>/` (one log per script, timestamped)

## Run Individual Tests

Each service has its own standalone script:

```bash
./main.sh 1 3 5          # Run only Entra ID, DNS, and Storage
./3_dns.sh               # Run just DNS standalone (self-cleaning)
```

> **Note:** Each script is fully self-contained — it creates any prerequisites (resource group, VNet) it needs, runs the full lifecycle, and cleans up after itself. No manual cleanup required.

## Scripts

```
azcli_ringzero_test/
├── main.sh              # Orchestrator — runs selected tests, tracks results
├── 1_entra_id.sh        # Creates & verifies a service principal
├── 2_arm.sh             # Creates & verifies a resource group
├── 3_dns.sh             # Creates a DNS zone + A record
├── 4_networking.sh      # Creates VNet with subnet + NSG
├── 5_storage.sh         # Creates storage account, container, uploads blob
├── 6_compute.sh         # Creates a Standard_B1s VM
├── 7_keyvault.sh        # Creates vault, stores & retrieves a secret
├── 8_monitor.sh         # Creates Log Analytics workspace
└── lib/
    └── common.sh        # Shared config, colors, logging, lifecycle helpers
```

## How It Works

- **Lifecycle:** Every script follows Create → Verify → Show → Delete → Verify deletion
- Resource names use a unique ID derived from your username (first 5 chars + 3 random digits, e.g. `naga482`)
- Each script auto-creates prerequisites (RG, VNet) if needed and cleans them up when done
- If a script detects a resource group mid-deletion (from a prior run), it waits before proceeding
- VM is deleted with `--force-deletion` to minimize wait time
- Key Vault is soft-deleted then purged to release the name
- Each script exits `0` on PASS, `1` on FAIL
- All output is logged to `logs_ringzero_test_<whoami>/` with timestamped filenames

## Cleanup

Cleanup is automatic — each script deletes what it creates. If a run is interrupted, you can manually clean up:

```bash
# Find any leftover resource groups
az group list --query "[?starts_with(name, 'rg-ringzero')]" -o table

# Delete a specific one
az group delete --name rg-ringzero-XXXXX --yes --no-wait

# Find leftover service principals
az ad sp list --display-name "sp-ringzero" -o table
```
