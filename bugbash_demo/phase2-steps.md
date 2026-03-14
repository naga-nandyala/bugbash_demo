# Phase 2 — Process & Network Checks

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
