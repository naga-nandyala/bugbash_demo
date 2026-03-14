# Bug Bash Demo

A collection of exercises for bug bash participants to validate system fundamentals and Azure Ring Zero services.

## Exercises

| Exercise | Description | Details |
|----------|-------------|---------|
| **Unix Commands** | 14 system validation steps covering OS info, files, processes, and networking | [test-steps.md](test-steps.md) |
| **Azure CLI — Ring Zero** | 8 Azure CLI scripts testing foundational Azure services (Entra ID, ARM, DNS, Networking, Storage, Compute, Key Vault, Monitor) | [README_AzCLI_RingZeroTest.md](README_AzCLI_RingZeroTest.md) |

## Structure

```
bugbash_demo/
├── README.md                        # This file
├── README_AzCLI_RingZeroTest.md     # Azure Ring Zero test details
├── test-steps.md                    # Unix command exercises
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

### Unix Commands
Follow the steps in [test-steps.md](test-steps.md).

### Azure Ring Zero
```bash
cd azcli_ringzero_test/
./main.sh          # Run all 8 tests
./main.sh 1 3 5    # Run specific tests
./3_dns.sh         # Run one test standalone
```

Each Azure test follows the lifecycle: **Create → Verify → Show → Delete → Verify deletion** — no leftover resources.
