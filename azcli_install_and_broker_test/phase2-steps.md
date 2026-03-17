# Phase 2 — New Install via Homebrew-Cask

### Step 1 — Untap custom taps (clean slate)
> Remove any previously tapped custom taps to ensure a clean starting state. Safe to run even if taps are not present.
[auto]
```
brew untap Azure/azure-cli 2>/dev/null || true
brew untap naga-nandyala/mycli-app 2>/dev/null || true
brew tap | grep -E 'azure/azure-cli|naga-nandyala/mycli-app' && echo 'WARN: tap still present' || echo 'PASS: custom taps removed'
```

### Step 2 — Tap and inspect cask
> Add the Azure CLI cask tap and verify it shows version 2.84.0 pointing to the correct release repo.
[auto]
```
brew tap Azure/azure-cli
brew tap-info Azure/azure-cli
brew info --cask azure-cli
cat $(brew --repository Azure/azure-cli)/Casks/a/azure-cli.rb
```

### Step 3 — Install cask
> Install the azure-cli cask and verify az resolves, version is 2.84.0, and install lives under Caskroom.
[auto]
```
brew install --cask azure-cli
which az
az --version
ls -la $(brew --prefix)/Caskroom/azure-cli/ 2>/dev/null
```

### Step 4 — Verify signatures
> Verify that native binaries (.so and .dylib files) in the cask are signed by Microsoft, and the Homebrew-installed Python dependency is also signed. The `az` entrypoint is a shell script and cannot be codesigned.
[auto]
```
CASK_DIR="$(brew --prefix)/Caskroom/azure-cli"
echo "az entrypoint is a shell script:"
file "$(which az)"
echo ""
echo "--- Homebrew Python dependency signature ---"
PYTHON_BIN="$(brew --prefix)/opt/python@3.13/bin/python3.13"
codesign -dv --verbose=2 "${PYTHON_BIN}" 2>&1 | grep -E "Authority|TeamIdentifier|Signature"
echo ""
echo "--- Cask .so and .dylib files (Microsoft signature TeamIdentifier=UBF8T346G9) ---"
find "${CASK_DIR}" -type f \( -name "*.so" -o -name "*.dylib" \) | while read -r f; do
  sig=$(codesign -dv --verbose=2 "$f" 2>&1)
  team=$(echo "$sig" | grep "TeamIdentifier=" | cut -d= -f2)
  if [ "$team" = "UBF8T346G9" ]; then
    echo "PASS: $(basename "$f") — signed by Microsoft"
  else
    echo "FAIL: $(basename "$f") — TeamIdentifier=$team"
  fi
done
```

### Step 5 — Login and verify browser-based auth
> A browser-based login prompt will open. Complete the login and select the tenant if prompted. Verify account details. (No broker in this phase — Azure/azure-cli cask does not include broker.)
[interactive]
```
az login
az account show --output table
```

### Step 6 — Basic functionality
> Run basic az commands to confirm no Python tracebacks or import failures.
[auto]
```
az --version
az find "create a storage account"
az account show 2>&1 | head -10
```

### Step 7 — Verify extensions work
> Confirm extensions are listed and azure-devops returns project list.
[auto]
```
az extension list --output table
az devops project list --org https://dev.azure.com/azclitools --output table
```

### Step 8 — Install a new extension then uninstall it
> Install the account extension, verify it, then remove it cleanly.
[auto]
```
az extension add --name account
az extension list --output table
az extension show --name account
az extension remove --name account
az extension list --output table
```

### Step 9 — az upgrade
> Verify the cask-installed CLI handles self-update without errors.
[auto]
```
az upgrade 2>&1
```

### Step 10 — Reinstall and upgrade simulation
> Reinstall and attempt upgrade of the cask to verify no broken symlinks.
[auto]
```
brew reinstall --cask azure-cli
az --version
brew upgrade --cask azure-cli 2>&1
az --version
```

### Step 11 — Uninstall cask and untap
> Remove the cask-installed azure-cli and untap both custom taps. Warning: this will remove the current installation.
[destructive]
```
brew uninstall --cask azure-cli
brew untap Azure/azure-cli 2>/dev/null || true
brew untap naga-nandyala/mycli-app 2>/dev/null || true
which az && echo "FAIL: az still on PATH" || echo "PASS: az removed"
ls $(brew --prefix)/Caskroom/azure-cli 2>/dev/null && echo "FAIL: Caskroom dir remains" || echo "PASS: Caskroom cleaned"
brew tap | grep -E 'azure/azure-cli|naga-nandyala/mycli-app' && echo 'WARN: tap still present' || echo 'PASS: custom taps removed'
ls ~/.azure/ && echo "PASS: ~/.azure retained" || echo "FAIL: ~/.azure gone"
ls ~/.azure/cliextensions/ 2>/dev/null && echo "PASS: extensions retained" || echo "NOTE: no extensions dir"
```
