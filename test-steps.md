# Bug Bash Test Steps

## Phase 1 — System Info

### Step 1 — Check OS Info
> Verify the operating system, kernel version, and architecture of the machine.
[auto]
```
uname -a
```

### Step 2 — Current User and Hostname
> Confirm who you are logged in as and the machine hostname.
[auto]
```
whoami && hostname
```

### Step 3 — Memory Usage
> Check total, used, and available RAM and swap space.
[interactive]
```
free -h
```

### Step 4 — Disk Usage Summary
> Review mounted filesystems and their disk space usage.
[auto]
```
df -h
```

## Phase 2 — Files & Directories

### Step 5 — Current Directory and Contents
> Confirm the working directory and list all files with permissions and sizes.
[auto]
```
pwd && ls -la
```

### Step 6 — Create and Remove a Temp File
> Create a temporary file in /tmp, verify it exists, then delete it.
[destructive]
```
touch /tmp/bugbash_test_file && ls -l /tmp/bugbash_test_file && rm /tmp/bugbash_test_file
```

### Step 7 — Check Disk Usage of Home Directory
> Open a terminal and run `du -sh ~` to check how much space your home directory uses. Paste the output here.
[manual]
```
du -sh ~
```

## Phase 3 — Processes & Environment

### Step 8 — Running Processes (Top 10 by CPU)
> Identify the most CPU-intensive processes currently running on the system.
[auto]
```
ps aux --sort=-%cpu | head -11
```

### Step 9 — Environment Variables (first 20)
> Inspect the environment variables set in the current shell session.
[auto]
```
env | head -20
```

### Step 10 — Check Shell and PATH
> Verify the default shell and review all directories in the PATH. Confirm the output looks correct.
[interactive]
```
echo "Shell: $SHELL" && echo "$PATH" | tr ':' '\n'
```

### Step 11 — Kill a Test Background Process
> Start a sleep process in the background, then kill it. This will terminate a process.
[destructive]
```
sleep 300 & BGPID=$! && echo "Started PID $BGPID" && kill $BGPID && echo "Killed PID $BGPID"
```

## Phase 4 — Network & Kernel

### Step 12 — Network Interfaces
> List all network interfaces with their IP addresses and status.
[auto]
```
ifconfig 2>/dev/null || ip addr show
```

### Step 13 — Test DNS Resolution
> Run `nslookup github.com` in your terminal and paste the output. Confirm DNS is resolving correctly.
[manual]
```
nslookup github.com
```

### Step 14 — Kernel Logs (last 15 lines)
> Check recent kernel messages for errors, warnings, or hardware events. This may require elevated permissions.
[destructive]
```
dmesg 2>/dev/null | tail -15 || log show --predicate 'eventMessage contains "kernel"' --last 1m 2>/dev/null | tail -15 || echo "No kernel log access"
```
