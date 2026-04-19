# SEV-0 Stop-Ship Risk Register

## Rule Binding
This register is release-binding. Any `OPEN` or `ACCEPTED_WITH_CONTROLS` risk rated High/Critical keeps verdict at `NO-SHIP` unless explicitly approved with compensating controls and linked evidence.

## Scale
| Field | Values |
| --- | --- |
| Severity | `Low`, `Medium`, `High`, `Critical` |
| Probability | `Low`, `Medium`, `High` |
| Status | `OPEN`, `MITIGATING`, `MONITORING`, `CLOSED`, `ACCEPTED_WITH_CONTROLS` |

## Active Risks
| Risk ID | Area | Risk Statement | Severity | Probability | Owner Agent | Mitigation Plan | Rollback / Contingency | Status | Evidence Placeholder |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R-001 | Data Integrity | Approval path can commit partial state under failure paths. | `Critical` | `Medium` | C | Enforce transactional sequencing, add failure guards, add regression tests. | Revert to last known good flow package and reprocess impacted items. | `MITIGATING` | `.planning/stopship/evidence/g1_critical_issues.md` |
| R-002 | Validation | Missing guard clauses for null/empty lookup results can hard-fail runs. | `High` | `High` | C, D | Add explicit preconditions and deterministic fallback branch tests. | Disable affected trigger and process queue manually with approved script. | `MITIGATING` | `.planning/stopship/evidence/g1_critical_issues.md` |
| R-003 | Security | Approval routing can be overridden by untrusted requester-supplied fields. | `Critical` | `Medium` | C, E | Resolve approver from authoritative source and validate permissions. | Switch to controlled approval channel and audit pending items. | `OPEN` | `.planning/stopship/evidence/g3_security.md` |
| R-004 | Operational | CI parity is not proven for release candidate branch. | `High` | `Medium` | E | Lock deterministic pipeline steps and publish signed artifacts. | Freeze release; run rollback drill and restore baseline package. | `OPEN` | `.planning/stopship/evidence/g2_ci_green.md` |
| R-005 | Performance | Approval and list update latency may exceed accepted threshold after fixes. | `Medium` | `Medium` | D, E | Baseline and compare p95 latency; set fail threshold in pipeline. | Roll back performance-sensitive change set behind feature flag. | `OPEN` | `.planning/stopship/evidence/g4_performance.md` |
| R-006 | Recovery | Rollback procedure is undocumented or untested in current cycle. | `High` | `Medium` | A, E | Create runbook and execute rollback simulation with timestamps. | Block release until drill proves RTO/RPO targets. | `OPEN` | `.planning/stopship/evidence/g6_rollback.md` |

## Closed Risks
| Risk ID | Closure Date (UTC) | Closure Evidence | Approver |
| --- | --- | --- | --- |
| `<R-XXX>` | `<YYYY-MM-DD HH:mm>` | `<link/path>` | `<name>` |

## Decision Coupling
| Condition | Required Verdict |
| --- | --- |
| Any Critical risk not `CLOSED` | `NO-SHIP` |
| Any High risk `OPEN` without approved controls | `NO-SHIP` |
| All High/Critical risks closed or approved with evidence | Candidate for `SHIP` (subject to all checklist gates green) |
