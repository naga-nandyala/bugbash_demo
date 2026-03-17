# Bug Report: macOS Broker Auth Fails After Config Toggle (false → true)

## Summary

Two related bugs discovered when toggling `core.enable_broker_on_mac` between `false` and `true`:

1. **Bug 1 (Broker):** After toggling from `false` back to `true`, `az login` (multi-tenant) fails with an MSAL token cache error. The broker dialog appears and the user selects an account, but the token is never written back to the MSAL file cache. Clearing caches does NOT fix this — the broker flow itself is broken. **Broker-first login from a clean install (no prior browser login) works perfectly**, confirming the root cause is browser-stored tokens in the MSAL cache interfering with the broker codepath.
2. **Bug 2 (Browser fallback):** After the broker toggle corrupts state, switching back to `broker=false` and using browser auth (`az login`) also fails with the same MSAL cache error — **unless** the cache files are deleted **before** running `az login`.

Additionally: removing Company Portal while broker is enabled does NOT trigger graceful browser fallback — it fails with `Status_TransientError, Error code: 1000`.

**`az login --tenant <id>` works correctly with broker** — the bug is isolated to the multi-tenant enumeration path.

## Environment

| Field | Value |
|-------|-------|
| **Azure CLI Version** | 2.84.0 |
| **OS** | macOS (arm64) |
| **Hostname** | Nagas-MacBook-Pro.local |
| **Company Portal Version** | 5.2602.0 |
| **Cask Source** | naga-nandyala/homebrew-mycli-app |
| **Date** | 2026-03-17 |

## Steps to Reproduce

### Confirmed minimal reproduction (from completely clean state):

1. Delete `~/.azure` entirely:
   ```bash
   rm -rf ~/.azure
   ```

2. Disable broker and login via browser:
   ```bash
   az config set core.enable_broker_on_mac=false
   az login
   # ✅ Browser opens, login succeeds
   ```

3. Logout, re-enable broker, and attempt login:
   ```bash
   az logout
   az config set core.enable_broker_on_mac=true
   az login
   # ❌ FAILS — broker dialog appears, account selected, but token cache error
   ```

**This reproduces 100% of the time**, even with:
- Completely clean `~/.azure` (freshly deleted)
- Device compliant in Company Portal
- Company Portal SSO extension registered and functional

### Clean install reproduction (confirmed 2026-03-17 ~20:25):

1. Full clean: uninstall cask + delete `~/.azure`:
   ```bash
   brew uninstall --cask azure-cli   # also auto-removes mpdecimal, python@3.13
   rm -rf ~/.azure
   ```

2. Reinstall cask (without `--no-quarantine`):
   ```bash
   brew install --cask azure-cli     # 2.84.0 installed
   ```

3. First login — broker (default=true), no config set:
   ```bash
   az login
   # ✅ Broker dialog appears, selects account, enumerates all tenants/subscriptions — WORKS
   ```

4. Toggle broker off, browser login:
   ```bash
   az logout
   az config set core.enable_broker_on_mac=false
   az login
   # ✅ Browser opens, login succeeds, enumerates tenants — WORKS
   ```

5. Toggle broker back on, attempt login:
   ```bash
   az logout
   az config set core.enable_broker_on_mac=true
   az login
   # ❌ Broker dialog appears, account selected, then:
   #    "User 'naganandyala@microsoft.com' does not exist in MSAL token cache. Run `az login`."
   ```

6. Single-tenant workaround still works:
   ```bash
   az login --tenant ed94de55-1f87-4278-9651-525e7ba467d6
   # ✅ Broker dialog, login succeeds for azclitools tenant
   ```

### Original reproduction (also works):

1. Start with broker enabled (default on macOS):
   ```bash
   az config get core.enable_broker_on_mac
   # not set (defaults to true on macOS)
   ```

2. Login successfully via broker:
   ```bash
   az login
   # ✅ Broker dialog appears, login succeeds
   ```

3. Disable broker and login via browser:
   ```bash
   az logout
   az config set core.enable_broker_on_mac=false
   az login
   # ✅ Browser opens, login succeeds
   ```

4. Re-enable broker and attempt login:
   ```bash
   az logout
   az config set core.enable_broker_on_mac=true
   az login
   # ❌ FAILS — broker dialog appears, account selected, but token cache error
   ```

## Error Message

```
Select the account you want to log in with. For more information on login with Azure CLI, see https://go.microsoft.com/fwlink/?linkid=2271136
Retrieving tenants and subscriptions for the selection...
User 'naganandyala@microsoft.com' does not exist in MSAL token cache. Run `az login`.
```

Exit code: 1

## Behavior

| Scenario | Result |
|----------|--------|
| Fresh install (no prior login) → broker default → `az login` | ✅ Works (confirmed) |
| Broker default (not set) → `az login` | ✅ Works |
| Broker `true` → `az login` | ✅ Works |
| Broker `false` → `az login` (browser) | ✅ Works |
| Broker `false` → `true` → `az login` | ❌ **FAILS** (Bug 1) |
| Broker `false` → `true` → `az login --tenant <id>` | ✅ Works |
| Broker `false` → `true` → `false` → `az login` (stale cache) | ❌ **FAILS** (Bug 2) |
| Broker `false` → `true` → `false` + clear cache → `az login` | ✅ Works (workaround) |
| Broker `false` → `true` → clear keychain only → `az login` | ❌ **FAILS** |
| Broker `false` → `true` → clear MSAL cache only → `az login` | ❌ **FAILS** |
| Broker `false` → `true` → clear keychain + MSAL cache → `az login` | ✅ **WORKS** (fix) |
| Company Portal removed + broker `true` → `az login` | ❌ **FAILS** (no browser fallback) |

## Remediation Attempts

### Bug 1: broker=true after toggle (All Failed)

| Action | Result |
|--------|--------|
| `az account clear` | Same error |
| Delete `~/.azure/msal_token_cache.json` | Same error |
| Delete `~/.azure/msal_http_cache.bin` | Same error |
| Delete `~/.azure/azureProfile.json` | Same error |
| Delete entire `~/.azure/` directory | Same error |
| `az config unset core.enable_broker_on_mac` (back to default) | Same error |
| Multiple retries of `az login` | Same error every time |

| Clear MSAL cache + `az account clear` (broker=true retained) | Same error |
| `rm -f msal_token_cache.json msal_http_cache.bin` + `az account clear` → `az login` | Same error |
| Clear keychain entries only (Microsoft identity) → `az login` | Same error |
| **Clear keychain entries + MSAL cache + `az account clear`** → `az login` | ✅ **WORKS** |

### Controlled isolation test (clean install 2026-03-17 ~20:55):

| Step | Action | Keychain | MSAL Cache | Result |
|------|--------|----------|------------|--------|
| 1 | Fresh install, clean keychain | clean | clean | (ready) |
| 2 | Broker login (default=true) | → 2 entries | → 33KB/44KB | ✅ WORKS |
| 3 | Toggle false → browser login | 2 entries | 34KB/57KB | ✅ WORKS |
| 4 | Toggle true → `az login` | 2 entries | dirty | ❌ **FAILS** (bug reproduced) |
| 4b | `az login --tenant <id>` | 2 entries | dirty | ✅ WORKS (single-tenant ok) |
| 5 | Clear MSAL cache+bin only | 2 entries (dirty) | clean | ❌ **FAILS** |
| 6 | Clear keychain + MSAL cache | clean | clean | ✅ **WORKS** |

**Root cause confirmed: The corrupted state spans BOTH the macOS keychain AND the MSAL file cache.** Both must be cleared together. Clearing only one or the other is insufficient.

### Bug 2: browser fallback with corrupted cache

| Action | Result |
|--------|--------|
| Set `broker=false` → `az login` (without clearing cache) | ❌ Same MSAL cache error |
| Set `broker=false` + delete MSAL cache files **before** `az login` | ✅ **Works** |

**Workaround exists:** clear cache files, then use browser auth.

## Analysis

### Bug 1 — Broker multi-tenant login broken after toggle
- The broker dialog **does appear** and the user **can select an account** — so the broker SSO extension (Company Portal) is functioning.
- The failure occurs in the **post-authentication step** where the CLI tries to enumerate tenants and subscriptions using the broker-acquired token.
- The error `User does not exist in MSAL token cache` suggests the broker acquires a token but does not persist it to the MSAL file cache (`msal_token_cache.json`), or the CLI reads from the file cache instead of the broker's in-memory/keychain token store.
- **`az login --tenant <id>` succeeds**, indicating the bug is in the multi-tenant discovery code path, not in the broker token acquisition itself. When a specific tenant is provided, the CLI skips multi-tenant enumeration and the single-tenant broker flow works.
- **Reproduced from completely clean state:** Deleting `~/.azure` entirely, starting with `broker=false` (browser login succeeds), then toggling to `broker=true` triggers the same error.
- **Clean install confirmation:** A completely fresh install (`brew uninstall --cask azure-cli`, `rm -rf ~/.azure`, `brew install --cask azure-cli`) with NO intermediate browser login → `az login` via broker works perfectly. This conclusively proves the root cause: **browser-stored MSAL tokens poison the broker's multi-tenant enumeration**.
- **ROOT CAUSE — Both keychain AND MSAL file cache:** Controlled isolation testing (clean install, 2026-03-17 ~20:55) confirmed:
  - Clearing MSAL cache only (keychain dirty) → still **FAILS**
  - Clearing keychain only (MSAL cache dirty) → still **FAILS** (confirmed in prior test)
  - Clearing BOTH keychain + MSAL cache → **WORKS**
  - The corrupted state spans both storage layers. Browser-based login stores tokens in a format incompatible with the broker's multi-tenant enumeration in both the keychain (`com.microsoft.identity.universalstorage`) and the MSAL file cache (`msal_token_cache.json`).
- **Keychain state tracking during reproduction:**
  - After broker login: 2 entries (`org.python.python.com.microsoft.identity.universalstorage[-org.python.python]`)
  - After browser login: same 2 entries (no additional entry in this run, unlike earlier)
  - After failed broker login: keychain re-creates the `org.python.python...` entries
  - Clearing only one storage layer leaves inconsistent state that still breaks multi-tenant enumeration.

### Bug 2 — Browser auth fails with corrupted cache
- After the broker toggle corrupts the MSAL cache state, switching to `broker=false` and using browser auth also fails — the browser opens, login succeeds in the browser, but the CLI cannot write the token back to the corrupted cache.
- **Clearing the cache files BEFORE running `az login` fixes this.** The sequence that works:
  ```bash
  rm -rf ~/.azure/msal_token_cache.json ~/.azure/msal_http_cache.bin ~/.azure/azureProfile.json
  az account clear
  az config set core.enable_broker_on_mac=false
  az login   # ✅ works
  ```
- This means the broker toggle leaves behind a corrupted cache state that poisons subsequent login attempts (both broker and browser) until the cache files are manually deleted.

### No browser fallback without Company Portal
- When Company Portal is removed and broker config is `true`, `az login` does NOT fall back to browser. Instead it fails with: `Status_TransientError, Error code: 1000, Tag: 508175367`
- The error message unhelpfully suggests re-running `az login`, which produces the same error in a loop.

### ⛔ CRITICAL: Removing Company Portal de-registers the device from Intune
- After removing Company Portal (`sudo rm -rf /Applications/Company\ Portal.app`) and reinstalling from the Mac App Store, the device shows **"This device is not registered"** in Company Portal with status: "There was an issue registering your device."
- This means reinstalling Company Portal does NOT automatically re-register the device with Intune.
- With the device non-compliant, **all broker-based authentication fails permanently** — even from a completely clean `~/.azure` directory, even with broker config at default.
- Browser-based auth to the Microsoft tenant also fails due to Conditional Access policies requiring device compliance.
- **Step 5 should NEVER be run on a real user machine.** It should only be tested on a dedicated VM that can be easily re-enrolled. The phase file has been updated to mark Step 5 as `[manual]` with a ⛔ BLOCKED warning.

## Workaround

### For broker=true (Bug 1)

**Option A (recommended — full fix):** Clear keychain + MSAL cache, then login:
```bash
# Delete Python/CLI Microsoft identity keychain entries
security delete-generic-password -a "org.python.python.com.microsoft.identity.universalstorage-org.python.python" login.keychain-db 2>/dev/null
security delete-generic-password -a "org.python.python.com.microsoft.identity.universalstorage" login.keychain-db 2>/dev/null

# Clear MSAL file cache
rm -f ~/.azure/msal_token_cache.json ~/.azure/msal_http_cache.bin
az account clear

# Login (should now work)
az login
```

**Option B (simple):** Use `az login --tenant <tenant_id>` instead of `az login`:
```bash
az login --tenant <your-tenant-id>
```

### For browser fallback (Bug 2)
Clear the cache files first, then disable broker and login:
```bash
rm -rf ~/.azure/msal_token_cache.json ~/.azure/msal_http_cache.bin ~/.azure/azureProfile.json
az account clear
az config set core.enable_broker_on_mac=false
az login
```

## Impact

- Users who toggle broker auth off and back on (e.g., for troubleshooting) will be unable to use `az login` for multi-tenant login. They must specify `--tenant` explicitly.
- If users switch back to browser auth (`broker=false`) after the toggle, login will also fail unless they manually clear the MSAL cache files first — a non-obvious recovery step.
- Removing Company Portal while broker is enabled provides no graceful degradation to browser auth.
