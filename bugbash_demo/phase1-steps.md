# Phase 1 — System & Environment Basics

### Step 1 — Check OS Info
> Verify the operating system, kernel version, and architecture of the machine.
[auto]
```
uname -a
```

### Step 2 — Memory Usage
> Check total, used, and available RAM and swap space, then confirm the output looks correct.
[interactive]
```
free -h
```

### Step 3 — Home Directory Size
> Open a terminal and run `du -sh ~` to check home directory usage. Paste the output here.
[manual]
```
du -sh ~
```

### Step 4 — Temp File Lifecycle
> Create a temporary file in /tmp, verify it exists, then delete it.
[destructive]
```
touch /tmp/bugbash_test_file && ls -l /tmp/bugbash_test_file && rm /tmp/bugbash_test_file
```
