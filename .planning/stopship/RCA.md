# Blameless RCA - VacationApproval Stop-Ship

Date: 2026-04-18  
Scope: Local static analysis only (no external systems)  
Decision posture: Stop-Ship until corrective actions are implemented and verified

## Timeline
1. 2026-04-18T18:00:41.0946142Z - Flow definition last modified (`clientLastModifiedTime`).  
Evidence: `power_automate/extracted/definition_pretty.json:23`
2. 2026-04-18T19:05:47.9571324Z - Export package created (`createdTime`).  
Evidence: `power_automate/extracted/manifest.json:1`
3. 2026-04-18T16:51:13.6151583-03:00 - Local forensic review executed with deterministic commands (`rg`, `Get-FileHash`, file inventory).  
Evidence: command transcript captured in `.planning/stopship/EVIDENCE_LOG.md`

## Impact
- Runtime reliability risk: expressions using `first(...)` can fail when source arrays are empty.
- Data integrity risk: request can be marked `APPROVED` before balance deduction succeeds.
- Process/audit risk: implementation diverges from documented approval and field update requirements.
- Security/governance risk: approver route is sourced from trigger payload value without local validation evidence.
- Operational risk: user-bound connection references and disabled top-level failure alerts reduce resilience.

## Root Causes
1. Defensive checks for empty query results were not consistently implemented before `first(...)` usage.  
Evidence: `power_automate/extracted/definition_pretty.json:155`, `power_automate/extracted/definition_pretty.json:218`, plus no-match guard evidence in `.planning/stopship/EVIDENCE_LOG.md`.
2. Approval branch sequencing is not transactional; status update occurs before balance update dependency chain completes.  
Evidence: `power_automate/extracted/definition_pretty.json:162`, `power_automate/extracted/definition_pretty.json:182`, `power_automate/extracted/definition_pretty.json:204`.
3. Specification drift between implementation and blueprint/context requirements.  
Evidence: `docs/Flow-Blueprint-VacationApproval.md:102`, `docs/Flow-Blueprint-VacationApproval.md:151`, `docs/Flow-Blueprint-VacationApproval.md:174`, `docs/Flow-Blueprint-VacationApproval.md:175`, `.planning/phases/02-power-automate-vacationapproval/02-CONTEXT.md:36`, `.planning/phases/02-power-automate-vacationapproval/02-CONTEXT.md:40`.
4. Trust boundary not enforced for approver identity source.  
Evidence: `power_automate/extracted/definition_pretty.json:80`.
5. Operational hardening controls (timeouts/escalation/alert subscriptions) are incomplete.  
Evidence: `power_automate/extracted/definition_pretty.json:149`, `power_automate/extracted/definition_pretty.json:414`, no-match timeout evidence in `.planning/stopship/EVIDENCE_LOG.md`.

## Contributing Factors
- JSON package shape makes reviews harder (large embedded strings and minimal structural guard checks).
- Local documentation indicates expected controls, but package export shows partial implementation.
- Connection packaging tied to a personal identity increases fragility during environment migration.
- No local evidence of automated static policy gates to enforce required action patterns before export/import.

## Corrective Actions
1. Add explicit guard conditions before any `first(outputs(...)?['body/value'])` usage for employee and balance lookups.
2. Reorder approval path or add compensating transaction logic so status is not persisted as `APPROVED` unless balance update succeeds.
3. Implement mandatory field updates per design (`DataAprovacao`, `DiasAgendados`, `DataAtualizacao`) and validate field internal names.
4. Align approval mechanism with agreed architecture and ensure connector set matches design intent.
5. Harden approver resolution by deriving approver from authoritative source, not request payload alone.
6. Add explicit timeout/escalation branch for pending approvals and verify failure alert subscription behavior.
7. Replace personal connections with controlled service identity where environment policy requires it.
8. Introduce static pre-export gate checks (scripted) for required expressions/fields/actions.

## Release Readiness (Current State)
- Status: **NO-SHIP**
- Blocking reasons:
  - Critical integrity/reliability risks (empty-array `first(...)`, non-atomic approval flow).
  - High-severity design drift from required workflow semantics and audit fields.
  - Missing hardening controls needed for operational safety.
