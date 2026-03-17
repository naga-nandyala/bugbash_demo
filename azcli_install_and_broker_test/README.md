# Azure CLI — Install & Broker Test (Bug Bash)

End-to-end bug bash exercise for Azure CLI macOS Homebrew Cask distribution. Tests the full lifecycle: existing state capture, cask install, offline tarball install, broker authentication, Ring Zero service deployment, and telemetry verification.

## Why Two Custom Taps?

The bug bash tests two separate releases of Azure CLI:

1. **`Azure/homebrew-azure-cli`** — The initial release build **without** the broker change. Phases 1-4 use this tap to validate core install, cask lifecycle, offline tarball, and Ring Zero against the baseline release.
2. **`naga-nandyala/homebrew-mycli-app`** — A second release build **with** the broker change (macOS SSO via Company Portal). Phases 5-6 switch to this tap to test broker authentication and verify broker-specific telemetry fields.

This dual-tap approach lets participants validate the full install lifecycle on the non-broker build first, then switch to the broker-enabled build for authentication and telemetry — mirroring the actual staged rollout plan.

## Phase Sources

| Phase | Source | Tap / URL |
|-------|--------|----------|
| 1 — Existing State | Existing homebrew-core install | (no tap needed) |
| 2 — Cask Install | Azure/homebrew-azure-cli | `Azure/azure-cli` tap → `https://github.com/Azure/homebrew-azure-cli` |
| 3 — Offline Install | Azure/homebrew-azure-cli releases | `https://github.com/Azure/homebrew-azure-cli/releases/` |
| 4 — Ring Zero | Ring Zero scripts | (uses az login from prior phase) |
| 5 — Broker Auth | naga-nandyala/homebrew-mycli-app | `naga-nandyala/mycli-app` tap → `https://github.com/naga-nandyala/homebrew-mycli-app` |
| 6 — Telemetry | naga-nandyala/homebrew-mycli-app | (same cask as Phase 5, already installed) |

## Phases

| Phase | Name | Steps | Types |
|-------|------|-------|-------|
| 1 | Existing State (Homebrew-Core Baseline) | 7 | auto, interactive, destructive |
| 2 | New Install via Homebrew-Cask | 11 | auto, interactive, destructive |
| 3 | Offline Install (Tarball, Non-Homebrew Python) | 9 | auto, interactive, destructive |
| 4 | Ring Zero Test | 1 | interactive |
| 5 | Broker Authentication | 6 | auto, interactive, destructive |
| 6 | Telemetry Verification | 5 | interactive, auto, manual |
| | **Total** | **39** | |

## Step Execution Modes

| Tag | Behavior |
|-----|----------|
| `[auto]` | Run immediately, no user input needed |
| `[interactive]` | Warn user, run command, ask user to confirm what they observed |
| `[destructive]` | Print warning, ask "Proceed? (yes/no)" before running |
| `[manual]` | Show command, user runs it and pastes result back |

## Prerequisites

- macOS (ARM64 or Intel)
- Homebrew installed
- VS Code with GitHub Copilot Chat extension
- Azure CLI currently installed via homebrew-core (for Phase 1 baseline)
- Active Azure subscription (VS Enterprise recommended for Ring Zero)
- Company Portal (Microsoft Intune) installed (for Phase 5 broker tests)
- Non-Homebrew Python 3.13 (python.org or pyenv) for Phase 3 offline tests (optional — can be skipped)

## Quick Start

**1. Clone and open the repo**

```bash
git clone https://github.com/naga-nandyala/bugbash-azcli.git
cd bugbash-azcli
code .
```

**2. Set up your environment**

```bash
cp .env.template .env
```

Edit `.env` and fill in your `PERSONAL_VSE_TENANT_ID` (Azure subscription ID for Ring Zero deployments). The tenant ID and org URL are pre-filled.

**3. Launch the bug bash**

Open GitHub Copilot Chat in VS Code and use the prompt file:

**[../.github/prompts/bugbash.prompt.md](../.github/prompts/bugbash.prompt.md)**

Copilot will:
1. Ask which phase(s) to run
2. Execute each step based on its type tag
3. Capture outputs to `logs_bugbash_results_<whoami>/` as per-step markdown files
4. Generate a summary after all steps complete

## Phase Files

- [phase1-steps.md](phase1-steps.md) — Existing State (Homebrew-Core Baseline)
- [phase2-steps.md](phase2-steps.md) — New Install via Homebrew-Cask
- [phase3-steps.md](phase3-steps.md) — Offline Install (Tarball, Non-Homebrew Python)
- [phase4-steps.md](phase4-steps.md) — Ring Zero Test
- [phase5-steps.md](phase5-steps.md) — Broker Authentication
- [phase6-steps.md](phase6-steps.md) — Telemetry Verification

## Phase Details

### Phase 1 — Existing State
Captures the current homebrew-core install baseline: version, extensions, config. Logs in to azclitools, tests az upgrade and reinstall, then uninstalls the formula (preserving ~/.azure).

### Phase 2 — Cask Install
Taps `Azure/azure-cli` (from `Azure/homebrew-azure-cli`), installs the azure-cli cask, verifies code signing (Gatekeeper), tests basic functionality, extensions, az upgrade, reinstall/upgrade, and clean uninstall.

### Phase 3 — Offline Install
Downloads the release tarball from `Azure/homebrew-azure-cli` releases, verifies signatures, confirms az fails gracefully without AZ_PYTHON, then runs az with a non-Homebrew Python. Tests extension loading in offline mode.

### Phase 4 — Ring Zero Test
Runs the integrated Ring Zero test script that deploys 8 foundational Azure services (Log Analytics, Key Vault, Storage, NSG, VNet, VM, DNS, Service Principal) as an interconnected architecture.

### Phase 5 — Broker Authentication
Taps `naga-nandyala/mycli-app` (from `naga-nandyala/homebrew-mycli-app`), re-installs the cask, then tests broker login (Company Portal SSO), disable/re-enable broker toggle, graceful fallback when Company Portal is removed, and tenant-scoped login.

### Phase 6 — Telemetry Verification
Captures CorrelationIds from broker login, cancelled login, and non-broker login for later KQL verification. Checks the installer field shows HOMEBREW_CASK. Includes KQL query for MSAL version fields.

## Notes

- Run phases in order (1 through 6) for the cleanest experience
- Phase 1 ends by uninstalling the formula; Phase 2 installs the cask
- Phase 2 ends by uninstalling the cask; Phase 5 re-installs it for broker tests
- Phase 4 requires an active az login session
- Phase 6 telemetry verification via KQL should be done ~1 hour after the login events
- Results are saved to `logs_bugbash_results_<whoami>/` with per-step markdown files and a final summary

## Test Metadata

| | |
|---|---|
| **azclitools tenant** | `ed94de55-1f87-4278-9651-525e7ba467d6` |
| **azclitools org** | `https://dev.azure.com/azclitools` |
| **Architectures** | ARM64 (Apple Silicon) and Intel (x86_64) |
