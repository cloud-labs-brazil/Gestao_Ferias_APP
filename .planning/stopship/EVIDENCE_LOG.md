# SEV-0 Evidence Log - VacationApproval Flow

Date (local): 2026-04-18  
Analyst mode: Deterministic, evidence-first, local-files-only  
Scope: Static forensics for `Export_Gestao_Ferias_20260418190548.zip` without calling external systems

## Evidence Artifacts
- `power_automate/Export_Gestao_Ferias_20260418190548.zip`
- `power_automate/extracted/definition_pretty.json`
- `power_automate/extracted/manifest.json`
- `power_automate/extracted/Microsoft.Flow/flows/ad33d86f-e6e6-43c3-af32-241263a8a6ce/apisMap.json`
- `docs/Flow-Blueprint-VacationApproval.md`
- `.planning/phases/02-power-automate-vacationapproval/02-CONTEXT.md`

## Commands Run (Deterministic)

`C1`
```powershell
Get-FileHash -Algorithm SHA256 'power_automate/Export_Gestao_Ferias_20260418190548.zip'
```
Output summary: SHA256 = `D9E8D47D81E30E95B3FED320DFD01A99CDEF33A39C642B04811557BE8A2DBDAF`.

`C2`
```powershell
Get-ChildItem -Recurse 'power_automate/extracted' -File | Select-Object FullName
```
Output summary: extracted package contains `definition_pretty.json`, export `manifest.json`, and flow files (`definition.json`, `apisMap.json`, `connectionsMap.json`).

`C3`
```powershell
$def='power_automate/extracted/definition_pretty.json'
rg -n "body/AprovadorEmail|PostCardAndWaitForResponse|Update_Status_APPROVED|GetCurrentBalance|Update_Balance_Deduct|item/SaldoDisponivel|body/Status|flowFailureAlertSubscribed|failureAlertSubscription" $def
```
Output summary: confirms approver source from trigger, Teams card wait action, approval->balance sequencing, status check using `body/Status`, and alert flag state.

`C4`
```powershell
$def='power_automate/extracted/definition_pretty.json'
$apis='power_automate/extracted/Microsoft.Flow/flows/ad33d86f-e6e6-43c3-af32-241263a8a6ce/apisMap.json'
if((rg -n "length\\(outputs\\('GetEmployeeDetails'\\)\\?\\['body/value'\\]\\)|empty\\(outputs\\('GetEmployeeDetails'\\)\\?\\['body/value'\\]\\)|greater\\(length\\(outputs\\('GetEmployeeDetails'\\)\\?\\['body/value'\\]\\)" $def | Measure-Object).Count -eq 0){'NO_MATCH employee guard expression'}
if((rg -n "length\\(outputs\\('GetCurrentBalance'\\)\\?\\['body/value'\\]\\)|empty\\(outputs\\('GetCurrentBalance'\\)\\?\\['body/value'\\]\\)|greater\\(length\\(outputs\\('GetCurrentBalance'\\)\\?\\['body/value'\\]\\)" $def | Measure-Object).Count -eq 0){'NO_MATCH balance guard expression'}
if((rg -n "item/DataAprovacao|item/DiasAgendados|item/DataAtualizacao" $def | Measure-Object).Count -eq 0){'NO_MATCH DataAprovacao/DiasAgendados/DataAtualizacao updates'}
if((rg -n "Status/Value" $def | Measure-Object).Count -eq 0){'NO_MATCH Status/Value condition usage'}
if((rg -n "timeout|escalat|Delay|Terminate_ApprovalTimeout" $def | Measure-Object).Count -eq 0){'NO_MATCH timeout/escalation handling'}
if((rg -n "shared_approvals|approvals" $apis | Measure-Object).Count -eq 0){'NO_MATCH approvals connector in apisMap'}
if((rg -n "TemConflito" $def | Measure-Object).Count -eq 0){'NO_MATCH TemConflito in approval payload'}
```
Output summary: all checks returned `NO_MATCH` for the listed safeguards/fields/connectors.

`C5`
```powershell
$bp='docs/Flow-Blueprint-VacationApproval.md'
$ctx='.planning/phases/02-power-automate-vacationapproval/02-CONTEXT.md'
rg -n "Start and wait for an approval|DataAprovacao|DiasAgendados|DataAtualizacao|TemConflito" $bp
rg -n "D-11|D-13|D-28|Status/Value|first\\(\\)|Data_Aprovacao|DataAprovacao" $ctx
```
Output summary: blueprint/context explicitly require approvals action, conflict detail, data fields, and guard logic.

`C6`
```powershell
$apis='power_automate/extracted/Microsoft.Flow/flows/ad33d86f-e6e6-43c3-af32-241263a8a6ce/apisMap.json'
$manifest='power_automate/extracted/manifest.json'
rg -n "shared_sharepointonline|shared_teams|shared_office365|shared_approvals" $apis
rg -n "createdTime|displayName|mbenicios@minsait.com|GestaoFerias_VacationApproval" $manifest
```
Output summary: package includes SharePoint/Teams/Office connectors, no approvals connector string, and user-bound connection display names.

## Deterministic Risk Evidence

| Risk ID | Severity | Evidence-backed finding | Command(s) | File/Line references |
|---|---|---|---|---|
| R-01 | Critical | `first(GetEmployeeDetails)` used in approval card without explicit empty-result guard. | C3, C4, C5 | `power_automate/extracted/definition_pretty.json:155`; `power_automate/extracted/definition_pretty.json:119`; `.planning/phases/02-power-automate-vacationapproval/02-CONTEXT.md:80`; `.planning/phases/02-power-automate-vacationapproval/02-CONTEXT.md:111` |
| R-02 | Critical | `first(GetCurrentBalance)` used in deduction path without explicit empty-result guard. | C3, C4 | `power_automate/extracted/definition_pretty.json:218`; `power_automate/extracted/definition_pretty.json:220`; `power_automate/extracted/definition_pretty.json:180` |
| R-03 | Critical | Non-atomic sequence: request set to APPROVED before balance read/write. | C3 | `power_automate/extracted/definition_pretty.json:162`; `power_automate/extracted/definition_pretty.json:182`; `power_automate/extracted/definition_pretty.json:204` |
| R-04 | High | Missing update fields required by design (`DataAprovacao`, `DiasAgendados`, `DataAtualizacao`). | C4, C5 | `docs/Flow-Blueprint-VacationApproval.md:151`; `docs/Flow-Blueprint-VacationApproval.md:174`; `docs/Flow-Blueprint-VacationApproval.md:175`; `.planning/phases/02-power-automate-vacationapproval/02-CONTEXT.md:47`; `.planning/phases/02-power-automate-vacationapproval/02-CONTEXT.md:54` |
| R-05 | High | Pending gate checks `body/Status`; context expects `Status/Value`. | C3, C4, C5 | `power_automate/extracted/definition_pretty.json:375`; `.planning/phases/02-power-automate-vacationapproval/02-CONTEXT.md:36` |
| R-06 | High | Approval mechanism drift: Teams card action used; blueprint expects approval action pattern; no approvals connector evidence in package map. | C3, C4, C5, C6 | `power_automate/extracted/definition_pretty.json:149`; `docs/Flow-Blueprint-VacationApproval.md:102`; `.planning/phases/02-power-automate-vacationapproval/02-CONTEXT.md:40`; `power_automate/extracted/Microsoft.Flow/flows/ad33d86f-e6e6-43c3-af32-241263a8a6ce/apisMap.json:1` |
| R-07 | High | Approver identity is sourced from trigger payload field (`AprovadorEmail`) without local validation evidence. | C3 | `power_automate/extracted/definition_pretty.json:80` |
| R-08 | Medium | No explicit timeout/escalation handling found for pending approval wait. | C4 | `power_automate/extracted/definition_pretty.json:149`; `power_automate/extracted/definition_pretty.json:363` |
| R-09 | Medium | Failure alert posture inconsistent: metadata flag true but top-level `flowFailureAlertSubscribed` false. | C3 | `power_automate/extracted/definition_pretty.json:22`; `power_automate/extracted/definition_pretty.json:414` |
| R-10 | Medium | Export contains user-tied connection display names (`mbenicios@minsait.com`), increasing operational coupling risk. | C6 | `power_automate/extracted/manifest.json:1` |
| R-11 | Low | `Title` is mutated with `utcNow()` on approve and reject patch operations. | C3 | `power_automate/extracted/definition_pretty.json:174`; `power_automate/extracted/definition_pretty.json:290` |
| R-12 | Low | Blueprint asks to include `TemConflito` in approval details; payload contains no such field evidence. | C4, C5 | `docs/Flow-Blueprint-VacationApproval.md:119`; `power_automate/extracted/definition_pretty.json:155` |

## Verification Constraints
- No API calls, no cloud/system runtime queries, no flow execution traces were used.
- Evidence is limited to static local artifacts and deterministic text queries shown above.
