---
description: "Run a cross-platform commands bug bash (bash/zsh/pwsh) — executes test steps one at a time, captures output to markdown files"
mode: "agent"
---

# Unix Commands Bug Bash

**Setup**: Run `whoami` first to get the current username, and do not create/switch branches.

**Shell detection**: Detect the user's shell environment before running any steps. Check the active terminal — if it is PowerShell (`pwsh`), use the `pwsh` code blocks from the phase files. If it is bash/zsh (Linux/macOS/WSL), use the `bash` code blocks. Each step in the phase files provides both a `bash` and a `pwsh` command variant. Always pick the one matching the detected shell. The `whoami` command works on all platforms.

Run the bug bash on the current branch (main) and use a dynamic results folder: `logs_bugbash_demo_results_<whoami_output>/` (e.g. if `whoami` returns `naganandyala`, use `logs_bugbash_demo_results_naganandyala/`).

Read the test steps from the phase files in `bugbash_demo/`:
- [phase1-steps.md](../../bugbash_demo/phase1-steps.md) — Phase 1
- [phase2-steps.md](../../bugbash_demo/phase2-steps.md) — Phase 2

Each step in the phase files includes a tag indicating its type:
- `[auto]` — Safe, low-risk command. Run immediately with no user input needed.
- `[interactive]` — Warn the user what will happen (login prompt, dialog, etc.), run the command, wait for it to finish, then ask the user to confirm what they observed.
- `[destructive]` — Potentially dangerous command (e.g. uninstall, remove folder, kill process). Print a warning and ask "Proceed? (yes/no)" before running. If the user says no, mark the step as **SKIP**.
- `[manual]` — Show the command to the user but do **not** run it. Let the user run it themselves and paste the result back.

Use the step's tag from the phase files as the source of truth for run behavior.

Each step provides two command variants in fenced code blocks labeled `bash` and `pwsh`. Always use the variant matching the detected shell environment.

**Ask the user which phase(s) to run** before starting. Present the available phases as a numbered list and let the user choose:
- A single phase (e.g. "2")
- Multiple phases (e.g. "1, 3")
- "all" to run every phase

Then execute only the selected phase(s), **one step at a time**. Before starting each phase, display the phase name and the steps it contains.

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
3. **Capture the terminal output** and create a markdown file named `step-{N}-{short-name}-{YYYYMMDDHHMMSS}.md` inside the `logs_bugbash_demo_results_<whoami_output>/` folder, where the timestamp uses 24-hour format (e.g. `step-1-check-os-info-20260312143025.md`). Use a per-step runtime/current-context timestamp directly, and do **not** run a separate `date` command for each step. Each file should contain:
   - Phase name
   - Step number and title
   - Execution mode
   - The exact command run
   - The full terminal output (in a code block)
   - A timestamp of when it was executed
4. **Confirm completion** of the step, then move on to the next step.

**After the last step of each phase**, display a bold completion banner using this exact format:
```
> ## ✅ Phase {N} — {Phase Name} — COMPLETE
```

**Do NOT batch multiple terminal commands in a single call.** Run exactly one command per step and follow that step's type tag.

---

## Phase Summary — After Each Phase

After the last step of each phase, create a `logs_bugbash_demo_results_<whoami_output>/p{N}-summary.md` file (e.g. `p1-summary.md`) that contains:
- Phase name and number
- A table listing every step in that phase, its command, execution mode, and whether it passed, failed, or was skipped
- Number of steps completed, passed, failed, and skipped for that phase
- Timestamp of the phase run

---

## Final Step — Generate Overall Summary

After all selected phases are complete, create a `logs_bugbash_demo_results_<whoami_output>/summary.md` that consolidates **all `p{N}-summary.md` files found** in the results folder (not just the phases run in this session). This allows phases to be run across separate Copilot sessions and still produce a unified summary.
- A table listing every phase, step, its command, execution mode, and whether it passed, failed, or was skipped (combine all `p{N}-summary.md` data)
- Total number of steps completed, passed, failed, and skipped across all phases
- Timestamp of the full run
