# Phase 1 — Existing State (Homebrew-Core Baseline)

### Step 1 — Discover all Python installations
> Find every Python installation on the machine: Homebrew, python.org (via pkgutil), Xcode Command Line Tools, pyenv, and any others on PATH.
[auto]
```
echo "=== Homebrew Python ==="
brew list --formula | grep python || echo "No Python formula installed via Homebrew"
brew info python@3.13 2>/dev/null | head -5 || echo "python@3.13 not installed via Homebrew"
echo ""
echo "=== python.org (pkgutil) ==="
pkgutil --pkgs | grep -i org.python || echo "No python.org packages found"
echo ""
echo "=== Xcode Command Line Tools Python ==="
/usr/bin/python3 --version 2>/dev/null && echo "  path: /usr/bin/python3" || echo "Not found"
echo ""
echo "=== pyenv ==="
which pyenv 2>/dev/null && pyenv versions 2>/dev/null || echo "pyenv not available"
echo ""
echo "=== All python3 binaries on PATH ==="
type -a python3 2>/dev/null || echo "No python3 found on PATH"
echo ""
echo "=== Python framework versions ==="
ls -d /Library/Frameworks/Python.framework/Versions/*/ 2>/dev/null || echo "No python.org framework versions"
```

### Step 2 — Installation check
> Verify the current homebrew-core azure-cli is installed and record its version and prefix.
[auto]
```
which az
az --version
brew info azure-cli 2>/dev/null || echo "azure-cli formula not installed"
brew list --formula | grep azure-cli
```

### Step 3 — Capture extensions and config
> Record the installed extensions, config file, and ~/.azure contents for later comparison.
[auto]
```
az extension list --output table
ls -la ~/.azure/cliextensions/ 2>/dev/null || echo "no cliextensions dir"
cat ~/.azure/config 2>/dev/null || echo "no config file"
ls ~/.azure/
```

### Step 4 — Login and run a command against azclitools
> A browser-based login prompt will open. Complete the login and select the tenant if prompted. Then verify azure-devops extension works. (No broker in this phase — homebrew-core does not include broker.)
[interactive]
```
az login
az account show --output table
az extension add --name azure-devops 2>/dev/null || true
az devops project list --org https://dev.azure.com/azclitools --output table
```

### Step 5 — az upgrade
> Run az upgrade to confirm it works on the current homebrew-core install.
[auto]
```
az upgrade 2>&1
```

### Step 6 — Reinstall homebrew-core formula
> Reinstall the formula and verify version, config, and extensions are intact afterward.
[auto]
```
brew reinstall azure-cli && az --version
az extension list --output table
cat ~/.azure/config 2>/dev/null || echo "no config file"
```

### Step 7 — Uninstall homebrew-core azure-cli
> Remove the current homebrew-core azure-cli. Warning: this will remove the current installation.
[destructive]
```
brew uninstall azure-cli
which az && echo "FAIL: az still on PATH" || echo "PASS: az removed"
brew list --formula | grep azure-cli && echo "FAIL: formula remains" || echo "PASS: formula removed"
ls ~/.azure/ && echo "PASS: ~/.azure retained" || echo "FAIL: ~/.azure gone"
ls ~/.azure/cliextensions/ 2>/dev/null && echo "PASS: extensions dir retained" || echo "NOTE: no extensions dir"
```
