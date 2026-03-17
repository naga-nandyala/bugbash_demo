# Recording Plan — Shot List

Voiceover: `3_fina.txt` (3 sections: overview, phases, outro)

---

## Section 1 — Overview (voiceover lines 1–16)

Record these clips to play under the overview narration:

| # | Clip | What to show | Duration hint |
|---|------|-------------|---------------|
| 1a | **Title card** | Static slide: "Azure CLI v2.84.0 — macOS Install & Broker Auth Bug Bash" | ~5s |
| 1b | **Homebrew Cask intro** | Terminal: `brew info azure-cli` showing the cask metadata (or the cask Ruby file in VS Code) | ~15s |
| 1c | **Tarball intro** | GitHub Releases page showing the ARM64 + Intel tarball assets | ~10s |
| 1d | **Broker intro** | `az login` launching Company Portal broker dialog (or screenshot of SSO prompt) | ~10s |
| 1e | **Transition** | Slow zoom into the Excalidraw overview image (full 6-phase grid) — hold until phases section starts | ~10s |

**Recording tips — Section 1:**
- 1b: Run `brew tap azure/azure-cli` then `brew info --cask azure-cli` in a clean terminal
- 1c: Open `https://github.com/Azure/azure-cli/releases` in browser, scroll to assets
- 1d: If you can capture the actual broker popup, great; otherwise a screenshot overlay works

---

## Section 2 — Phases (voiceover lines 18–32)

Start with the **full Excalidraw overview** on screen, then zoom/highlight each phase box as its narration begins. Between phases, cut to a Copilot Chat screen recording showing 1–2 representative steps.

### Phase 1 — Existing State

| # | Clip | What to show |
|---|------|-------------|
| 2a | **Overview zoom** | Highlight/zoom Phase 1 box in Excalidraw |
| 2b | **Copilot running Step 1** | Copilot Chat discovering Python installs (`which -a python3`, framework check) |
| 2c | **Copilot running Step 3** | Copilot capturing extensions list (`az extension list`) |

### Phase 2 — Cask Install

| # | Clip | What to show |
|---|------|-------------|
| 2d | **Overview zoom** | Highlight/zoom Phase 2 box in Excalidraw |
| 2e | **Copilot running Step 3** | `brew install --cask azure-cli` output scrolling in terminal |
| 2f | **Copilot running Step 4** | `codesign --verify` on the az binary — showing "valid on disk" |

### Phase 3 — Offline Install

| # | Clip | What to show |
|---|------|-------------|
| 2g | **Overview zoom** | Highlight/zoom Phase 3 box in Excalidraw |
| 2h | **Copilot running Step 1** | `curl` downloading the tarball, progress bar visible |
| 2i | **Copilot running Step 2** | `xattr -p com.apple.quarantine` showing quarantine attribute on tarball |
| 2j | **Copilot running Step 6** | Python 3.13 install dialog or `sudo installer -pkg` output |

### Phase 4 — Ring Zero

| # | Clip | What to show |
|---|------|-------------|
| 2k | **Overview zoom** | Highlight/zoom Phase 4 box in Excalidraw |
| 2l | **Copilot running the step** | Copilot deploying resources — `az group create`, `az monitor log-analytics workspace create`, etc. — or the Azure Portal showing the resource group with 8 resources |

### Phase 5 — Broker Authentication

| # | Clip | What to show |
|---|------|-------------|
| 2m | **Overview zoom** | Highlight/zoom Phase 5 box in Excalidraw |
| 2n | **Copilot running Step 2** | `az login` triggering broker — Company Portal SSO popup appearing |
| 2o | **Copilot running Step 3** | `az config set core.enable_broker_on_mac=false` then `az login` opening browser instead |

### Phase 6 — Telemetry Verification

| # | Clip | What to show |
|---|------|-------------|
| 2p | **Overview zoom** | Highlight/zoom Phase 6 box in Excalidraw |
| 2q | **Copilot running Step 4** | KQL query in Log Analytics or Application Insights showing `installer = HOMEBREW_CASK` |
| 2r | **Copilot running Step 5** | KQL results showing MSAL broker fields populated |

**Recording tips — Section 2:**
- For each phase, the Copilot clip only needs ~15–20s of footage — enough to show Copilot asking "proceed?", running a command, and printing a result
- You don't need to record every step — pick 1–2 visually interesting ones per phase
- The Excalidraw zoom transitions can be done in editing (pan/crop on the static image)
- Record the Copilot clips with the VS Code sidebar open so `Copilot Chat` panel is visible

---

## Section 3 — Outro (voiceover lines 34–36)

| # | Clip | What to show |
|---|------|-------------|
| 3a | **Repo page** | Browser showing `github.com/naga-nandyala/bugbash-azcli` README |
| 3b | **End card** | Static slide: repo URL, team channel, "Questions? Reach out" |

---

## Checklist — Clips to Record

Before recording, prep a machine with:
- [x] Excalidraw overview open in VS Code (for zoom/pan captures or static export)
- [ ] Clean terminal (dark theme, large font ~16pt)
- [ ] VS Code with Copilot Chat panel open
- [ ] `.env` configured with tenant + subscription

Capture in order (group by tool to minimize context-switching):

**Terminal / Copilot recordings (screen record VS Code):**
1. [ ] Phase 1: Python discovery + extension list
2. [ ] Phase 2: `brew install --cask` + `codesign --verify`
3. [ ] Phase 3: Tarball download + quarantine check + Python install
4. [ ] Phase 4: Ring Zero deployment (or Azure Portal screenshot)
5. [ ] Phase 5: Broker login popup + browser fallback
6. [ ] Phase 6: KQL query + results

**Browser recordings:**
7. [ ] GitHub Releases page with tarball assets
8. [ ] Repo README page (outro)

**Static assets (screenshot or export):**
9. [ ] Title card
10. [ ] Excalidraw overview (export as PNG for zoom/pan in editor)
11. [ ] End card

---

## Editing Notes

- Total clips: ~15 (6 phase zooms + 2–3 Copilot clips per active phase + bookend cards)
- Each Copilot clip: 15–20s of the most visually interesting moment
- Excalidraw phase highlights: can be done with a single pan/zoom on the exported PNG — no need to re-record 6 separate clips if your editor supports keyframe animation
- The voiceover is ~2min for overview, ~1.5min for phases, ~15s for outro — roughly 4 minutes total, so clips can be trimmed to match
