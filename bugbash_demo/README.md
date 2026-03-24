# Bug Bash Demo Walkthrough

This demo uses simple, harmless commands to show exactly how the actual bug bash will look and feel — the step modes, the prompts, the output capture, and the phase flow.

No Azure resources or credentials are needed. The goal is to let participants experience the full bug bash workflow before running the real Azure CLI bug bash.

**Supported shells**: bash/zsh (Linux, macOS, WSL) and PowerShell (`pwsh` on Windows). Each step provides both a `bash` and a `pwsh` command variant — the prompt automatically detects the active shell and picks the right one.

It is based on:
- Prompt rules in [../.github/prompts/bugbash_demo.prompt.md](../.github/prompts/bugbash_demo.prompt.md)
- Steps in [phase1-steps.md](phase1-steps.md) and [phase2-steps.md](phase2-steps.md)

## What A Real Run Looks Like

1. Run setup first:
   - `whoami`
2. Build dynamic output folder:
   - `logs_bugbash_results_<whoami_output>/`
   - Example: `logs_bugbash_results_naga/`
3. Ask which phase(s) to execute (`1`, `2`, `1,2`, or `all`).
4. Execute one step at a time.
5. Save one markdown result file per step:
   - `step-{N}-{short-name}-{YYYYMMDDHHMMSS}.md`
6. Print phase completion banner after each phase.
7. Generate final summary file:
   - `logs_bugbash_results_<whoami_output>/summary.md`

## Step Modes (How Each One Behaves)

Use this section as the quick reference to understand exactly how each mode behaves during the real bug bash.

| Mode Tag | Behavior During Run | User Interaction |
|---|---|---|
| `[auto]` | Command runs immediately | None required |
| `[interactive]` | Warn user, run command, ask what they observed | User confirms output looked right/wrong |
| `[manual]` | Show command only (do not execute) | User runs command and pastes output |
| `[destructive]` | Show warning and ask `Proceed? (yes/no)` before running | User must explicitly approve |

## Prompt Styling Used For Each Step

For non-destructive steps:

```text
> ## 🟠 {step description}
```

For destructive steps:

```text
> ## 🔴 {step description}
```

At end of phase:

```text
> ## ✅ Phase {N} — {Phase Name} — COMPLETE
```

## Example Flow Snippets

### Example `[auto]` (bash)

```text
> ## 🔵 Verify the operating system, kernel version, and architecture of the machine.
Phase: 1 — System & Environment Basics
Step: 1 — Check OS Info
Type: [auto]
Command: uname -a

# command runs immediately
```

### Example `[auto]` (pwsh)

```text
> ## 🔵 Verify the operating system, kernel version, and architecture of the machine.
Phase: 1 — System & Environment Basics
Step: 1 — Check OS Info
Type: [auto]
Command: [System.Environment]::OSVersion; $PSVersionTable

# command runs immediately
```

### Example `[interactive]`

```text
> ## 🟠 Check total, used, and available RAM and swap space, then confirm the output looks correct.
Phase: 1 — System & Environment Basics
Step: 2 — Memory Usage
Type: [interactive]
Command (bash): free -h
Command (pwsh): Get-CimInstance Win32_OperatingSystem | Select-Object TotalVisibleMemorySize, FreePhysicalMemory, TotalVirtualMemorySize, FreeVirtualMemory

Warning: this interactive step requires confirmation after execution.
# command runs
Please confirm:
1. Output looked correct
2. Output looked incorrect
```

### Example `[manual]`

```text
> ## 🟠 Open a terminal and run `du -sh ~` to check home directory usage. Paste the output here.
Phase: 1 — System & Environment Basics
Step: 3 — Home Directory Size
Type: [manual]
Command (do not auto-run, bash): du -sh ~
Command (do not auto-run, pwsh): Get-ChildItem ~ | Format-Table Name, Length, LastWriteTime

# user runs command and pastes output
```

### Example `[destructive]`

```text
> ## 🔴 Create a temporary file in /tmp, verify it exists, then delete it.
Phase: 1 — System & Environment Basics
Step: 4 — Temp File Lifecycle
Type: [destructive]
Command: touch /tmp/bugbash_test_file && ls -l /tmp/bugbash_test_file && rm /tmp/bugbash_test_file

Warning: this step creates and removes a file in /tmp.
Proceed? (yes/no)
```

## Result File Contents (Per Step)

Each step file contains:
- Phase name
- Step number and title
- Execution mode
- Exact command run
- Full terminal output in a code block
- Execution timestamp

## Cross-Platform Support

Each step in the phase files provides two command variants in labeled fenced code blocks:
- `` ```bash `` — for bash/zsh (Linux, macOS, WSL)
- `` ```pwsh `` — for PowerShell (Windows)

The prompt automatically detects the active shell and selects the matching command.

## Current 2-Phase Coverage

The current phase files ([phase1-steps.md](phase1-steps.md) and [phase2-steps.md](phase2-steps.md)) intentionally cover 2 phases, and both include all four step modes:
- `[auto]`
- `[interactive]`
- `[manual]`
- `[destructive]`

This gives full mode coverage while keeping the bug bash compact.
