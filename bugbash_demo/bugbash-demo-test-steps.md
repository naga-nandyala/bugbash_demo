# Bug Bash Test Steps

## Phase 1 — System & Environment Basics

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

## Phase 2 — Process & Network Checks

### Step 5 — Top CPU Processes
> Identify the most CPU-intensive processes currently running on the system.
[auto]
```
ps aux --sort=-%cpu | head -11
```

### Step 6 — Check Shell and PATH
> Verify the default shell and review all directories in PATH. Confirm the output looks correct.
[interactive]
```
echo "Shell: $SHELL" && echo "$PATH" | tr ':' '\n'
```

### Step 7 — DNS Lookup
> Run `nslookup github.com` in your terminal and paste the output. Confirm DNS resolution works.
[manual]
```
nslookup github.com
```

### Step 8 — Kill Test Background Process
> Start a sleep process in the background, then kill it. This terminates a process.
[destructive]
```
sleep 300 & BGPID=$! && echo "Started PID $BGPID" && kill $BGPID && echo "Killed PID $BGPID"
```
