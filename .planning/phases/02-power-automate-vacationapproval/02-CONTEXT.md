# Phase 2: Power Automate Flow — VacationApproval - Context

**Gathered:** 2026-04-14
**Status:** Ready for planning
**Source:** Blueprint docs/Flow-Blueprint-VacationApproval.md

<domain>
## Phase Boundary

Build the VacationApproval Power Automate flow that handles the full approval lifecycle when an employee submits a vacation request. The flow triggers on item creation in Solicitacoes_Ferias, routes an approval to the manager, and on approval/rejection updates the request status, adjusts balance, and notifies the employee via Teams + Email. All using Standard license connectors only.

</domain>

<decisions>
## Implementation Decisions

### Flow Identity
- **D-01:** Flow name: `GestaoFerias_VacationApproval`
- **D-02:** Type: Automated cloud flow
- **D-03:** Connectors: SharePoint, Approvals, Office 365 Outlook, Microsoft Teams (all Standard)

### Trigger
- **D-04:** Trigger: "When an item is created" (SharePoint) on `Solicitacoes_Ferias` list
- **D-05:** Site Address: `https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA`
- **D-06:** MUST use "item created" trigger (not "created or modified") to prevent re-triggering on status updates

### Variables
- **D-07:** Initialize 3 variables: `varApproverEmail`, `varEmployeeEmail`, `varRequestId`
- **D-08:** All sourced from trigger outputs

### Employee Lookup
- **D-09:** Get employee details from `Colaboradores_Aprovadores` filtered by Email
- **D-10:** Action renamed to `GetEmployeeDetails`

### Status Guard
- **D-11:** Condition: check if `Status/Value` equals `PENDING` before proceeding
- **D-12:** If not PENDING → Terminate with Succeeded status (safety guard)

### Approval
- **D-13:** Approval Type: `Approve/Reject - First to respond`
- **D-14:** Title in PT-BR: `Solicitação de Férias - {employee_name}`
- **D-15:** Details include: Colaborador, Período (dd/MM/yyyy), Total de dias, Conflito flag, Observações
- **D-16:** Item link points to SharePoint DispForm for the request
- **D-17:** Action renamed to `ApprovalAction`

### Approval Path (Approved)
- **D-18:** Update Solicitacoes_Ferias: Status → APPROVED, Data_Aprovacao → utcNow()
- **D-19:** Get current balance from Saldo_Ferias (filter by ColaboradorEmail)
- **D-20:** Deduct: SaldoDisponivel = current - Total_Dias; DiasAgendados = current + Total_Dias
- **D-21:** Notify employee via Teams (Flow bot chat) — approval message in PT-BR with ✅
- **D-22:** Notify employee via Email (Office 365 Outlook) — same content with HTML

### Rejection Path (Rejected)
- **D-23:** Update Solicitacoes_Ferias: Status → REJECTED, Data_Aprovacao → utcNow()
- **D-24:** Notify employee via Teams — rejection message in PT-BR with ❌ including manager's comments/reason
- **D-25:** Notify employee via Email — same content with HTML

### Language
- **D-26:** All notification text, approval title, details MUST be in PT-BR
- **D-27:** Date format: dd/MM/yyyy throughout

### Column Name Mapping (CRITICAL — resolved 2026-04-18)
The deployed SharePoint columns (from 02-Deploy-Listas.ps1) use camelCase without underscores. 
The gemini.md schema uses underscored names. Blueprint was updated to match ACTUAL deployed columns:

| gemini.md Name | Actual Deployed Column | List |
|---|---|---|
| Email_Colaborador | ColaboradorEmail | Solicitacoes_Ferias |
| Email_Aprovador | AprovadorEmail | Solicitacoes_Ferias |
| Data_Inicio | DataInicio | Solicitacoes_Ferias |
| Data_Fim | DataFim | Solicitacoes_Ferias |
| Total_Dias | DiasUteis | Solicitacoes_Ferias |
| Data_Aprovacao | DataAprovacao | Solicitacoes_Ferias |
| Tem_Conflito | TemConflito | Solicitacoes_Ferias (added via 06-Add-TemConflito-Column.ps1) |
| Saldo_Dias | SaldoDisponivel | Saldo_Ferias |
| Nome | NomeCompleto | Colaboradores_Aprovadores |
| Email_Gestor | AprovadorEmail | Colaboradores_Aprovadores |

### Error Handling (resolved 2026-04-18)
- **D-28:** Explicit guard: Check Employee Found condition with Terminate on "Se não" ✅ (already built)
- **D-29:** No balance negativity guard — Power Apps enforces BR rules client-side before submitting

### Agent's Discretion
- Email HTML styling choices

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Flow Blueprint (PRIMARY)
- `docs/Flow-Blueprint-VacationApproval.md` — Complete step-by-step build instructions with exact expressions, field mappings, and HTML templates

### SharePoint Infrastructure
- `gemini.md` §3 — SharePoint list schemas (Solicitacoes_Ferias, Saldo_Ferias, Colaboradores_Aprovadores)
- `docs/ADR-001-Architecture-Pivot.md` — Architecture decision: Standard license only

### Integration Points
- `docs/PowerApps-Formula-Reference.md` — How Power Apps creates items that trigger this flow

</canonical_refs>

<specifics>
## Specific Ideas

- Blueprint provides exact Power Automate expressions for every field — follow them precisely
- The flow is built interactively in make.powerautomate.com browser UI — agent will guide user through steps
- Testing requires creating a test item in Solicitacoes_Ferias with Status=PENDING
- Common issue: `first()` expression errors if GetEmployeeDetails returns 0 items — add guard

</specifics>

<deferred>
## Deferred Ideas

None — blueprint covers complete flow scope

</deferred>

---

*Phase: 02-power-automate-vacationapproval*
*Context gathered: 2026-04-14 from Flow Blueprint*
