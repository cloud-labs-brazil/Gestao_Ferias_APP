# Phase 1: Data Seeding & Infrastructure Validation - Context

**Gathered:** 2026-04-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Seed the Saldo_Ferias SharePoint list with simulated vacation balances for all 13 test employees, and verify all 6 SharePoint lists are healthy and accessible. This is prerequisite infrastructure for all subsequent phases.

**Important context:** All data is SIMULATED. We don't know which real employees are eligible for vacation (requires completed 12-month acquisition period per CLT). The 13 employees in Colaboradores_Aprovadores and their balances are test data for development and testing purposes only. Real HR data would replace this at production time.

</domain>

<decisions>
## Implementation Decisions

### Data Seeding Approach
- **D-01:** Use existing `05-Seed-Saldo-Ferias.ps1` script — it reads all active employees from Colaboradores_Aprovadores and creates one Saldo_Ferias record per employee with 30 days balance
- **D-02:** Default simulated balance: 30 days per employee (standard CLT entitlement)
- **D-03:** Reference year: 2026 (current year)
- **D-04:** Script is idempotent — skips employees who already have balance records
- **D-05:** All data is simulated/test data — not real eligibility data

### Verification Approach
- **D-06:** After seeding, verify Saldo_Ferias has exactly 13 records (matching active employee count)
- **D-07:** Verify all 6 SharePoint lists are accessible: Colaboradores_Aprovadores, Solicitacoes_Ferias, Historico_Ferias, Saldo_Ferias, Feriados, Alertas_Ferias
- **D-08:** No data transformation needed — script handles column mapping directly

### Agent's Discretion
- Período aquisitivo date formatting (script uses hire date if available, else Jan 1 - Dec 31)
- Data_Vencimento calculation (script handles this)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### SharePoint Infrastructure
- `gemini.md` §3 — SharePoint list schemas (all 6 lists), column types, required fields
- `docs/ADR-001-Architecture-Pivot.md` — Architecture decision: Power Apps + SharePoint + Power Automate (Standard only)

### Deployment Scripts
- `05-Seed-Saldo-Ferias.ps1` — The seed script to execute (170 lines, ready to run)
- `03-Importar-Dados.ps1` — Pre-requisite: employee data import (must have run successfully before Phase 1)
- `02-Deploy-Listas.ps1` — Pre-requisite: list creation (must have run successfully)

### Data Source
- `Users_Approvers.xlsx` — Source employee/manager mapping (13 records)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `05-Seed-Saldo-Ferias.ps1`: Complete, tested seed script — just needs execution
- `02-Deploy-Listas.ps1`: Already deployed all 6 lists
- `03-Importar-Dados.ps1`: Already imported 13 employees + 19 holidays

### Established Patterns
- PnP.PowerShell for all SharePoint operations
- `Connect-PnPOnline -UseWebLogin` for authentication
- Idempotent scripts (skip-if-exists logic)

### Integration Points
- Saldo_Ferias list connects to Power Apps Home screen (Phase 4) for balance display
- Saldo_Ferias is deducted by VacationApproval flow (Phase 2) on approval
- ColaboradorEmail is the foreign key linking Saldo_Ferias → Colaboradores_Aprovadores

</code_context>

<specifics>
## Specific Ideas

- User confirmed this is simulation data — no real eligibility determination needed
- Script should be validated by checking record count matches employee count
- All 6 lists must be verified accessible before moving to Phase 2+

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-data-seeding-infrastructure-validation*
*Context gathered: 2026-04-14*
