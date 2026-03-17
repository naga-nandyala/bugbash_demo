# Azure CLI on macOS — Installation & Authentication Bug Bash

## Overview

Significant changes are coming to **Azure CLI on macOS** — introducing new installation models and a major authentication upgrade.

### 🚀 What's New

**1. Homebrew Cask Installation (New Default)**

Azure CLI is moving from the legacy Homebrew *formula* to a **Homebrew Cask**.
This delivers a **self‑contained, pre‑built bundle with native binaries**, designed to improve reliability, security, and upgrade consistency across macOS systems.

**2. Offline, Architecture‑Specific Installs**

For air‑gapped or restricted environments, we're introducing **offline tarball distributions**:

- Separate builds for **ARM64** and **Intel**
- Download directly from GitHub
- Extract and run without Homebrew
- Point to any compatible Python runtime

This makes Azure CLI usable in environments where package managers are unavailable or locked down.

**3. Broker‑Based Authentication on macOS**

We're bringing **brokered authentication** to macOS using **Company Portal SSO** — equivalent to the Windows experience.

- If Company Portal is installed, Azure CLI uses the broker automatically
- No browser pop‑ups
- Secure, consistent token handling
- Browser fallback remains available where required

---

## Why This Bug Bash Matters

These changes must be validated on **real hardware**, across **real-world developer environments**, using **live Azure resources**.

We need confidence that:

- Every install method works end‑to‑end
- Authentication behaves correctly in all modes
- Azure CLI is production‑ready on macOS for our customers

That's where **you** come in.

---

## Bug Bash Structure

This bug bash is divided into **six guided phases**, orchestrated using **GitHub Copilot**, to ensure coverage across installation, authentication, and real Azure usage.

### Phase 1: Existing State Validation

Before making any changes, we establish a baseline.

**Objectives**

- Document current system state:
  - Installed Python runtimes
  - Existing Azure CLI version
  - Installed extensions
- Validate existing Azure CLI functionality
- Perform a **clean uninstall** to ensure a blank slate

✅ Outcome: We confirm the starting point and eliminate environmental noise.

---

### Phase 2: Homebrew Cask Installation

We validate the new **primary installation path**.

**What to Test**

- End‑to‑end Cask installation
- Code signing and security attributes
- Azure login and account discovery
- Extension installation and usage
- Upgrade and downgrade behavior
- Clean uninstall and reinstall

✅ Outcome: Confidence that the Cask install is secure, repeatable, and user‑friendly.

---

### Phase 3: Offline Installation (Tarball)

We validate environments where Homebrew isn't an option.

**What to Test**

- Download correct tarball (ARM64 vs Intel)
- Inspect security metadata
- Configure standalone or existing Python runtime
- Run Azure CLI without a package manager
- Verify core CLI commands and extensions

✅ Outcome: Azure CLI works reliably in air‑gapped and restricted environments.

---

### Phase 4: Ring Zero Azure Deployments

Installation alone isn't enough — we validate **real usage**.

**What to Deploy**

- Eight core Azure services
- Deployed as an interconnected architecture
- Validate provisioning, configuration, and access
- Perform a full cleanup

✅ Outcome: Azure CLI is proven in real-world, production‑like scenarios.

---

### Phase 5: Broker Authentication Validation

We test the new macOS authentication experience.

**What to Validate**

- Broker login via Company Portal
- Token acquisition and reuse
- Browser fallback behavior
- Ability to toggle authentication paths for comparison
- Error handling and recovery paths

✅ Outcome: Broker authentication is seamless, predictable, and secure.

---

### Phase 6: Telemetry Verification

If we can't observe it, we can't improve it.

**What to Verify**

- Installation telemetry
- Authentication flow signals
- Attribute completeness and correctness
- Events reaching the backend successfully

✅ Outcome: Full visibility into install and auth flows for diagnostics and analysis.

---

## Final Call to Action

**Join the bug bash.**

Test these changes on your daily‑driver hardware.
Push the edges. Break things. Tell us what works — and what doesn't.

Your feedback will directly shape the **next chapter of Azure CLI on macOS**.