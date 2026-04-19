# 📋 TASK_PLAN.MD - Implementation Plan (Post-Pivot)
> **Project:** Gestão Férias (Vacation Management)  
> **Architecture:** Power Apps + Power Automate (Standard) + SharePoint  
> **Updated:** 2026-04-18T20:24:00-03:00

---

## 📊 Overall Progress

```
[████████░░░░░░░░░░░░] 40% Complete
```

| Phase | Name | Progress | Status |
|-------|------|----------|--------|
| 1 | SharePoint Infrastructure | 100% | ✅ Complete |
| 2 | Power Automate Flows (2) | 25% | 🟡 In Progress |
| 3 | Power Apps Canvas App (5 screens) | 0% | ⏳ Waiting |
| 4 | Teams Integration | 0% | ⏳ Waiting |
| 5 | Testing & Go-Live | 0% | ⏳ Waiting |

---

## ✅ Phase 1: SharePoint Infrastructure — COMPLETE

- [x] Deploy 6 SharePoint lists
- [x] Import Colaboradores_Aprovadores (13 records)
- [x] Import Feriados (19 records)
- [x] Seed Saldo_Ferias
- [x] Fix Boolean bug in 03-Importar-Dados.ps1

---

## 🟡 Phase 2: Power Automate Flows (Standard License)

> Only 2 flows needed. All other logic lives in Power Apps.

### Flow 1: GestaoFerias_VacationApproval
- [x] Create flow in Power Automate
- [ ] Configure trigger (SharePoint - when item created in Solicitacoes_Ferias)
- [ ] Initialize variables (varApproverEmail, varEmployeeName, etc.)
- [ ] Get approver from Colaboradores_Aprovadores
- [ ] Start and wait for Approval
- [ ] Condition: Approved → update Status, send notifications
- [ ] Condition: Rejected → update Status, send notifications
- [ ] Update Saldo_Ferias on approval
- [ ] Test end-to-end

### Flow 2: GestaoFerias_ScheduledAlerts
- [ ] Create flow with Recurrence trigger (weekly)
- [ ] Query upcoming vacations (next 7 days)
- [ ] Send reminder to employee + manager
- [ ] Query expiring balances
- [ ] Create alert records in Alertas_Ferias
- [ ] Test end-to-end

---

## ⏳ Phase 3: Power Apps Canvas App

### 5 Screens to Build

| Screen | Key Logic | Power Fx |
|--------|-----------|----------|
| Home | Role detection, navigation | `LookUp(Colaboradores_Aprovadores)` |
| New Request | Date validation, conflict check, submit | `Patch()`, `Filter()`, business rules |
| My Requests | View/cancel own requests | `Filter()`, `Patch()` for cancel |
| Approvals (Manager) | Approve/reject with reason | `Patch()` to update Status |
| Team Calendar | Visual team vacation view | `Filter()` by department + dates |

---

## ⏳ Phase 4: Teams Integration

- [ ] Publish Power App
- [ ] Add as Teams tab/personal app
- [ ] Test SSO with `User()` function

---

## ⏳ Phase 5: Testing & Go-Live

- [ ] E2E test: employee submits → manager approves → balance updated
- [ ] E2E test: conflict detection
- [ ] E2E test: scheduled alerts
- [ ] User acceptance testing

---

> 📌 **Current Focus:** Complete VacationApproval flow in Power Automate
