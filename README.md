# bugbash-azcli

This repo contains the bug bash for Azure CLI — along with a demo simulation that uses simple, harmless Unix commands to show participants how the actual bug bash will look and feel before they run the real thing.

## Exercises

| Exercise | Description | Details |
|----------|-------------|---------|
| **Unix Commands (Demo Simulation)** | 8 guided steps across 2 phases with all execution modes: auto, interactive, manual, destructive | [bugbash_demo/](bugbash_demo/) |
| **Azure CLI — Ring Zero** | 8 Azure CLI scripts testing foundational Azure services (Entra ID, ARM, DNS, Networking, Storage, Compute, Key Vault, Monitor) | [README_AzCLI_RingZeroTest.md](README_AzCLI_RingZeroTest.md) |

## Structure

```
bugbash_demo/
├── README.md                        # This file
├── README_AzCLI_RingZeroTest.md     # Azure Ring Zero test details
├── bugbash_demo/
│   ├── phase1-steps.md               # Phase 1 — System & Environment Basics
│   └── phase2-steps.md               # Phase 2 — Process & Network Checks
├── azcli_ringzero_test/             # Azure CLI test scripts
│   ├── main.sh                      # Orchestrator
│   ├── 1_entra_id.sh … 8_monitor.sh # Individual service tests
│   └── lib/common.sh               # Shared helpers
├── logs_ringzero_test_<whoami>/     # Auto-generated test logs
└── _archive/                        # Archived prompts
```

## Prerequisites

- **Unix exercises:** Any Linux/macOS terminal
- **Azure exercises:** Azure CLI installed, logged in (`az login`), active Azure subscription (VS Enterprise recommended)

## Quick Start

### Unix Commands (Demo Simulation)
Follow the steps in [bugbash_demo/phase1-steps.md](bugbash_demo/phase1-steps.md) and [bugbash_demo/phase2-steps.md](bugbash_demo/phase2-steps.md).

### Azure Ring Zero
```bash
cd azcli_ringzero_test/
./main.sh          # Run all 8 tests
./main.sh 1 3 5    # Run specific tests
./3_dns.sh         # Run one test standalone
```

Each Azure test follows the lifecycle: **Create → Verify → Show → Delete → Verify deletion** — no leftover resources.
