---
description: "Run a Unix commands bug bash — executes test steps one at a time, captures output to markdown files"
mode: "agent"
---

# Unix Commands Bug Bash

**Setup override**: Do not run `whoami`, and do not create/switch branches.

Run the bug bash on the current branch (main) and use a fixed results folder: `results_main/`.

Read the test steps from [test-steps.md](../../test-steps.md). Steps are organized into phases.

Each step in `test-steps.md` includes an execution indicator line in this format:
- `Execution: auto` means run immediately without approval.
- `Execution: approve` means pause for user approval via the built-in VS Code "Continue" button before execution.

Use the step's `Execution` value from `test-steps.md` as the source of truth for run behavior.

**Ask the user which phase(s) to run** before starting. Present the available phases as a numbered list and let the user choose:
- A single phase (e.g. "2")
- Multiple phases (e.g. "1, 3")
- "all" to run every phase

Then execute only the selected phase(s), **one step at a time**. Before starting each phase, display the phase name and the steps it contains.

For each step:

1. **Display the step description** (the blockquote text from test-steps.md) prominently based on execution mode:
   - If `Execution: auto`, use this exact format:
     ```
     > ## 🟠 {step description}
     ```
   - If `Execution: approve`, use this exact format:
     ```
     > ## 🔴 {step description}
     ```
   Then show the phase, step number, title, execution mode (`auto` or `approve`), and the command you are about to run.
2. **Execute based on the step indicator**:
   - If `Execution: auto`, run the command immediately.
   - If `Execution: approve`, pause for user approval via the built-in VS Code "Continue" button before execution.
3. **Capture the terminal output** and create a markdown file named `step-{N}-{short-name}-{YYYYMMDDHHMMSS}.md` inside the `results_main/` folder, where the timestamp uses 24-hour format (e.g. `step-1-check-os-info-20260312143025.md`). Use a per-step runtime/current-context timestamp directly, and do **not** run a separate `date` command for each step. Each file should contain:
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

**Do NOT batch multiple terminal commands in a single call.** Run exactly one command per step and follow that step's `Execution` indicator.

---

## Final Step — Generate Summary

After all steps are complete, create a `results_main/summary.md` file that contains:
- A table listing every phase, step, its command, and whether it succeeded or failed
- Total number of steps completed
- Timestamp of the full run
