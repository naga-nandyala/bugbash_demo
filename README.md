# bugbash-azcli

This repo contains the bug bash for Azure CLI — along with a demo simulation that uses simple, harmless Unix commands to show participants how the actual bug bash will look and feel before they run the real thing.

## Exercises

| Exercise | Description | Details |
|----------|-------------|---------|
| **Unix Commands (Demo Simulation)** | 8 guided steps across 2 phases with all execution modes: auto, interactive, manual, destructive | [README_BugBash_Demo.md](README_BugBash_Demo.md) |
| **Azure CLI — Ring Zero (Individual)** | 8 Azure CLI scripts testing foundational Azure services individually (Create → Verify → Delete per service) | [README_AzCLI_RingZeroTest.md](README_AzCLI_RingZeroTest.md) |
| **Azure CLI — Ring Zero (Integrated)** | All 8 services deployed together as an interconnected architecture in a single RG, with user-confirmed cleanup | [README_AzCLI_RingZeroIntegrated.md](README_AzCLI_RingZeroIntegrated.md) |
| **Azure CLI — Install & Broker Test** _(Bug Bash)_ | The actual bug bash exercise — details TBD | [azcli_install_and_broker_test/](azcli_install_and_broker_test/) |

## Structure

```
├── README.md                            # This file
├── README_BugBash_Demo.md               # Unix demo simulation details
├── README_AzCLI_RingZeroTest.md         # Ring Zero individual test details
├── README_AzCLI_RingZeroIntegrated.md   # Ring Zero integrated architecture details
├── bugbash_demo/
│   ├── phase1-steps.md                  # Phase 1 — System & Environment Basics
│   └── phase2-steps.md                  # Phase 2 — Process & Network Checks
├── azcli_ringzero_test/                 # Individual service test scripts
│   ├── main.sh                          # Orchestrator
│   ├── 1_entra_id.sh … 8_monitor.sh     # Individual service tests
│   └── lib/common.sh                    # Shared helpers
├── azcli_ringzero_integrated/           # Integrated architecture test
│   └── integrated_test.sh               # All-in-one: deploy, verify, inspect, cleanup
├── azcli_install_and_broker_test/       # Actual bug bash exercise (TBD)
├── resources/images/                    # Screenshots and diagrams
└── logs_ringzero_test_<whoami>/         # Auto-generated test logs
```

## Prerequisites

- **Unix exercises:** Any Linux/macOS terminal
- **Azure exercises:** Azure CLI installed, logged in (`az login`), active Azure subscription (VS Enterprise recommended)

## Quick Start

### Unix Commands (Demo Simulation)
Use the prompt file [.github/prompts/bugbash_demo.prompt.md](.github/prompts/bugbash_demo.prompt.md) in GitHub Copilot Chat. Copilot will read the phase files, execute each step for you based on its mode (`[auto]`, `[interactive]`, `[manual]`, `[destructive]`), capture outputs, and generate result logs — all guided through chat.

Phase files:
- [bugbash_demo/phase1-steps.md](bugbash_demo/phase1-steps.md) — System & Environment Basics
- [bugbash_demo/phase2-steps.md](bugbash_demo/phase2-steps.md) — Process & Network Checks

### Azure Ring Zero — Individual Tests
```bash
cd azcli_ringzero_test/
./main.sh          # Run all 8 tests
./main.sh 1 3 5    # Run specific tests
./3_dns.sh         # Run one test standalone
```

Each test follows the lifecycle: **Create → Verify → Show → Delete → Verify deletion** — no leftover resources.

### Azure Ring Zero — Integrated Architecture
```bash
cd azcli_ringzero_integrated/
./integrated_test.sh
```

Deploys all services into a single RG as an interconnected architecture. Pauses for portal inspection, then asks for **explicit confirmation** before cleanup.

### Azure CLI — Install & Broker Test _(Bug Bash)_
Details TBD — see [azcli_install_and_broker_test/](azcli_install_and_broker_test/).
