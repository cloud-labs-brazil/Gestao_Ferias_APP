# Gestão Férias — Task Tracker
> **Updated:** 2026-04-18T20:58:00-03:00  
> **Architecture:** Power Apps + Power Automate (2 flows) + SharePoint (6 lists)

## Status Geral: ~25% Concluído

```
[█████░░░░░░░░░░░░░░░] 25%
```

---

### ✅ Phase 1: Data Seeding & Infrastructure (100%)

- [x] Deploy 6 SharePoint lists
- [x] Import 13 employees to Colaboradores_Aprovadores
- [x] Import 19 holidays to Feriados
- [x] Seed Saldo_Ferias (30 days per employee)
- [x] Fix Boolean bug in 03-Importar-Dados.ps1
- [x] Create 05-Seed-Saldo-Ferias.ps1

### 🟡 Phase 2: VacationApproval Flow (90% — needs verification)

- [x] Task 01: Create Flow + Configure Trigger
- [x] Task 02: Initialize 3 Variables (varApproverEmail, varEmployeeEmail, varRequestId)
- [x] Task 03: Get Employee Details (GetEmployeeDetails)
- [x] Task 04: Status Guard Condition (PENDING check)
- [x] Task 05: Approval Action (Start and wait for an approval)
- [x] Task 06: Approval Outcome Condition
- [x] Task 07: Approved Path — Update Status + Deduct Balance
- [x] Task 08: Approved Path — Notify Employee (Teams + Email)
- [x] Task 09: Rejected Path — Update Status + Notify
- [ ] **Task 10: End-to-End Testing** ⚠️ BROWSER EXPIRED — needs re-verification
- [ ] **BLOCKER:** Must visually confirm flow structure in PA editor before testing

### ⏳ Phase 3: ScheduledAlerts Flow (0%)

- [ ] Build weekly recurrence flow
- [ ] Balance expiration detection (30/60/90 days)
- [ ] Upcoming vacation reminders (7 days)
- [ ] Alert record creation in Alertas_Ferias
- [ ] PT-BR notifications

### ⏳ Phase 4: Power Apps — Home Screen (0%)

- [ ] Create Canvas App with Modern Controls
- [ ] Connect 6 SharePoint data sources
- [ ] Role detection (employee vs manager)
- [ ] Balance card (saldo, período aquisitivo, vencimento)
- [ ] Pending requests count
- [ ] Manager quick stats
- [ ] Navigation (role-based)

### ⏳ Phase 5: Power Apps — New Request Screen (0%)

- [ ] Date pickers + form layout
- [ ] BR-001/002/003 validation (45 days, 5-30 days)
- [ ] Balance validation
- [ ] Conflict detection
- [ ] CLT fracionamento validation
- [ ] Submit → Patch() to Solicitacoes_Ferias

### ⏳ Phase 6: Power Apps — My Requests (0%)

- [ ] Request gallery (sorted by date)
- [ ] Status badges (color-coded)
- [ ] Cancel button (PENDING only)

### ⏳ Phase 7: Power Apps — Manager Approvals (0%)

- [ ] Role guard (manager only)
- [ ] Pending requests gallery
- [ ] Approve/Reject actions

### ⏳ Phase 8: Power Apps — Team Calendar (0%)

- [ ] Manager-only calendar view
- [ ] Month navigation
- [ ] Team coverage indicator

### ⏳ Phase 9: Teams Integration + Acceptance (0%)

- [ ] Embed in Teams
- [ ] 12 acceptance criteria validation

---

## 📌 IMMEDIATE NEXT STEP

1. Open VacationApproval flow in PA editor
2. Verify all 9 tasks are intact
3. Run E2E test (Task 10)
4. Mark Phase 2 complete
5. Start Phase 3 (ScheduledAlerts) or Phase 4 (Power Apps)
