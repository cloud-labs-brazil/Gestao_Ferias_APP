# G1 - Critical Issues Reproduced, Fixed, and Proven
Gate-Status: GREEN

## Scope
VacationApproval flow SEV-0 invariants (employee guard, status condition robustness, balance fields, approval ordering, DataAprovacao stamping, failure alert subscription).

## Reproduction (Before)
- Command:
```powershell
$env:FLOW_DEFINITION_PATH='C:\VMs\Projects\Copilot_Studio_Config\power_automate\extracted\Microsoft.Flow\flows\ad33d86f-e6e6-43c3-af32-241263a8a6ce\definition.json'
node --test tests/flow/*.test.js
```
- Exit code: `1`
- Evidence log: `.planning/stopship/evidence/g1_tests_before.log`

## Fix Applied
- Patched source definition:
  - `flows/VacationApproval_Definition.json`
- Reproducible patcher:
  - `scripts/patch_vacationapproval_flow.py`
- Patched import package:
  - `power_automate/Export_Gestao_Ferias_20260418190548_patched.zip`

## Verification (After)
- Command (source definition):
```powershell
$env:FLOW_DEFINITION_PATH='C:\VMs\Projects\Copilot_Studio_Config\flows\VacationApproval_Definition.json'
node --test tests/flow/*.test.js
```
- Exit code: `0`
- Evidence log: `.planning/stopship/evidence/g1_tests_after.log`

- Command (patched zip definition extracted):
```powershell
$env:FLOW_DEFINITION_PATH='C:\VMs\Projects\Copilot_Studio_Config\.tmp\patched_zip_verify\Microsoft.Flow\flows\ad33d86f-e6e6-43c3-af32-241263a8a6ce\definition.json'
node --test tests/flow/*.test.js
```
- Exit code: `0`

## Artifact Integrity
- Original zip SHA256: `D9E8D47D81E30E95B3FED320DFD01A99CDEF33A39C642B04811557BE8A2DBDAF`
- Patched zip SHA256: `4ADC3E1D2BCC80417B8DA50B57D3E57BD6D66D56F9ED7A2292711ED6384F2086`
