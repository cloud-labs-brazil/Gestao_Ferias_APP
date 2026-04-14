# Gestão Férias — MVP Roadmap

> **Milestone:** M1 — MVP (Working Vacation App in Teams)  
> **Started:** 2026-04-14  
> **Target:** Production-ready vacation management for 13 employees

---

## Phase 1: Data Seeding & Infrastructure Validation
> Seed Saldo_Ferias for all 13 employees and verify SharePoint list health

**UAT:**
- [ ] Saldo_Ferias has exactly 13 records (one per employee)
- [ ] Each record has correct Saldo_Dias (30), Periodo_Aquisitivo, Data_Vencimento
- [ ] All 6 SharePoint lists accessible via Power Apps data connector

**Depends on:** Nothing (starting point)

---

## Phase 2: Power Automate Flow — VacationApproval
> Build Flow 1 (VacationApproval) following docs/Flow-Blueprint-VacationApproval.md

**UAT:**
- [ ] Flow triggers on item creation in Solicitacoes_Ferias
- [ ] Approval request sent to correct manager via Teams Approvals center
- [ ] On approval: Status=APPROVED, Saldo_Ferias deducted, employee notified (Teams + Email)
- [ ] On rejection: Status=REJECTED, employee notified with reason
- [ ] All notifications in PT-BR

**Depends on:** Phase 1

---

## Phase 3: Power Automate Flow — ScheduledAlerts
> Build Flow 2 (ScheduledAlerts) following docs/Flow-Blueprint-ScheduledAlerts.md

**UAT:**
- [ ] Flow runs on weekly recurrence schedule
- [ ] Detects balances expiring within 30/60/90 days
- [ ] Detects upcoming vacations within 7 days
- [ ] Creates alert records in Alertas_Ferias list
- [ ] Sends reminder notifications in PT-BR

**Depends on:** Phase 1

---

## Phase 4: Power Apps — Create App + Home Screen
> Create Canvas App with Modern Controls, connect all 6 SP lists, build Home screen

**UAT:**
- [ ] Canvas App created with Modern Controls + Fluent 2 theme enabled
- [ ] All 6 SharePoint lists connected as data sources
- [ ] App.OnStart: role detection (employee vs manager) works correctly
- [ ] Home screen shows balance card (saldo, período aquisitivo, vencimento)
- [ ] Home screen shows pending requests count
- [ ] Manager sees quick stats: pending approvals count, team members on vacation
- [ ] Navigation shows/hides manager-only screens based on role
- [ ] 100% PT-BR labels and text

**Depends on:** Phase 1

---

## Phase 5: Power Apps — New Request Screen
> Build request submission form with full CLT validation + conflict detection

**UAT:**
- [ ] Date pickers for start/end date work correctly
- [ ] BR-001: Rejects requests with < 45 days advance notice
- [ ] BR-002: Rejects requests with < 5 days duration
- [ ] BR-003: Rejects requests with > 30 days duration
- [ ] Balance validation: blocks if requested days > saldo disponível
- [ ] CLT fracionamento: validates 1 period ≥ 14 days, others ≥ 5 days, max 3 periods
- [ ] Conflict detection: shows team overlap warnings before submission
- [ ] Abono pecuniário: option to sell up to 10 days (1/3 of entitlement)
- [ ] Submit creates item in Solicitacoes_Ferias (triggers Flow 1)
- [ ] All validation messages in PT-BR

**Depends on:** Phase 4

---

## Phase 6: Power Apps — My Requests + Cancel
> Build request history screen with status tracking and cancel functionality

**UAT:**
- [ ] Gallery shows all user's requests sorted by creation date (newest first)
- [ ] Each request shows: dates, total days, status badge (color-coded)
- [ ] Cancel button visible only for PENDING requests
- [ ] Cancel action updates Status to CANCELLED
- [ ] Status colors: Pending=Orange, Approved=Green, Rejected=Red, Cancelled=Gray
- [ ] All text in PT-BR

**Depends on:** Phase 4

---

## Phase 7: Power Apps — Manager Approval Screen
> Build approval interface for managers with approve/reject actions

**UAT:**
- [ ] Screen only accessible to managers (role guard)
- [ ] Gallery shows pending requests for manager's team
- [ ] Each request shows: employee name, dates, total days, conflict flag
- [ ] Approve button: updates status, deducts saldo, notifies employee
- [ ] Reject button: requires reason text, updates status, notifies employee
- [ ] All text in PT-BR

**Depends on:** Phase 4, Phase 2

---

## Phase 8: Power Apps — Team Calendar (Manager)
> Build team calendar view for managers to see team vacation schedule

**UAT:**
- [ ] Screen only accessible to managers
- [ ] Shows approved vacations for current month (gallery/visual)
- [ ] Month navigation (forward/backward)
- [ ] Team coverage indicator (% available)
- [ ] Shows employee name + date range for each vacation
- [ ] All text in PT-BR

**Depends on:** Phase 4

---

## Phase 9: Teams Integration + Acceptance Testing
> Embed Power App in Teams and validate all 12 acceptance criteria

**UAT:**
- [ ] V1: Employee can see vacation balance in Home screen
- [ ] V2: Employee can submit a vacation request
- [ ] V3: Request with < 45 days notice is rejected (form validation)
- [ ] V4: Request exceeding balance is rejected (form validation)
- [ ] V5: Conflict detection warns on team overlap
- [ ] V6: Manager receives approval request in Teams Approvals center
- [ ] V7: Manager approval updates status to APPROVED
- [ ] V8: Manager rejection with reason updates status to REJECTED
- [ ] V9: Employee notified on approval/rejection (Teams + Email)
- [ ] V10: Employee can cancel pending request
- [ ] V11: Balance updates after approval (Saldo deducted)
- [ ] V12: App works inside Teams as tab

**Depends on:** All previous phases
