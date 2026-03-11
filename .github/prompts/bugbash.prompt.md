---
description: "Run a Unix commands bug bash — executes test steps one at a time, captures output to markdown files"
mode: "agent"
---

# Unix Commands Bug Bash

**First**, run `whoami` to get the current username. Use this to create the results folder named `results_{username}/` (e.g. `results_naga/`).

**Next**, create and switch to a git branch named `bb_{username}` (e.g. `bb_naga`). Run `git checkout -b bb_{username}`. If the branch already exists, just switch to it with `git checkout bb_{username}`.

Read the test steps from [test-steps.md](../../test-steps.md). Steps are organized into phases.

**Ask the user which phase(s) to run** before starting. Present the available phases as a numbered list and let the user choose:
- A single phase (e.g. "2")
- Multiple phases (e.g. "1, 3")
- "all" to run every phase

Then execute only the selected phase(s), **one step at a time**. Before starting each phase, display the phase name and the steps it contains.

For each step:

1. **Display the step description** (the blockquote text from test-steps.md) prominently using this exact format:
   ```
   > ## 🔴 {step description}
   ```
   Then show the phase, step number, title, and the command you are about to run.
2. **Immediately run the command** in the terminal. The user will approve via the built-in VS Code "Continue" button before it executes.
3. **Capture the terminal output** and create a markdown file named `step-{N}-{short-name}-{YYYYMMDDHHMMSS}.md` inside the `results_{username}/` folder, where the timestamp uses 24-hour format (e.g. `step-1-check-os-info-20260312143025.md`). Each file should contain:
   - Phase name
   - Step number and title
   - The exact command run
   - The full terminal output (in a code block)
   - A timestamp of when it was executed
4. **Confirm completion** of the step, then move on to the next step.

**After the last step of each phase**, display a bold completion banner using this exact format:
```
> ## ✅ Phase {N} — {Phase Name} — COMPLETE
```

**Do NOT batch multiple terminal commands in a single call.** Run exactly one command per step so the user gets an approval prompt for each one.

---

## Final Step — Generate Summary

After all steps are complete, create a `results_{username}/summary.md` file that contains:
- A table listing every phase, step, its command, and whether it succeeded or failed
- Total number of steps completed
- Timestamp of the full run
