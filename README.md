# bugbash-azcli

This repo contains the bug bash for Azure CLI — along with a demo simulation that uses simple, harmless Unix commands to show participants how the actual bug bash will look and feel before they run the real thing.

## Exercises

| Exercise | Description | Details |
|----------|-------------|---------|
| **Unix Commands (Demo Simulation)** | 8 guided steps across 2 phases with all execution modes: auto, interactive, manual, destructive | [bugbash_demo/](bugbash_demo/) |
| **Azure CLI — Ring Zero (Individual)** | 8 Azure CLI scripts testing foundational Azure services individually (Create → Verify → Delete per service) | [azcli_ringzero_test/](azcli_ringzero_test/) |
| **Azure CLI — Ring Zero (Integrated)** | All 8 services deployed together as an interconnected architecture in a single RG, with user-confirmed cleanup | [azcli_ringzero_integrated/](azcli_ringzero_integrated/) |
| **Azure CLI — Install & Broker Test** _(Bug Bash)_ | 39 steps across 6 phases: existing state, cask install, offline tarball, broker auth, Ring Zero, telemetry | [azcli_install_and_broker_test/](azcli_install_and_broker_test/) |

## Structure

```
├── README.md                            # This file
├── README_BugBash.md                    # Bug bash overview
├── .github/prompts/
│   ├── bugbash_demo.prompt.md           # Copilot prompt — Unix demo
│   └── bugbash.prompt.md                # Copilot prompt — Install & Broker
├── bugbash_demo/
│   ├── README.md                      # Unix demo simulation details
│   ├── phase1-steps.md                  # Phase 1 — System & Environment Basics
│   └── phase2-steps.md                  # Phase 2 — Process & Network Checks
├── azcli_ringzero_test/                 # Individual service test scripts
│   ├── README.md                        # Ring Zero individual test details
│   ├── main.sh                          # Orchestrator
│   ├── 1_entra_id.sh … 8_monitor.sh     # Individual service tests
│   └── lib/common.sh                    # Shared helpers
├── azcli_ringzero_integrated/           # Integrated architecture test
│   ├── README.md                        # Ring Zero integrated architecture details
│   └── integrated_test.sh               # All-in-one: deploy, verify, inspect, cleanup
├── azcli_install_and_broker_test/       # Actual bug bash exercise
│   ├── README.md                        # Install & Broker Test details
│   ├── phase1-steps.md                  # Phase 1 — Existing State
│   ├── phase2-steps.md                  # Phase 2 — Cask Install
│   ├── phase3-steps.md                  # Phase 3 — Offline Install
│   ├── phase4-steps.md                  # Phase 4 — Ring Zero
│   ├── phase5-steps.md                  # Phase 5 — Broker Auth
│   └── phase6-steps.md                  # Phase 6 — Telemetry
├── resources/images/                    # Screenshots and diagrams
└── logs_ringzero_test_<whoami>/         # Auto-generated test logs
```

## Getting Started (Bug Bash Participants)

1. **Clone this repo and open in VS Code**
   ```
   git clone https://github.com/naga-nandyala/bugbash-azcli.git
   cd bugbash-azcli
   code .
   ```

2. **Create your `.env` file**
   ```
   cp .env.template .env
   ```
   Edit `.env` and fill in your values (tenant ID, org URL, VSE subscription).

3. **Open Copilot Chat** — press `Ctrl+Shift+I` (or `Cmd+Shift+I` on Mac)

4. **Run the bug bash prompt** — type `/` in Copilot Chat, select **bugbash**, and press Enter. Copilot will ask which phase(s) to run.

5. **Follow along** — Copilot executes each step one at a time. `[auto]` steps run immediately; `[interactive]` and `[destructive]` steps ask for confirmation; `[manual]` steps show you the command to run yourself.

6. **Results** — All outputs are saved to `logs_bugbash_results_<your-username>/` inside the repo (gitignored).

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
Use the prompt file [.github/prompts/bugbash.prompt.md](.github/prompts/bugbash.prompt.md) in GitHub Copilot Chat. 39 steps across 6 phases testing the full Azure CLI macOS Homebrew Cask lifecycle.

Phase files:
- [azcli_install_and_broker_test/phase1-steps.md](azcli_install_and_broker_test/phase1-steps.md) — Existing State
- [azcli_install_and_broker_test/phase2-steps.md](azcli_install_and_broker_test/phase2-steps.md) — Cask Install
- [azcli_install_and_broker_test/phase3-steps.md](azcli_install_and_broker_test/phase3-steps.md) — Offline Install
- [azcli_install_and_broker_test/phase4-steps.md](azcli_install_and_broker_test/phase4-steps.md) — Ring Zero
- [azcli_install_and_broker_test/phase5-steps.md](azcli_install_and_broker_test/phase5-steps.md) — Broker Auth
- [azcli_install_and_broker_test/phase6-steps.md](azcli_install_and_broker_test/phase6-steps.md) — Telemetry

See [azcli_install_and_broker_test/](azcli_install_and_broker_test/) for full details.
