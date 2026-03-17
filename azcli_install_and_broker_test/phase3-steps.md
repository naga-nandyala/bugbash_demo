# Phase 3 — Offline Install (Tarball, Non-Homebrew Python)

### Step 1 — Download tarball
> Download the release tarball for the current architecture. The tarball is saved to the results folder for quarantine inspection before extraction.
[auto]
```
VERSION=2.84.0
ARCH=$(uname -m)
RESULTS_DIR="logs_bugbash_results_$(whoami)"
TARBALL="azure-cli-${VERSION}-macos-${ARCH}.tar.gz"
curl -L -o ${RESULTS_DIR}/${TARBALL} "https://github.com/Azure/homebrew-azure-cli/releases/download/azure-cli-${VERSION}/${TARBALL}"
ls -la ${RESULTS_DIR}/${TARBALL}
```

### Step 2 — Check quarantine attribute on tarball
> Verify the downloaded tarball has the com.apple.quarantine extended attribute (set by curl). This must be checked before extraction.
[auto]
```
RESULTS_DIR="logs_bugbash_results_$(whoami)"
VERSION=2.84.0
ARCH=$(uname -m)
TARBALL="azure-cli-${VERSION}-macos-${ARCH}.tar.gz"
echo "--- Quarantine on tarball ---"
xattr -l "${RESULTS_DIR}/${TARBALL}" 2>&1
```

### Step 3 — Extract tarball and check quarantine propagation
> Extract the tarball to azcli_offline_test/ and check whether the com.apple.quarantine attribute propagated to the extracted contents.
[auto]
```
VERSION=2.84.0
ARCH=$(uname -m)
RESULTS_DIR="logs_bugbash_results_$(whoami)"
TARBALL="azure-cli-${VERSION}-macos-${ARCH}.tar.gz"
rm -rf azcli_offline_test && mkdir azcli_offline_test
tar -xzf ${RESULTS_DIR}/${TARBALL} -C azcli_offline_test
ls -la azcli_offline_test/bin/az
echo ""
echo "--- Quarantine on extracted az script ---"
xattr -l "azcli_offline_test/bin/az" 2>&1
echo ""
echo "--- Quarantine on a sample .so file ---"
SAMPLE_SO=$(find "azcli_offline_test" -type f -name "*.so" | head -1)
if [ -n "$SAMPLE_SO" ]; then
  xattr -l "$SAMPLE_SO" 2>&1
else
  echo "No .so files found"
fi
```

### Step 4 — Verify signatures on .so and .dylib files
> Verify that native binaries (.so and .dylib files) in the extracted tarball are signed by Microsoft. The `az` entrypoint is a shell script and cannot be codesigned.
[auto]
```
echo "az entrypoint is a shell script:"
file "azcli_offline_test/bin/az"
echo ""
echo "--- .so and .dylib files (Microsoft signature TeamIdentifier=UBF8T346G9) ---"
find "azcli_offline_test" -type f \( -name "*.so" -o -name "*.dylib" \) | while read -r f; do
  sig=$(codesign -dv --verbose=2 "$f" 2>&1)
  team=$(echo "$sig" | grep "TeamIdentifier=" | cut -d= -f2)
  if [ "$team" = "UBF8T346G9" ]; then
    echo "PASS: $(basename "$f") — signed by Microsoft"
  else
    echo "FAIL: $(basename "$f") — TeamIdentifier=$team"
  fi
done
```

### Step 5 — Confirm az fails without AZ_PYTHON
> Run az without setting AZ_PYTHON to verify it exits with a human-readable error, not a traceback.
[auto]
```
azcli_offline_test/bin/az --version 2>&1 | head -5
```

### Step 6 — Install python.org Python 3.13
> Download and install Python 3.13 from python.org. This installs a universal2 (ARM + Intel) framework build to /Library/Frameworks/Python.framework/. Requires sudo for installation.
[interactive]
```
PY_VERSION=3.13.2
RESULTS_DIR="logs_bugbash_results_$(whoami)"
PKG="python-${PY_VERSION}-macos11.pkg"
echo "Downloading Python ${PY_VERSION} from python.org..."
curl -L -o "${RESULTS_DIR}/${PKG}" "https://www.python.org/ftp/python/${PY_VERSION}/${PKG}"
ls -la "${RESULTS_DIR}/${PKG}"
echo ""
echo "Installing Python ${PY_VERSION} (requires sudo)..."
sudo installer -pkg "${RESULTS_DIR}/${PKG}" -target /
echo ""
echo "--- Verify installation ---"
NON_HB_PYTHON="/Library/Frameworks/Python.framework/Versions/3.13/bin/python3"
ls -la "${NON_HB_PYTHON}" && "${NON_HB_PYTHON}" --version
echo ""
echo "--- pkgutil verification ---"
pkgutil --pkgs | grep -i org.python.Python
```

### Step 7 — Run az with python.org Python
> Set AZ_PYTHON to the python.org Python path and verify az works. Skip if Step 6 failed.
[auto]
```
NON_HB_PYTHON="/Library/Frameworks/Python.framework/Versions/3.13/bin/python3"
AZ_PYTHON="${NON_HB_PYTHON}" azcli_offline_test/bin/az --version
AZ_PYTHON="${NON_HB_PYTHON}" azcli_offline_test/bin/az find "create storage account"
```

### Step 8 — Verify extensions in offline mode
> Confirm extensions load correctly in offline mode. Skip if Step 6 failed.
[auto]
```
NON_HB_PYTHON="/Library/Frameworks/Python.framework/Versions/3.13/bin/python3"
AZ_PYTHON="${NON_HB_PYTHON}" azcli_offline_test/bin/az extension list --output table
AZ_PYTHON="${NON_HB_PYTHON}" azcli_offline_test/bin/az devops project list --org https://dev.azure.com/azclitools --output table
```

### Step 9 — Cleanup
> Remove the temporary tarball, python.org installer, and extracted azcli_offline_test/ directory. Warning: this deletes test files.
[destructive]
```
RESULTS_DIR="logs_bugbash_results_$(whoami)"
rm -rf azcli_offline_test ${RESULTS_DIR}/azure-cli-*.tar.gz ${RESULTS_DIR}/python-*.pkg
```
