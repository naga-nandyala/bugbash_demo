---
description: "Run the Azure CLI Install & Broker bug bash — executes test steps one at a time, captures output to markdown files"
mode: "agent"
---

# Azure CLI — Install & Broker Test Bug Bash

**Setup**: Run `whoami` first to get the current username. Detect architecture with `uname -m` and set `BREW_PREFIX` accordingly (`/opt/homebrew` for arm64, `/usr/local` for x86_64). Do not create/switch branches.

Create the results folder before writing any files: `mkdir -p logs_bugbash_results_<whoami_output>/`

Run the bug bash on the current branch (main) and use a dynamic results folder: `logs_bugbash_results_<whoami_output>/` (e.g. if `whoami` returns `naganandyala`, use `logs_bugbash_results_naganandyala/`).

Load environment variables from `.env` (at repo root) before starting:
```
source .env
```
If `.env` does not exist, tell the user to copy `.env.template` to `.env` and fill in the values, then stop.

| | |
|---|---|
| **Version** | 2.84.0 |
| **azclitools tenant** | `$AZCLITOOLS_TENANT_ID` (from `.env`) |
| **azclitools org** | `$AZCLITOOLS_ORG` (from `.env`) |
| **VSE subscription** | `$PERSONAL_VSE_TENANT_ID` (from `.env`, used in Phase 4 — Ring Zero) |

## Phase Sources

| Phase | Source | Tap / URL |
|-------|--------|----------|
| 1 — Existing State | Existing homebrew-core install | (no tap needed) |
| 2 — Cask Install | Azure/homebrew-azure-cli | `Azure/azure-cli` tap → `https://github.com/Azure/homebrew-azure-cli` |
| 3 — Offline Install | Azure/homebrew-azure-cli releases | `https://github.com/Azure/homebrew-azure-cli/releases/download/azure-cli-2.84.0/` |
| 4 — Ring Zero | Ring Zero scripts | (uses az login from prior phase) |
| 5 — Broker Auth | naga-nandyala/homebrew-mycli-app | `naga-nandyala/mycli-app` tap → `https://github.com/naga-nandyala/homebrew-mycli-app` |
| 6 — Telemetry | naga-nandyala/homebrew-mycli-app | (same cask as Phase 5, already installed) |

Read the test steps from the phase files in `azcli_install_and_broker_test/`:
- [phase1-steps.md](../../azcli_install_and_broker_test/phase1-steps.md) — Phase 1: Existing State (Homebrew-Core Baseline)
- [phase2-steps.md](../../azcli_install_and_broker_test/phase2-steps.md) — Phase 2: New Install via Homebrew-Cask
- [phase3-steps.md](../../azcli_install_and_broker_test/phase3-steps.md) — Phase 3: Offline Install (Tarball, Non-Homebrew Python)
- [phase4-steps.md](../../azcli_install_and_broker_test/phase4-steps.md) — Phase 4: Ring Zero Test
- [phase5-steps.md](../../azcli_install_and_broker_test/phase5-steps.md) — Phase 5: Broker Authentication
- [phase6-steps.md](../../azcli_install_and_broker_test/phase6-steps.md) — Phase 6: Telemetry Verification

Each step in the phase files includes a tag indicating its type:
- `[auto]` — Safe, low-risk command. Run immediately with no user input needed.
- `[interactive]` — Warn the user what will happen (login prompt, dialog, etc.), run the command, wait for it to finish, then ask the user to confirm what they observed.
- `[destructive]` — Potentially dangerous command (e.g. uninstall, remove folder, kill process). Print a warning and ask "Proceed? (yes/no)" before running. If the user says no, mark the step as **SKIP**.
- `[manual]` — Show the command to the user but do **not** run it. Let the user run it themselves and paste the result back.

Use the step's tag from the phase files as the source of truth for run behavior.

**Ask the user which phase(s) to run** before starting. Present the available phases as a numbered list and let the user choose:
- A single phase (e.g. "2")
- Multiple phases (e.g. "1, 4")
- "all" to run every phase

Then execute only the selected phase(s), **one step at a time**. Before starting each phase, display the phase name and the steps it contains.

**Phase-specific notes:**
- **Phase 3 (Offline Install):** Step 6 downloads and installs python.org Python 3.13 (requires sudo). If Step 6 fails (download or install error), also skip Steps 7 and 8.
- **Phase 4 (Ring Zero):** This phase runs an external script. Change directory and run it. The script handles its own prompts.
- **Phase 5 (Broker Auth):** Step 5 has a mandatory recovery block after the main commands — ensure Company Portal is reinstalled before proceeding.
- **Phase 6 (Telemetry):** Steps 1-3 capture CorrelationIds that need KQL verification later. Record them in the result files. Step 5 is a KQL query for the user to run in their telemetry dashboard.

For each step:

1. **Display the step description** (the blockquote text from the phase file) prominently based on step type:
   - If `[auto]`, use this exact format:
     ```
     > ## 🔵 {step description}
     ```
   - If `[interactive]` or `[manual]`, use this exact format:
     ```
     > ## 🟠 {step description}
     ```
   - If `[destructive]`, use this exact format:
     ```
     > ## 🔴 {step description}
     ```
   Then show the phase, step number, title, step type, and the command (if applicable).
2. **Execute based on the step type**:
   - If `[auto]`, run the command immediately. No user input needed.
   - If `[interactive]`, warn the user what will happen, run the command, wait for it to finish, then ask the user to confirm what they observed.
   - If `[destructive]`, print a warning and ask "Proceed? (yes/no)" before running. If the user says no, mark the step as **SKIP**.
   - If `[manual]`, show the command to the user but do **not** run it. Wait for the user to run it themselves and paste the result back.
3. **Capture the terminal output** and create a markdown file named `p{P}-step{N}-{short-name}-{YYYYMMDDHHMMSS}.md` inside the `logs_bugbash_results_<whoami_output>/` folder, where `{P}` is the phase number, `{N}` is the step number within that phase, and the timestamp uses 24-hour format (e.g. `p1-step1-installation-check-20260317143025.md`). Use a per-step runtime/current-context timestamp directly, and do **not** run a separate `date` command for each step. Each file should contain:
   - Phase name
   - Step number and title
   - Execution mode
   - The exact command run
   - The full terminal output (in a code block)
   - A timestamp of when it was executed
   - Pass/fail assessment based on the expected behavior described in the step
4. **Confirm completion** of the step, then move on to the next step.

**After the last step of each phase**, display a bold completion banner using this exact format:
```
> ## ✅ Phase {N} — {Phase Name} — COMPLETE
```

**Do NOT batch multiple steps in a single terminal call.** Each step's code block runs as one command. Follow that step's type tag.

**Do NOT use heredoc syntax** (`cat << EOF` or `<<-EOF`) — it will fail in this environment.

**Never fabricate output.** Record actual terminal output only. If a command produces no output, record that.

**If a step FAILs**, stop and ask the user: "Step N failed. Continue to next step, retry, or abort?" Record FAIL in the result file regardless.

**Pre-phase setup:** If a phase file contains a `Note:` block with setup commands before the first step, execute those commands first (following their tag if present, or as `[auto]` if untagged).

---

## Phase Summary — After Each Phase

After the last step of each phase, create a `logs_bugbash_results_<whoami_output>/p{N}-summary.md` file (e.g. `p1-summary.md`) that contains:
- Phase name and number
- Test metadata (version, cask source, architecture, hostname)
- A table listing every step in that phase, its command, execution mode, and whether it passed, failed, or was skipped
- Number of steps completed, passed, failed, and skipped for that phase
- Timestamp of the phase run
- Any CorrelationIds captured during telemetry steps (for later KQL verification)

---

## Final Step — Generate Overall Summary

After all selected phases are complete, create a `logs_bugbash_results_<whoami_output>/summary.md` that consolidates **all `p{N}-summary.md` files found** in the results folder (not just the phases run in this session). This allows phases to be run across separate Copilot sessions and still produce a unified summary.
- Test metadata (version, cask source, architecture, hostname)
- A table listing every phase, step, its command, execution mode, and whether it passed, failed, or was skipped (combine all `p{N}-summary.md` data)
- Total number of steps completed, passed, failed, and skipped across all phases
- Timestamp of the full run
- Any CorrelationIds captured during telemetry steps (for later KQL verification)
