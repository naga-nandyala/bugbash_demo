# Azure CLI v2.84.0 macOS Bug Bash — Video Script

## Video Metadata

| | |
|---|---|
| **Target length** | 8–10 minutes |
| **Audience** | Bug bash participants + non-participating team members |
| **Tone** | Technical but approachable — think team demo, not conference talk |

---

## SLIDE 1 — Title (0:00–0:15)

**Visual:** Title card with Azure CLI logo

> "Azure CLI v2.84.0 — macOS Install & Broker Auth Bug Bash"
>
> Teams: Azure CLI Packaging · MSAL Broker · Release Engineering

---

## SLIDE 2 — Why This Bug Bash (0:15–1:45)

**Visual:** Bullet points appearing one at a time

**Script:**

> We are introducing **two new ways to install Azure CLI on macOS**, along with a major **broker authentication change**, in the near future. This bug bash validates all three.
>
> **New installation method 1 — Homebrew Cask.** Today, Azure CLI on macOS installs via a Homebrew **formula** — a source-built `pip install` on the user's machine. We're moving to a Homebrew **Cask**: a self-contained, pre-built bundle that ships its own Python, native binaries, and codesigned extensions. No more build-time failures or dependency conflicts.
>
> **New installation method 2 — Offline Tarball.** For air-gapped environments, restricted networks, or customers who don't use Homebrew, we're publishing architecture-specific tarballs (ARM64 and Intel) on GitHub Releases. Users download, extract, point `AZ_PYTHON` to any compatible Python, and run `az` — no package manager required.
>
> **Broker authentication on macOS.** We're shipping SSO through Company Portal (MSAL broker) on macOS for the first time — the same seamless Entra ID authentication that Windows users already have. When Company Portal is present, `az login` goes through the broker instead of the browser.
>
> These are three of the biggest changes to Azure CLI on macOS in years. We need real machines, real devices, real enrollment states — not just CI matrices. That's what this bug bash is for.

**Key points to hit:**

- Two new installation methods: Homebrew Cask and Offline Tarball
- Broker auth via Company Portal (macOS SSO, seamless with Entra ID)
- Real hardware testing — ARM64 (Apple Silicon) and Intel x86_64
- Ring Zero service deployment validates az works end-to-end against live Azure

---

## SLIDE 3 — What We Want to Get Out of It (1:30–2:45)

**Visual:** Two-column layout — "Validate" on left, "Catch" on right

**Script:**

> We need to validate three things:
>
> **One** — The install lifecycle works cleanly. Formula uninstall → cask install → reinstall → upgrade → uninstall. No orphaned files, no broken symlinks, no config loss.
>
> **Two** — Broker auth works on real enrolled devices. Company Portal present: broker fires. Company Portal absent or disabled: falls back to browser. No crashes, no stale tokens.
>
> **Three** — Telemetry captures the right fields. Installer shows `HOMEBREW_CASK`, not `HOMEBREW`. MSAL broker telemetry flows with `MsalVersion`, `MsalRuntimeVersion`, and `broker_app_used` populated.

**What we're trying to catch:**

- macOS quarantine (`com.apple.quarantine`) blocking extracted binaries
- Codesigning failures on `.so` / `.dylib` native extensions
- Python path mismatches (Homebrew Python vs. system Python vs. python.org Python)
- Broker dialog not appearing when expected (or appearing when not expected)
- Telemetry fields missing or wrong after the packaging change
- `az upgrade` or `brew upgrade` breaking the cask install
- Config or extensions lost across install/uninstall transitions

---

## SLIDE 4 — The Six Phases at a Glance (2:45–4:30)

**Visual:** Phase flow diagram (refer to `resources/bugbash-overview.excalidraw`)

**Script:**

> The bug bash is organized into 6 phases. You open Copilot Chat, select the phases you want, and Copilot guides you through each step — seeking your approval to proceed, running commands, capturing output, and logging results automatically.

### Phase 1 — Existing State

> Establish the baseline. Record the current state of azure-cli installation on macOS, what's currently on the machine — Python runtimes, the existing homebrew-core Azure CLI, its extensins — verify it works, then cleanly uninstall so we start fresh.

### Phase 2 — Cask Install

> Test the new Homebrew Cask installation end-to-end. Install, verify binaries are properly signed, login, test extensions and upgrades, reinstall, then fully remove.

### Phase 3 — Offline Install

> Test the tarball distribution for environments without Homebrew. Download the archive, verify security attributes, install a standalone Python, and run the CLI entirely outside of any package manager.

### Phase 4 — Ring Zero

> Installation and packaging can look fine locally — but if commands fail against real Azure endpoints, none of it matters. Deploy 8 foundational Azure services as an interconnected architecture, verify each one, then clean up.

### Phase 5 — Broker Authentication

> Test the new azure cli macOS login experience via MSAL & Company Portal. Verify broker-based login, disable it and confirm browser fallback, re-enable and confirm it fires again. This is the core broker based authentication flow that will be available to all macOS users soon.

### Phase 6 — Telemetry Verification

> And finally, observability aspects. Confirm that telemetry correctly reflects the new installation methods and broker usage. Verify the right attributes flow through to the telemetry backend via KQL.

---

## SLIDE 5 — Why Two Taps? (4:30–5:15)

**Visual:** Diagram showing `Azure/homebrew-azure-cli` → Phases 1–4 and `naga-nandyala/homebrew-mycli-app` → Phases 5–6

**Script:**

> You'll notice we use two different Homebrew taps. Phases 1 through 4 use the official `Azure/homebrew-azure-cli` tap — this is the baseline release **without** the broker change. Phases 5 and 6 switch to `naga-nandyala/homebrew-mycli-app` — a second release build **with** the broker enabled.
>
> This mirrors our actual staged rollout plan: ship the cask packaging first, validate it, then enable broker in a follow-up. The bug bash tests both builds.

---

## SLIDE 6 — How It Works: Copilot Chat Automation (5:15–6:30)

**Visual:** Screen recording or screenshot of Copilot Chat running the bug bash

**Script:**

> Here's the cool part: you don't read a wiki and type commands. You open the repo in VS Code, open Copilot Chat, and type `/bugbash`. Copilot reads the phase files and executes each step for you, one at a time.
>
> Each step has a type tag:
> - **Auto** (blue) — runs immediately, no input needed
> - **Interactive** (orange) — warns you, runs the command, asks you to confirm what you observed
> - **Destructive** (red) — asks "Proceed yes/no?" before running anything that deletes files
> - **Manual** (orange) — shows you the command, you run it yourself and paste the result
>
> Every step's output is captured to a markdown file with timestamp and pass/fail assessment. At the end, Copilot generates a per-phase summary and an overall summary across all phases — even if you ran phases in separate sessions.

**Getting started in 60 seconds:**

> 1. Clone the repo, open in VS Code
> 2. Copy `.env.template` to `.env`, fill in your tenant ID and subscription
> 3. Open Copilot Chat, type `/bugbash`
> 4. Pick your phases and go

---

## SLIDE 7 — What Participants Will Learn (6:30–7:30)

**Visual:** Learning outcomes list

**For participants running the bug bash:**

- **Homebrew internals**: How taps, formulas, and casks work — and the differences between them. You'll see `brew tap`, `brew install --cask`, `brew --prefix`, `Caskroom`, and package lifecycle commands in action.
- **macOS security**: How `com.apple.quarantine` extended attributes work, how `codesign` verification works on native binaries, and why you can't codesign shell scripts.
- **Python packaging on macOS**: The difference between Homebrew Python, python.org framework installs, Xcode CLT Python, and pyenv — and how `AZ_PYTHON` lets you decouple the CLI from its Python runtime.
- **Broker / SSO authentication**: How macOS broker auth works through Company Portal, the `enable_broker_on_mac` config flag, and how MSAL Runtime provides SSO across Azure tools.
- **Copilot Chat as a test harness**: How prompt files can drive automated, step-by-step testing with output capture, pass/fail assessment, and summary generation.

---

## SLIDE 8 — What the Non-Participating Audience Will Learn (7:30–8:30)

**Visual:** Audience takeaways

**For people watching but not running the bug bash:**

- **Release process visibility**: See exactly how a macOS Homebrew Cask release is validated before it ships. Every step, every check, every edge case — transparent and reproducible.
- **Packaging evolution**: Understand why we're moving from formula to cask — eliminating `pip install` build failures, shipping pre-built universal binaries, controlling the Python dependency, enabling codesigning.
- **Broker auth rollout strategy**: See the dual-tap staged rollout approach — validate packaging first, then layer in broker — and understand the Company Portal dependency and fallback behavior.
- **Prompt-driven testing pattern**: See how a Copilot Chat prompt file can orchestrate a 39-step, 6-phase test suite — with execution modes, output capture, summaries, and cross-session continuity. This pattern applies to any CLI testing, not just Azure CLI.
- **Telemetry validation methodology**: How CorrelationIds are captured at login time and later verified via KQL queries to confirm the telemetry pipeline works end-to-end.
- **macOS platform specifics**: Quarantine attributes, Gatekeeper, codesigning, `pkgutil`, framework installs — concepts that apply to any macOS software distribution.

---

## SLIDE 9 — Call to Action (8:30–9:00)

**Visual:** Repo link, Getting Started steps

**Script:**

> If you have a Mac — ARM or Intel — we want you in. Clone the repo, set up your `.env`, open Copilot Chat, and pick a phase. Even running just Phase 2 (cask install) or Phase 5 (broker auth) is immensely valuable.
>
> If you don't have a Mac, watch the results summaries that come back. The telemetry data from Phase 6 will be especially interesting for anyone working on the auth or instrumentation side.
>
> Repo: `github.com/naga-nandyala/bugbash-azcli`
>
> Questions? Reach out in the team channel.

---

## SLIDE 10 — Quick Reference (9:00–end)

**Visual:** Summary table on screen

| Phase | Name | Steps | What it Tests |
|-------|------|-------|---------------|
| 1 | Existing State | 7 | Baseline capture, Python discovery, formula uninstall |
| 2 | Cask Install | 11 | Full cask lifecycle, codesigning, extensions, upgrade |
| 3 | Offline Install | 9 | Tarball, quarantine, non-Homebrew Python, air-gapped scenario |
| 4 | Ring Zero | 1 | 8 Azure services deployed and verified end-to-end |
| 5 | Broker Auth | 6 | SSO via Company Portal, enable/disable/fallback |
| 6 | Telemetry | 5 | CorrelationIds, installer field, MSAL KQL verification |
| | **Total** | **39** | |
