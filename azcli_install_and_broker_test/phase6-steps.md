# Phase 6 — Telemetry Verification

Telemetry is available approximately 1 hour after login events. Record CorrelationIds now and verify via KQL later.

### Step 1 — Successful broker login
> Login via broker with debug output, capture the CorrelationId for later KQL verification. Mark as PASS (telemetry pending).
[interactive]
```
az logout 2>/dev/null || true
RESULTS_DIR="logs_bugbash_results_$(whoami)"
az login --tenant ed94de55-1f87-4278-9651-525e7ba467d6 --debug 2>&1 | tee ${RESULTS_DIR}/st1_debug.log | grep -E "correlation.id|CorrelationId|telemetry" | head -20
az account show --output table
```

### Step 2 — Cancelled broker login
> When the broker/SSO dialog appears, click Cancel or close it. Capture the CorrelationId. Mark as PASS (telemetry pending).
[interactive]
```
az logout 2>/dev/null || true
RESULTS_DIR="logs_bugbash_results_$(whoami)"
az login --tenant ed94de55-1f87-4278-9651-525e7ba467d6 --debug 2>&1 | tee ${RESULTS_DIR}/st2_debug.log | grep -E "correlation.id|CorrelationId" | head -5
```

### Step 3 — Non-broker login contrast
> Disable broker, login via browser, capture CorrelationId. This record should NOT appear in broker-filtered KQL. Mark as PASS (telemetry pending).
[interactive]
```
az logout 2>/dev/null || true
az config set core.enable_broker_on_mac=false
RESULTS_DIR="logs_bugbash_results_$(whoami)"
az login --tenant ed94de55-1f87-4278-9651-525e7ba467d6 --debug 2>&1 | tee ${RESULTS_DIR}/st3_debug.log | grep -E "correlation.id|CorrelationId|telemetry" | head -20
az account show --output table
az config set core.enable_broker_on_mac=true
```

### Step 4 — Verify installer field
> Check that the installer field shows HOMEBREW_CASK (not HOMEBREW). Mark as PASS (telemetry pending) for backend confirmation.
[auto]
```
az --version --debug 2>&1 | grep -i installer | head -5
az account show --output table --debug 2>&1 | grep -i installer | head -5
```

### Step 5 — MSAL version fields (KQL verification)
> This test is verified via KQL after Step 1 completes (~1 hour). MsalVersion and MsalRuntimeVersion must be non-empty. Run the KQL query below in your telemetry dashboard.
[manual]
```
RawEventsAzCli
| where tostring(Properties["context.default.azurecli.enablebrokeronmac"]) =~ "true"
| extend MsalTelemetryRaw = tostring(Properties["context.default.azurecli.msaltelemetry"])
| extend MsalTelemetry = parse_json(MsalTelemetryRaw)
| extend MsalRuntime = MsalTelemetry.msalruntime_telemetry
| extend
    MsalApiName        = tostring(MsalRuntime.api_name),
    BrokerAppUsed      = tostring(MsalRuntime.broker_app_used),
    MsalIsSuccessful   = tostring(MsalRuntime.is_successful),
    MsalVersion        = tostring(MsalRuntime.msal_version),
    MsalRuntimeVersion = tostring(MsalRuntime.msalruntime_version)
| extend
    EnableBrokerOnMac = tostring(Properties["context.default.azurecli.enablebrokeronmac"]),
    RawCommand        = tostring(Properties["context.default.azurecli.rawcommand"]),
    CoreVersion       = tostring(Properties["context.default.azurecli.coreversion"]),
    Installer         = tostring(Properties["context.default.azurecli.installer"])
| project-reorder MsalApiName, BrokerAppUsed, MsalIsSuccessful, MsalVersion, MsalRuntimeVersion,
    EventTimestamp, RawCommand, Params, OsType, EnableBrokerOnMac, CoreVersion, Installer, UserId, MachineId, *
```
