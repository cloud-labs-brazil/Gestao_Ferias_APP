# Gestão Férias — Task Tracker
> **Updated:** 2026-04-19T16:35:00-03:00  
> **Architecture:** Power Apps + Power Automate (2 flows) + SharePoint (6 lists)

## Status Geral: ~33% Concluído (3 of 9 phases done)

```
[███████░░░░░░░░░░░░░] 33%
```

> **Decision (2026-04-19):** HTML Dashboard (Phase 4A/4B) DROPPED — Power Apps "Aplicativo" is the sole frontend. Dashboard files kept in repo for reference but will NOT be deployed.

---

### ✅ Phase 1: Data Seeding & Infrastructure (COMPLETE)

- [x] Deploy 6 SharePoint lists
- [x] Import 13 employees to Colaboradores_Aprovadores
- [x] Import 19 holidays to Feriados
- [x] Seed Saldo_Ferias (30 days per employee)
- [x] Fix Boolean bug in 03-Importar-Dados.ps1
- [x] Create 05-Seed-Saldo-Ferias.ps1

### ✅ Phase 2: VacationApproval Flow (COMPLETE — E2E Verified)

- [x] Task 01: Create Flow + Configure Trigger
- [x] Task 02: Initialize 3 Variables (varApproverEmail, varEmployeeEmail, varRequestId)
- [x] Task 03: Get Employee Details (GetEmployeeDetails)
- [x] Task 04: Status Guard Condition (PENDING check)
- [x] Task 05: Approval Action (Start and wait for an approval)
- [x] Task 06: Approval Outcome Condition
- [x] Task 07: Approved Path — Update Status + Deduct Balance
- [x] Task 08: Approved Path — Notify Employee (Teams + Email)
- [x] Task 09: Rejected Path — Update Status + Notify
- [x] Task 10: End-to-End Testing ✅ Verified 2026-04-18

### ✅ Phase 3: ScheduledAlerts Flow (COMPLETE — E2E Verified)

- [x] Build weekly recurrence flow
- [x] Balance expiration detection (30/60/90 days)
- [x] Upcoming vacation reminders (7 days)
- [x] Alert record creation in Alertas_Ferias
- [x] E2E verified: recurrence → filter expiring balances → create alert items

### ~~Phase 4A/4B: HTML Dashboard~~ ❌ DROPPED

> Dashboard dropped per user decision (2026-04-19). Power Apps "Aplicativo" Canvas App is sufficient as the sole frontend. Files remain in `GestaoFerias-Dashboard/` for reference only.

### ⏳ Phase 4: Power Apps — Connect "Aplicativo" to SP (NEXT)

- [ ] Open "Aplicativo" Canvas App in edit mode
- [ ] Connect 6 SharePoint data sources
- [ ] Role detection (employee vs manager via Colaboradores_Aprovadores)
- [ ] Build Home screen (balance card, pending count, manager stats)
- [ ] Navigation (role-based show/hide)
- [ ] Publish Canvas App

### ⏳ Phase 5: Power Apps — New Request Screen (NOT STARTED)

- [ ] Date pickers + form layout
- [ ] BR-001/002/003 validation (45 days, 5-30 days)
- [ ] Balance validation
- [ ] Conflict detection
- [ ] Submit → Patch() to Solicitacoes_Ferias

### ⏳ Phase 6: Power Apps — My Requests (NOT STARTED)

- [ ] Request gallery (sorted by date)
- [ ] Status badges (color-coded)
- [ ] Cancel button (PENDING only)

### ⏳ Phase 7: Power Apps — Manager Approvals (NOT STARTED)

- [ ] Role guard (manager only)
- [ ] Pending requests gallery
- [ ] Approve/Reject actions

### ⏳ Phase 8: Power Apps — Team Calendar (NOT STARTED)

- [ ] Manager-only calendar view
- [ ] Month navigation
- [ ] Team coverage indicator

### ⏳ Phase 9: Teams Integration + Acceptance (NOT STARTED)

- [ ] Embed Canvas App as tab in Teams
- [ ] 12 acceptance criteria validation (V1-V12)

---

## 📌 IMMEDIATE NEXT STEP

1. **Phase 4:** Connect "Aplicativo" Canvas App to 6 SP lists + build Home screen
