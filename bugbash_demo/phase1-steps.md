# Phase 1 — System & Environment Basics

### Step 1 — Check OS Info
> Verify the operating system, kernel version, and architecture of the machine.
[auto]
```bash
uname -a
```
```pwsh
[System.Environment]::OSVersion; $PSVersionTable
```

### Step 2 — Memory Usage
> Check total, used, and available RAM and swap space, then confirm the output looks correct.
[interactive]
```bash
free -h 2>/dev/null || vm_stat
```
```pwsh
Get-CimInstance Win32_OperatingSystem | Select-Object TotalVisibleMemorySize, FreePhysicalMemory, TotalVirtualMemorySize, FreeVirtualMemory
```

### Step 3 — Home Directory Contents
> List the top-level contents of your home directory with sizes.
[manual]
```bash
ls -lh ~
```
```pwsh
Get-ChildItem ~ | Format-Table Name, Length, LastWriteTime
```

### Step 4 — Temp File Lifecycle
> Create a temporary file in /tmp, verify it exists, then delete it.
[destructive]
```bash
touch /tmp/bugbash_test_file && ls -l /tmp/bugbash_test_file && rm /tmp/bugbash_test_file
```
```pwsh
$f = "$env:TEMP\bugbash_test_file"; New-Item $f -ItemType File | Out-Null; Get-Item $f; Remove-Item $f
```
