# Clean-Room Reproduction: Broker Auth Toggle Bug

**Date:** 2026-03-17 ~20:55–21:01  
**Machine:** Nagas-MacBook-Pro.local (macOS arm64)  
**CLI Version:** 2.84.0 (cask from naga-nandyala/homebrew-mycli-app)

---

## Objective

Full clean-room reproduction of the broker toggle bug, with isolated testing:
1. Clean install from scratch (cask + keychain + ~/.azure all cleared)
2. Document keychain and MSAL cache state at every step
3. Reproduce the bug via toggle (false → true)
4. Confirm single-tenant still works in broken state
5. Test clearing MSAL cache only (keychain dirty)
6. Test clearing both keychain + MSAL cache

---

## Step 1: Full Clean Install

```bash
brew uninstall --cask azure-cli
rm -rf ~/.azure
# Clear all Python/CLI keychain entries
security delete-generic-password -a "org.python.python.com.microsoft.identity.universalstorage-org.python.python" login.keychain-db
security delete-generic-password -a "org.python.python.com.microsoft.identity.universalstorage" login.keychain-db
```

Output:
```
==> Uninstalling Cask azure-cli
==> Unlinking Binary '/opt/homebrew/bin/az'
==> Purging files for version 2.84.0 of Cask azure-cli
==> Autoremoving 2 unneeded formulae:
mpdecimal
python@3.13
Deleted: org.python.python.com.microsoft.identity.universalstorage-org.python.python
Deleted: org.python.python.com.microsoft.identity.universalstorage
```

```bash
brew install --cask azure-cli
```

Output:
```
==> Installing dependencies: mpdecimal, python@3.13
🍺  /opt/homebrew/Cellar/mpdecimal/4.0.1: 22 files, 660.9KB
🍺  /opt/homebrew/Cellar/python@3.13/3.13.12_1: 3,625 files, 72MB
==> Installing Cask azure-cli
==> Linking Binary 'az' to '/opt/homebrew/bin/az'
🍺  azure-cli was successfully installed!
```

**Result:** ✅ CLI 2.84.0 installed

---

## Step 2: Document Before-State (Clean Install, No Login)

```bash
az version 2>&1 | head -2
# { "azure-cli": "2.84.0",

security dump-keychain login.keychain-db | grep '"acct".*microsoft.*identity' | grep -v VSCode | sort -u
# (none)

ls -la ~/.azure/msal_* 2>&1
# zsh: no matches found: /Users/naganandyala/.azure/msal_*

ls ~/.azure/
# az.json  azureProfile.json  commandIndex.json  commands  config  logs  telemetry  versionCheck.json
```

| Storage | State |
|---------|-------|
| CLI | 2.84.0 |
| Keychain (Python/CLI) | 0 entries |
| MSAL token cache | does not exist |
| MSAL http cache | does not exist |

---

## Step 3: First Broker Login (Default broker=true)

```bash
az login 2>&1 | tail -5
```

Output:
```
      "name": "naganandyala@microsoft.com",
      "type": "user"
    }
  }
]
```

**Result:** ✅ Broker dialog appeared, login succeeded, tenants/subscriptions enumerated.

Post-state:
```
Keychain:
    "acct"="org.python.python.com.microsoft.identity.universalstorage-org.python.python"
    "acct"="org.python.python.com.microsoft.identity.universalstorage"

MSAL:
-rw-r--r-- naganandyala staff 44994 Mar 17 20:56 msal_http_cache.bin
-rw------- naganandyala staff 33895 Mar 17 20:56 msal_token_cache.json
```

| Storage | State |
|---------|-------|
| Keychain (Python/CLI) | 2 entries (new) |
| msal_token_cache.json | 33KB (new) |
| msal_http_cache.bin | 44KB (new) |

---

## Step 4: Toggle false → Browser Login

```bash
az logout
az config set core.enable_broker_on_mac=false
az login 2>&1 | tail -5
```

Output:
```
      "name": "naganandyala@microsoft.com",
      "type": "user"
    }
  }
]
```

**Result:** ✅ Browser opened, login succeeded.

Post-state:
```
Keychain:
    "acct"="org.python.python.com.microsoft.identity.universalstorage-org.python.python"
    "acct"="org.python.python.com.microsoft.identity.universalstorage"

MSAL:
-rw-r--r-- naganandyala staff 57913 Mar 17 20:56 msal_http_cache.bin
-rw------- naganandyala staff 34519 Mar 17 20:56 msal_token_cache.json
```

| Storage | Change |
|---------|--------|
| Keychain | same 2 entries (no change) |
| msal_token_cache.json | 33KB → 34KB (+600B — browser tokens added) |
| msal_http_cache.bin | 44KB → 57KB (+12KB — http cache grew) |

---

## Step 5: Toggle true → Reproduce Bug

```bash
az logout
az config set core.enable_broker_on_mac=true
az login 2>&1
```

Output:
```
Select the account you want to log in with. For more information on login with Azure CLI, see https://go.microsoft.com/fwlink/?linkid=2271136
Retrieving tenants and subscriptions for the selection...
User 'naganandyala@microsoft.com' does not exist in MSAL token cache. Run `az login`.
```

**Result:** ❌ FAILS — broker dialog appeared, account selected, but multi-tenant enumeration fails.

---

## Step 5b: Confirm Single-Tenant Still Works

```bash
az login --tenant ed94de55-1f87-4278-9651-525e7ba467d6 2>&1 | tail -10
```

Output:
```
No     Subscription name    Subscription ID                       Tenant
-----  -------------------  ------------------------------------  ------------------------------------
[1] *  Azure CLI            88939486-3f56-4b35-bd43-5d6b34df022f  ed94de55-1f87-4278-9651-525e7ba467d6
```

**Result:** ✅ Single-tenant broker login works in broken state.

Confirmed multi-tenant still fails:
```bash
az logout && az login 2>&1
# User 'naganandyala@microsoft.com' does not exist in MSAL token cache. Run `az login`.
```

---

## Step 6: Clear MSAL Cache+Bin ONLY (Keychain Untouched)

```bash
az logout
rm -f ~/.azure/msal_token_cache.json ~/.azure/msal_http_cache.bin
az account clear
```

State after clear:
```
Keychain (untouched):
    "acct"="org.python.python.com.microsoft.identity.universalstorage-org.python.python"
    "acct"="org.python.python.com.microsoft.identity.universalstorage"

MSAL:
-rw-r--r-- naganandyala staff 6287 Mar 17 20:58 msal_http_cache.bin   (recreated by az account clear, tiny)
msal_token_cache.json — DELETED
```

```bash
az login 2>&1 | head -2
```

Output:
```
WARNING: Select the account you want to log in with...
ERROR: User 'naganandyala@microsoft.com' does not exist in MSAL token cache. Run `az login`.
```

**Result:** ❌ FAILS — Clearing MSAL cache alone (with keychain dirty) is NOT sufficient.

---

## Step 7: Clear BOTH Keychain + MSAL Cache

```bash
security delete-generic-password -a "org.python.python.com.microsoft.identity.universalstorage-org.python.python" login.keychain-db
security delete-generic-password -a "org.python.python.com.microsoft.identity.universalstorage" login.keychain-db
rm -f ~/.azure/msal_token_cache.json ~/.azure/msal_http_cache.bin
az account clear
```

State after clear:
```
Keychain: (none — only VS Code entries remain)
MSAL: msal_http_cache.bin (6KB, recreated by az account clear)
```

```bash
az login 2>&1 | head -8
```

Output:
```
WARNING: Select the account you want to log in with...
WARNING: Authentication failed against tenant 1a092f68... 'HMGAdmin': AADSTS53003 ...
WARNING: Authentication failed against tenant 213e87ed... 'Azure Client Tools': AADSTS5000224 ...
...
```

```bash
az account show --output table
# AzureCloud  72f988bf-...  True  dSCM PPE  Enabled  microsoft.onmicrosoft.com  Microsoft
```

**Result:** ✅ WORKS — Multi-tenant broker login succeeds after clearing both keychain and MSAL cache.

---

## Summary Table

| Step | Action | Keychain | MSAL Cache | Multi-tenant `az login` |
|------|--------|----------|------------|------------------------|
| 3 | Fresh install → broker login | clean → 2 entries | clean → 33KB/44KB | ✅ WORKS |
| 4 | Toggle false → browser login | 2 entries (same) | 34KB/57KB (+browser tokens) | ✅ WORKS |
| 5 | Toggle true → broker login | 2 entries | dirty | ❌ **FAILS** (bug) |
| 5b | `az login --tenant <id>` | 2 entries | dirty | ✅ WORKS |
| 6 | Clear MSAL only | 2 entries (dirty) | clean | ❌ **FAILS** |
| 7 | Clear keychain + MSAL | clean | clean | ✅ **WORKS** |

## Conclusion

**Both the macOS keychain entries AND the MSAL file cache must be cleared together** to recover from the broker toggle bug. Clearing only one storage layer is insufficient — the corrupted state spans both.

### Minimal Recovery Command
```bash
security delete-generic-password -a "org.python.python.com.microsoft.identity.universalstorage-org.python.python" login.keychain-db 2>/dev/null
security delete-generic-password -a "org.python.python.com.microsoft.identity.universalstorage" login.keychain-db 2>/dev/null
rm -f ~/.azure/msal_token_cache.json ~/.azure/msal_http_cache.bin
az account clear
az login
```
