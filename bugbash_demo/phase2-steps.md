# Phase 2 — Process & Network Checks

### Step 5 — Top CPU Processes
> Identify the most CPU-intensive processes currently running on the system.
[auto]
```bash
ps aux --sort=-%cpu | head -11
```
```pwsh
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 Name, Id, CPU, WorkingSet
```

### Step 6 — Check Shell and PATH
> Verify the default shell and review all directories in PATH. Confirm the output looks correct.
[interactive]
```bash
echo "Shell: $SHELL" && echo "$PATH" | tr ':' '\n'
```
```pwsh
Write-Output "Shell: PowerShell $($PSVersionTable.PSVersion)"; $env:PATH -split ';'
```

### Step 7 — DNS Lookup
> Run `nslookup github.com` in your terminal and paste the output. Confirm DNS resolution works.
[manual]
```bash
nslookup github.com
```
```pwsh
nslookup github.com
```

### Step 8 — Kill Test Background Process
> Start a sleep process in the background, then kill it. This terminates a process.
[destructive]
```bash
sleep 300 & BGPID=$! && echo "Started PID $BGPID" && kill $BGPID && echo "Killed PID $BGPID"
```
```pwsh
$p = Start-Process -PassThru -WindowStyle Hidden powershell -ArgumentList "Start-Sleep 300"; Write-Output "Started PID $($p.Id)"; Stop-Process -Id $p.Id; Write-Output "Killed PID $($p.Id)"
```
