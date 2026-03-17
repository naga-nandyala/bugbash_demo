# Azure CLI Bug Bash — Teaser Video Plan

**Target Duration:** 2:00 – 2:30 minutes  
**Tool:** Clipchamp (layer recorded clips, screenshots, and audio on the timeline)  
**Resolution:** 1920×1080  
**Music:** Clipchamp stock music or royalty-free upbeat tech track, ducked under VO

---

## Step 1 — Record Clips & Capture Screenshots

Record each clip with `Cmd+Shift+5` (macOS screen recording). Keep raw clips — you'll trim in Clipchamp.

### Video Clips to Record

| Clip | What to Capture | How |
|------|----------------|-----|
| **C1** | Terminal: `az --version` output (current homebrew-core install) | Screen record, dark terminal theme, large font |
| **C2** | Terminal: `brew tap Azure/azure-cli` then `brew install --cask azure-cli` | Record full install, you'll speed it up in Clipchamp |
| **C3** | Terminal: `codesign` output showing PASS lines with Microsoft TeamIdentifier | Screen record the verification script running |
| **C4** | Terminal: `curl` downloading tarball + `tar -xzf` extracting | Screen record, speed up in Clipchamp |
| **C5** | Terminal: `xattr -l` showing quarantine attributes on extracted files | Short clip |
| **C6** | Terminal: `integrated_test.sh` deploying Ring Zero resources | Record the deploy phase, speed up in Clipchamp |
| **C7** | Azure Portal: Resource group showing all 8 Ring Zero services | Screen record scrolling the resource list |
| **C8** | Azure Portal: Resource Visualizer showing service connections | Screen record the graph view |
| **C9** | macOS broker/SSO dialog appearing (Company Portal login) | Screen record the native dialog — blur any credentials in Clipchamp |
| **C10** | Terminal: `az config set core.enable_broker_on_mac=false` → browser login → `=true` → broker returns | Record the toggle cycle |
| **C11** | Terminal: `--debug` output with CorrelationId visible | Short clip, position terminal so the ID is prominent |
| **C12** | Browser/VS Code: Repo README scrolling the phase table | Screen record a quick scroll-through |

### Screenshots to Capture

| Screenshot | What | How |
|------------|------|-----|
| **S1** | `az --version` output (clean, full screen) | `Cmd+Shift+4` |
| **S2** | `codesign` PASS output (zoomed to the PASS lines) | Crop in Preview or Clipchamp |
| **S3** | Azure Portal — Resource Visualizer with connection lines | Full browser screenshot |
| **S4** | macOS broker dialog (Company Portal SSO prompt) | `Cmd+Shift+4` |
| **S5** | Ring Zero resource group overview in Azure Portal | Full browser screenshot |
| **S6** | KQL query results showing telemetry fields | Screenshot from your telemetry dashboard |

> **Tip:** You can use screenshots as still frames in Clipchamp to hold on screen while the VO describes what's happening — especially useful for Phase 4 (Ring Zero architecture) and Phase 6 (KQL results).

---

## Step 2 — Record Audio

Record the voiceover separately. Use Voice Memos or GarageBand, then import the `.m4a` into Clipchamp.

### Voiceover Script

> Azure CLI 2.84.0. New Homebrew Cask distribution. macOS broker authentication. And 39 steps to try to break it all.
>
> Azure CLI on macOS is moving from a Homebrew formula to a Homebrew Cask. That's a completely new packaging model — new install paths, new code-signed binaries, new offline tarball distribution. And on top of that, we're shipping macOS broker authentication — single sign-on through Company Portal, no browser needed.
>
> New packaging plus new auth means we need to test everything before it ships.
>
> The bug bash covers six phases — thirty-nine steps total.
>
> Phase 1 — snapshot your current Homebrew-core install, then cleanly remove the old formula.
> Phase 2 — tap the new Azure CLI cask, install it, verify every native binary is code-signed by Microsoft, and test the full Homebrew lifecycle.
> Phase 3 — download the release tarball directly, verify macOS quarantine attributes, check code signatures, and run az with a standalone Python.
> Phase 4 — the real-world capstone. Deploy all eight Ring Zero services as a connected architecture in your own Azure subscription — Entra ID, ARM, DNS, Networking, Storage, Compute, Key Vault, Monitor — then clean up.
> Phase 5 — the headline feature. Login via the macOS broker through Company Portal. Disable it, fall back to browser. Re-enable it, broker comes back.
> Phase 6 — confirm telemetry. Capture correlation IDs, verify the installer field shows HOMEBREW_CASK, and check MSAL version fields via KQL.
>
> What you'll need: A Mac. Homebrew. Your current Azure CLI install. A VS Enterprise subscription. And Company Portal for broker tests.
>
> Six phases. Thirty-nine steps. Find the bugs before our customers do.

---

## Step 3 — Assemble in Clipchamp

### Timeline Layout

Drop the VO audio on **Track 1** (the timeline ruler). Then layer clips/screenshots on **Track 2** (video), trimmed to match each VO section. Add text overlays on **Track 3**.

| VO Section | Timestamp | Clip/Screenshot on Screen | Text Overlay |
|------------|-----------|--------------------------|--------------|
| "Azure CLI 2.84.0..." (hook) | 0:00 – 0:10 | **C1** (`az --version`) then quick cut to **C2** (brew install starting) | **"Bug Bash — Azure CLI 2.84.0 macOS"** |
| "Moving from formula to cask..." | 0:10 – 0:25 | **C2** (brew install running, speed up 4×) | **"Formula → Cask"** |
| "Broker auth... Company Portal..." | 0:25 – 0:33 | **S4** (broker dialog screenshot) | **"macOS Broker Auth via Company Portal"** |
| "New packaging + new auth..." | 0:33 – 0:38 | Hold on **S4** or fade to black | **"New packaging + New auth = Test everything"** |
| "Six phases, thirty-nine steps" | 0:38 – 0:45 | **S5** (resource group overview) or create a simple slide with 6 phase names | **"6 Phases · 39 Steps"** |
| Phase 1 — Existing State | 0:45 – 0:55 | **C1** (`az --version`, `brew info`) | **"Phase 1 — Existing State"** |
| Phase 2 — Cask Install | 0:55 – 1:08 | **C2** (install) → **C3** (codesign) or **S2** | **"Phase 2 — Cask Install"** |
| Phase 3 — Offline Tarball | 1:08 – 1:20 | **C4** (curl + extract) → **C5** (quarantine check) | **"Phase 3 — Offline Tarball"** |
| Phase 4 — Ring Zero | 1:20 – 1:35 | **C6** (deploy) → **C7** or **C8** (portal views) or **S3** / **S5** | **"Phase 4 — Ring Zero"** |
| Phase 5 — Broker Auth | 1:35 – 1:45 | **C9** (broker dialog) → **C10** (toggle cycle) | **"Phase 5 — Broker Auth"** |
| Phase 6 — Telemetry | 1:45 – 1:55 | **C11** (debug output) → **S6** (KQL results) | **"Phase 6 — Telemetry"** |
| "What you'll need..." | 1:55 – 2:08 | Simple slide or **C12** (README scroll) | Bullet list appearing: Mac, Homebrew, Azure sub, Company Portal |
| "Six phases... find the bugs" | 2:08 – 2:20 | Quick montage: flash **C1→C3→C6→C9** (1s each) then final card | **"Find the bugs before our customers do."** |

### Clipchamp Tips

- **Speed up** long clips (C2 brew install, C4 curl, C6 deploy): right-click clip → Speed → 4× or 8×
- **Text overlays**: Use Clipchamp's "Text" panel → pick a clean style → position bottom-center or top-left
- **Transitions**: Use simple cross-dissolve (0.3s) between clips, not fancy effects
- **Background music**: Clipchamp has free stock music — search "tech" or "corporate" → drag to a track below VO → lower volume to ~20%
- **Blur credentials**: Use Clipchamp's "Blur" filter on clips C9/C10 if credentials are visible
- **Export**: 1080p, auto quality

---

## File Naming Convention

Save your raw assets in `_video/assets/`:

```
_video/
├── teaser-video-plan.md          ← this file
├── bugbash_demo.txt              ← demo video script (done)
├── bugbash_teaser_vo.m4a         ← recorded voiceover
└── assets/
    ├── clips/
    │   ├── C01-az-version.mov
    │   ├── C02-brew-install-cask.mov
    │   ├── C03-codesign.mov
    │   ├── C04-tarball-download.mov
    │   ├── C05-quarantine-check.mov
    │   ├── C06-ringzero-deploy.mov
    │   ├── C07-portal-rg-view.mov
    │   ├── C08-portal-visualizer.mov
    │   ├── C09-broker-dialog.mov
    │   ├── C10-broker-toggle.mov
    │   ├── C11-debug-correlationid.mov
    │   └── C12-readme-scroll.mov
    └── screenshots/
        ├── S01-az-version.png
        ├── S02-codesign-pass.png
        ├── S03-resource-visualizer.png
        ├── S04-broker-dialog.png
        ├── S05-rg-overview.png
        └── S06-kql-results.png
```

---

## Checklist

- [ ] Record all 12 video clips (C1–C12)
- [ ] Capture all 6 screenshots (S1–S6)
- [ ] Record voiceover audio
- [ ] Import everything into Clipchamp
- [ ] Lay VO on Track 1, clips on Track 2, text on Track 3
- [ ] Speed up long clips (C2, C4, C6)
- [ ] Add text overlays for phase names and key messages
- [ ] Add background music (low volume under VO)
- [ ] Blur any credentials in broker clips
- [ ] Export 1080p
- [ ] Review and trim to ~2:00–2:20
