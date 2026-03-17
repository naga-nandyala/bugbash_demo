# Phase 5 — Broker Authentication

Note: Untap any existing custom taps and re-install the cask before running broker tests:
```
brew untap Azure/azure-cli 2>/dev/null || true
brew untap naga-nandyala/mycli-app 2>/dev/null || true
brew tap naga-nandyala/mycli-app
brew install --cask azure-cli 2>/dev/null || true
```

### Step 1 — Check Company Portal
> Verify that Microsoft Intune Company Portal is installed and record its version.
[auto]
```
ls /Applications/Company\ Portal.app 2>/dev/null && echo "FOUND" || echo "NOT INSTALLED"
defaults read /Applications/Company\ Portal.app/Contents/Info CFBundleShortVersionString 2>/dev/null || echo "version read failed"
```

### Step 2 — Broker auto-invoked on az login
> A login prompt will appear. Note whether it is the macOS broker dialog (Company Portal/SSO) or a browser tab. Complete the login.
[interactive]
```
az logout 2>/dev/null || true
az config get core.enable_broker_on_mac 2>/dev/null || echo "not set (defaults to true on macOS)"
az login
az account show --output table
```

### Step 3 — Disable broker then browser fallback
> A browser tab should open for login (not broker). Complete the login and confirm it was browser-based.
[interactive]
```
az logout
az config set core.enable_broker_on_mac=false
az config get core.enable_broker_on_mac
az login
az account show --output table
```

### Step 4 — Re-enable broker then broker invoked again
> The broker dialog should appear again. Complete the login and confirm it was the broker UI.
[interactive]
```
az logout
az config set core.enable_broker_on_mac=true
az config get core.enable_broker_on_mac
az login
az account show --output table
```

### Step 5 — No Company Portal plus config equals true then browser fallback
> ⛔ BLOCKED — Do NOT run this step on a real user machine. Removing Company Portal de-registers the device from Intune. Reinstalling Company Portal does NOT automatically re-register the device, leaving it non-compliant and breaking all broker-based (and some browser-based) authentication permanently until the device is manually re-registered. This test should only be run on a dedicated test VM.
[manual]
```
az logout
sudo rm -rf /Applications/Company\ Portal.app
ls /Applications/Company\ Portal.app 2>/dev/null && echo "still present" || echo "REMOVED"
az config get core.enable_broker_on_mac
az login
az account show --output table
```

After login, the user must reinstall Company Portal from Mac App Store, then verify:
```
ls /Applications/Company\ Portal.app 2>/dev/null && echo "REINSTALLED" || echo "STILL MISSING — must reinstall"
pluginkit -m -v 2>/dev/null | grep com.microsoft.CompanyPortalMac.ssoextension
```

### Step 6 — Login into azclitools tenant
> Complete the broker or browser login to the azclitools tenant and verify azure-devops project list returns.
[interactive]
```
az logout
az login --tenant ed94de55-1f87-4278-9651-525e7ba467d6
az devops project list --org https://dev.azure.com/azclitools --output table
```
