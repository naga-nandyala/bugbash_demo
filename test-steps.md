# Bug Bash Test Steps

## Phase 1 — System Info

### Step 1 — Check OS Info
> Verify the operating system, kernel version, and architecture of the machine.
Execution: auto
```
uname -a
```

### Step 2 — Memory Usage
> Check total, used, and available RAM and swap space.
Execution: approve
```
free -h
```

### Step 3 — Disk Usage Summary
> Review mounted filesystems and their disk space usage.
Execution: auto
```
df -h
```

## Phase 2 — Files & Directories

### Step 4 — Current Directory and Contents
> Confirm the working directory and list all files with permissions and sizes.
Execution: auto
```
pwd && ls -la
```

### Step 5 — Find Large Files (top 10 in /tmp)
> Identify the largest files in /tmp that may be consuming disk space.
Execution: approve
```
find /tmp -type f -exec du -h {} + 2>/dev/null | sort -rh | head -10
```

## Phase 3 — Processes & Environment

### Step 6 — Running Processes (Top 10 by CPU)
> Identify the most CPU-intensive processes currently running on the system.
Execution: auto
```
ps aux --sort=-%cpu | head -11
```

### Step 7 — Environment Variables (first 20)
> Inspect the environment variables set in the current shell session.
Execution: auto
```
env | head -20
```

### Step 8 — Check Shell and PATH
> Verify the default shell and review all directories in the PATH.
Execution: approve
```
echo "Shell: $SHELL" && echo "PATH: $PATH" | tr ':' '\n'
```

## Phase 4 — Network & Kernel

### Step 9 — Network Interfaces
> List all network interfaces with their IP addresses and status.
Execution: auto
```
ip addr show
```

### Step 10 — Kernel Logs (last 15 lines)
> Check recent kernel messages for errors, warnings, or hardware events.
Execution: approve
```
dmesg --color=never 2>/dev/null | tail -15 || journalctl -k --no-pager -n 15 2>/dev/null || echo "No kernel log access"
```
