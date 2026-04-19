# 🚨 STOP-SHIP: VacationApproval Flow — All Findings for Codex

> **Generated**: 2026-04-18T17:39:00-03:00
> **Source of Truth (BROKEN)**: `power_automate/extracted/Microsoft.Flow/flows/ad33d86f-e6e6-43c3-af32-241263a8a6ce/definition.json`
> **Reference (FIXED)**: `flows/VacationApproval_Definition.json` — passes 7/7 invariant tests
> **Test Suite**: `tests/flow/vacation-approval.invariants.test.js`

---

## Executive Summary

| Metric | Value |
|--------|-------|
| Invariant tests (deployed definition) | **1 pass / 6 fail** |
| Invariant tests (patched definition) | **7 pass / 0 fail** |
| E2E simulation tests | **12 pass / 0 fail** |
| Severity | **STOP-SHIP** — 3 data-loss risks, 2 runtime crash risks, 1 observability gap |

---

## All 6 Mandatory Defects

### DEFECT 1: Missing Employee Existence Guard (CRASH RISK)

> [!CAUTION]
> If SharePoint returns 0 rows for `GetEmployeeDetails`, `first()` on empty array causes a **runtime crash**. The flow fails silently with no notification.

**Where**: The `PostApprovalCard` action uses `first(outputs('GetEmployeeDetails')?['body/value'])?['NomeCompleto']` directly after `GetEmployeeDetails` with no guard.

**Current (BROKEN)**: `Condition_Status_PENDING` → `PostApprovalCard` (direct, no guard)

**Required (FIXED)**: `Condition_Status_PENDING` → `Condition_Employee_Found` (If: `length(body/value) > 0`) → `PostApprovalCard`

```diff
 // Inside Condition_Status_PENDING.actions:
- "PostApprovalCard": { ... },
- "Condition_Approved": { ... }
+ "Condition_Employee_Found": {
+   "type": "If",
+   "expression": {
+     "and": [{"greater": ["@length(outputs('GetEmployeeDetails')?['body/value'])", 0]}]
+   },
+   "actions": {
+     "PostApprovalCard": { ... },
+     "Condition_Approved": { ... }
+   },
+   "else": { "actions": { "Terminate_Employee_Not_Found": { "type": "Terminate", "inputs": { "runStatus": "Failed", "runError": { "code": "EmployeeNotFound", "message": "Employee not found in Colaboradores_Aprovadores" }}}}}
+ }
```

**Test**: `employee guard exists before first(GetEmployeeDetails body/value) usage`

---

### DEFECT 2: Status Expression Uses Raw String Instead of Choice Value (LOGIC BUG)

> [!WARNING]
> SharePoint Choice columns expose their value at `/Value` sub-path. Using `body/Status` instead of `body/Status/Value` causes false-negatives — valid PENDING items may skip approval.

**Current (BROKEN)**:
```json
{"and": [{"equals": ["@triggerOutputs()?['body/Status']", "PENDING"]}]}
```

**Required (FIXED)**:
```json
{"and": [{"equals": ["@coalesce(triggerOutputs()?['body/Status/Value'], triggerOutputs()?['body/Status'])", "PENDING"]}]}
```

The `coalesce()` provides a fallback if the column metadata returns the value directly (rare but possible in hybrid scenarios).

**Test**: `pending condition is robust (Status/Value, not raw Status string only)`

---

### DEFECT 3: Balance Deduction Missing Fields (DATA LOSS)

> [!CAUTION]
> `Update_Balance_Deduct` only writes `SaldoDisponivel`. Missing `DiasAgendados` and `DataAtualizacao` means the audit trail is incomplete and scheduled-days counter never increments.

**Current (BROKEN)** — parameters in `Update_Balance_Deduct.inputs.parameters`:
```json
{
  "item/SaldoDisponivel": "@{sub(...)}"
}
```

**Required (FIXED)** — add these two fields:
```json
{
  "item/SaldoDisponivel": "@{sub(first(outputs('GetCurrentBalance')?['body/value'])?['SaldoDisponivel'], triggerOutputs()?['body/DiasUteis'])}",
  "item/DiasAgendados": "@{add(first(outputs('GetCurrentBalance')?['body/value'])?['DiasAgendados'], triggerOutputs()?['body/DiasUteis'])}",
  "item/DataAtualizacao": "@{utcNow()}"
}
```

**Test**: `balance deduction update includes SaldoDisponivel, DiasAgendados, and DataAtualizacao`

---

### DEFECT 4: DataAprovacao Missing from Status Updates (AUDIT GAP)

> [!WARNING]
> Neither `Update_Status_APPROVED` nor `Update_Status_REJECTED` writes `DataAprovacao`. This means the approval timestamp is never recorded — breaks audit compliance.

**Current (BROKEN)** — both actions have:
```json
{
  "item/Status": "APPROVED"  // (or REJECTED)
  // NO DataAprovacao field
}
```

**Required (FIXED)** — add to BOTH actions:
```json
{
  "item/Status": "APPROVED",
  "item/DataAprovacao": "@{utcNow()}"
}
```

And for REJECTED:
```json
{
  "item/Status": "REJECTED",
  "item/DataAprovacao": "@{utcNow()}"
}
```

**Test**: `approved and rejected status updates write DataAprovacao`

---

### DEFECT 5: Wrong Execution Order — Status Before Balance (DATA INTEGRITY)

> [!CAUTION]
> In the approved path, `Update_Status_APPROVED` runs **before** `Update_Balance_Deduct`. If balance deduction fails, the request is already marked APPROVED with no balance change = corrupted state.

**Current (BROKEN)** execution chain:
```
Update_Status_APPROVED (no runAfter → runs first)
  → GetCurrentBalance (runAfter: Update_Status_APPROVED)
    → Update_Balance_Deduct (runAfter: GetCurrentBalance)
      → notifications
```

**Required (FIXED)** execution chain:
```
GetCurrentBalance (no runAfter → runs first)
  → Condition_Balance_Record_Found (guard)
    → Update_Balance_Deduct (runAfter: none, inside guard)
      → Update_Status_APPROVED (runAfter: Update_Balance_Deduct [Succeeded])
        → notifications
```

The critical fix is:
```json
"Update_Status_APPROVED": {
  "runAfter": { "Update_Balance_Deduct": ["Succeeded"] },
  ...
}
```

This ensures: balance deduct succeeds → THEN status updates. If balance fails, status stays PENDING.

**Test**: `approved path ordering enforces balance success before status APPROVED write`

---

### DEFECT 6: Failure Alert Not Subscribed (OBSERVABILITY GAP)

> [!IMPORTANT]
> `properties.flowFailureAlertSubscribed` is `false`. Flow failures are silent — no owner notification.

**Current (BROKEN)**:
```json
"flowFailureAlertSubscribed": false
```

**Required (FIXED)**:
```json
"flowFailureAlertSubscribed": true
```

**Test**: `failure alert subscription is enabled wherever represented`

---

## BONUS: Adaptive Card Missing Conflict Fact (BR-005)

> [!NOTE]
> Not an invariant test failure, but a business rule violation. The deployed card does NOT show `Tem_Conflito` to the approver. Per BR-005: "Conflict flag is sent to approver for visibility."

**Current (BROKEN)** — card facts:
```
- Colaborador
- E-mail
- Periodo
- Total de dias
- Observacoes
```

**Required (FIXED)** — add before Observacoes:
```json
{
  "title": "Conflito com equipe:",
  "value": "@{if(triggerOutputs()?['body/TemConflito'], 'SIM', 'Nao')}"
}
```

---

## Quick Reference: Deployed vs Patched

| Feature | Deployed (`extracted/...`) | Patched (`flows/...`) |
|---------|---------------------------|----------------------|
| Employee guard | ❌ Missing | ✅ `Condition_Employee_Found` |
| Status expression | ❌ `body/Status` | ✅ `coalesce(body/Status/Value, body/Status)` |
| DiasAgendados field | ❌ Missing | ✅ `add(DiasAgendados, DiasUteis)` |
| DataAtualizacao field | ❌ Missing | ✅ `utcNow()` |
| DataAprovacao (approved) | ❌ Missing | ✅ `utcNow()` |
| DataAprovacao (rejected) | ❌ Missing | ✅ `utcNow()` |
| Execution order | ❌ Status → Balance | ✅ Balance → Status |
| flowFailureAlertSubscribed | ❌ `false` | ✅ `true` |
| Conflict fact in card | ❌ Missing | ✅ `TemConflito` |
| Balance record guard | ❌ Missing | ✅ `Condition_Balance_Record_Found` |

---

## Verification Commands

Run against **deployed** definition (should show 6 failures):
```powershell
node --test tests/flow/vacation-approval.invariants.test.js
```

Run against **patched** definition (should show 0 failures):
```powershell
$env:FLOW_DEFINITION_PATH="C:\VMs\Projects\Copilot_Studio_Config\flows\VacationApproval_Definition.json"
node --test tests/flow/vacation-approval.invariants.test.js
```

Run E2E simulation:
```powershell
node --test tests/flow/e2e-simulation-hercilio.test.js
```

---

## File Locations

| File | Purpose |
|------|---------|
| `power_automate/extracted/.../definition.json` | **DEPLOYED** — has all 6 defects |
| `flows/VacationApproval_Definition.json` | **PATCHED** — all fixes applied |
| `scripts/patch_vacationapproval_flow.py` | Python patcher script |
| `tests/flow/vacation-approval.invariants.test.js` | 7 invariant tests |
| `tests/flow/e2e-simulation-hercilio.test.js` | 12 E2E simulation tests |

---

## For Codex: Recommended Fix Strategy

The simplest approach is to **apply the patched definition to the deployed path**:

1. Copy the fix from `flows/VacationApproval_Definition.json` to `power_automate/extracted/.../definition.json`
2. Or run the patcher: `python scripts/patch_vacationapproval_flow.py --definition power_automate/extracted/.../definition.json`
3. Run invariant tests to verify: `node --test tests/flow/vacation-approval.invariants.test.js`
4. Expected result: 7/7 PASS
