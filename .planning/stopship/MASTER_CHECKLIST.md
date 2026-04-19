# SEV-0 Stop-Ship Master Checklist

## Mission Control
| Field | Value |
| --- | --- |
| Release | `VacationApproval Patch Candidate` |
| Target Date/Timezone | `2026-04-18 America/Sao_Paulo` |
| Repo / Branch | `local workspace @ (branch not provided)` |
| Incident Commander | `Codex (SEV-0 mission)` |
| Last Updated (UTC) | `2026-04-18` |

## Hard Release Rule
`NO-SHIP` is mandatory if any gate below is not `GREEN`.

`SHIP` is allowed only when every mandatory gate is `GREEN` and every SEV-0/SEV-1 item is closed with evidence.

## Status Legend
| Status | Meaning |
| --- | --- |
| `GREEN` | Gate passed with linked evidence. |
| `AMBER` | In progress; not yet releasable. |
| `RED` | Failed or missing evidence; release blocked. |
| `N/A` | Not applicable with explicit written justification. |

## Mandatory Quality Gates
| Gate ID | Mandatory Gate | Owner Agent | Status | Evidence Placeholder | Blocking Reason If Not Green |
| --- | --- | --- | --- | --- | --- |
| G1 | All critical issues reproduced, fixed, and proven by automated tests | B, C, D | `GREEN` | `.planning/stopship/evidence/g1_critical_issues.md` | N/A |
| G2 | All tests green in CI (not only local) | E | `RED` | `.planning/stopship/evidence/g2_ci_green.md` | CI parity not proven |
| G3 | Zero known high/critical security findings, or approved exception with compensating controls | E | `RED` | `.planning/stopship/evidence/g3_security.md` | Security risk unresolved |
| G4 | Performance not regressed beyond agreed threshold | D, E | `RED` | `.planning/stopship/evidence/g4_performance.md` | Performance evidence missing |
| G5 | Backward compatibility validated (contracts, schema, migrations) | C, D | `RED` | `.planning/stopship/evidence/g5_backward_compat.md` | Runtime compatibility not validated |
| G6 | Rollback plan documented and tested | A, E | `RED` | `.planning/stopship/evidence/g6_rollback.md` | Rollback drill not executed |
| G7 | RCA package completed per incident-class issue | A, B | `GREEN` | `.planning/stopship/evidence/g7_rca.md` | N/A |

## Critical Issue Tracker
| Issue ID | Severity | Summary | Owner Agent | Status | Evidence Placeholder |
| --- | --- | --- | --- | --- | --- |
| I-001 | SEV-0 | Missing guards and non-atomic approval path in VacationApproval flow | C,D | `CLOSED` | `.planning/stopship/evidence/g1_critical_issues.md` |
| I-002 | SEV-0 | Missing required approval/balance status fields (`DataAprovacao`, `DiasAgendados`, `DataAtualizacao`) | C,D | `CLOSED` | `.planning/stopship/evidence/g1_critical_issues.md` |
| I-003 | SEV-1 | Release gate evidence incomplete (CI/Security/Perf/Rollback/Compat) | A,E | `OPEN` | `.planning/stopship/evidence/` |

## Evidence Log Pointers
| Artifact | Location |
| --- | --- |
| Checklist script output | `scripts/stopship_gate.ps1` console output |
| Risk register | `.planning/stopship/RISK_REGISTER.md` |
| CI evidence bundle | `.planning/stopship/evidence/` |
| RCA package | `.planning/stopship/RCA.md` + `.planning/stopship/EVIDENCE_LOG.md` |

## Release Decision
| Decision | Current Value | Rule |
| --- | --- | --- |
| Release Verdict | `NO-SHIP` | Must remain `NO-SHIP` until G1-G7 are all `GREEN` |
| Blocking Gates | `G2,G3,G4,G5,G6` | Any non-green gate blocks release |
