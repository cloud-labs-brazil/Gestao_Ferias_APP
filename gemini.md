# 🧠 GEMINI.MD - Project Constitution
> **Gestão Férias** - Power Apps + SharePoint + Power Automate  
> **Status:** EXECUTION PHASE (MVP)  
> **Last Updated:** 2026-04-13T19:05:00-03:00

---

## 📋 Table of Contents

1. [Project Identity](#project-identity)
2. [B.L.A.S.T. Discovery Answers](#blast-discovery-answers)
3. [Data Schemas](#data-schemas)
4. [Behavioral Rules](#behavioral-rules)
5. [Architectural Invariants](#architectural-invariants)
6. [Integration Endpoints](#integration-endpoints)
7. [Maintenance Log](#maintenance-log)

---

## 1. Project Identity

| Property | Value |
|----------|-------|
| **Project Name** | Gestão Férias (Vacation Management) |
| **Platform** | Power Apps (Canvas) + Power Automate |
| **Backend** | SharePoint Online Lists (6) |
| **Frontend** | Power Apps Canvas App in Teams |
| **Target Users** | Employees + Managers (Minsait/Indra) |
| **Tenant** | `indra365.sharepoint.com` |
| **Admin Account** | `mbenicios@minsait.com` |
| **Power Platform Env** | `ColOfertasBrasilPro` |
| **Dataverse URL** | `https://colofertasbrasilpro.crm4.dynamics.com/` |

---

## 2. B.L.A.S.T. Discovery Answers

### 🎯 North Star
**What is the singular desired outcome?**
> A functional vacation management app embedded in Teams that enables:
> - Employees: query balance, submit requests (with conflict detection), track status
> - Managers: approve/reject requests, view team calendar, track team vacations
> - System: automated notifications, balance updates, audit history

### 🔗 Integrations
**Which external services do we need? Are keys ready?**

| Service | Purpose | Status | Notes |
|---------|---------|--------|-------|
| SharePoint Online | Data storage (6 lists) | ✅ deployed | 6 lists, 32 records |
| Power Automate | Business logic (2 flows) | ⏳ pending | Standard license only (no Premium) |
| Power Apps | Canvas App (5 screens) | ⏳ pending | Primary UI for employees + managers |
| Microsoft Teams | Delivery channel + App host | ⏳ pending | Power App embedded as Teams tab |
| Copilot Studio | Phase 2 Q&A assistant | 🔵 deferred | Read-only queries only |
| PnP.PowerShell | Deployment automation | ✅ installed | v2.12/3.x |

### 📦 Source of Truth
**Where does the primary data live?**

```
SharePoint Site: indra365.sharepoint.com
├── 📋 Colaboradores_Aprovadores   → Employee/Manager mapping
├── 📋 Solicitacoes_Ferias         → Active requests
├── 📋 Historico_Ferias            → Past vacations
├── 📋 Saldo_Ferias                → Balance per employee
├── 📋 Feriados                    → Company holidays
└── 📋 Alertas_Ferias              → Proactive alerts
```

### 📤 Delivery Payload
**How and where should the final result be delivered?**

| Payload | Destination | Format |
|---------|-------------|--------|
| Vacation App | Microsoft Teams Tab | Power Apps Canvas App |
| Approval Requests | Teams Approval Center | Approvals connector |
| Status Notifications | Teams + Email | Power Automate notifications |
| Manager Dashboard | Power App (manager view) | Canvas App screen |

### 📜 Behavioral Rules
**How should the system "act"?**

| Rule ID | Rule | Enforcement |
|---------|------|-------------|
| BR-001 | Minimum 45 days advance notice for requests | ✅ Confirmed |
| BR-002 | Minimum 5 days per request | ✅ Confirmed (2026-01-25) |
| BR-003 | Maximum 30 days per request | ✅ Confirmed (2026-01-25) |
| BR-004 | No RH handoff (self-service model) | ✅ Confirmed |
| BR-005 | Conflict detection is MANDATORY before submission | ✅ Confirmed |
| BR-006 | All notifications via Teams AND Email | ✅ Confirmed |
| BR-007 | No blackout periods | ✅ Confirmed (2026-01-25) |
| BR-008 | Power Automate Standard license only (no Premium) | ✅ Confirmed (2026-04-13) |

---

## 3. Data Schemas

### 3.1 INPUT: Vacation Request Payload

```json
{
  "employee_email": "string (required)",
  "start_date": "date ISO-8601 (required)",
  "end_date": "date ISO-8601 (required)",
  "has_conflict": "boolean (auto-detected)",
  "conflicting_employees": ["string[]"],
  "notes": "string (optional)",
  "request_type": "enum: NEW | CHANGE | CANCEL"
}
```

### 3.2 OUTPUT: Request Creation Response

```json
{
  "request_id": "string (GUID)",
  "status": "enum: PENDING | APPROVED | REJECTED | CANCELLED",
  "approver_email": "string",
  "approver_name": "string",
  "created_at": "datetime ISO-8601",
  "message": "string"
}
```

### 3.3 OUTPUT: Balance Query Response

```json
{
  "employee_email": "string",
  "employee_name": "string",
  "available_days": "integer",
  "acquisition_period": "string (DD/MM/YYYY - DD/MM/YYYY)",
  "expiration_date": "date ISO-8601"
}
```

### 3.4 OUTPUT: Conflict Check Response

```json
{
  "has_conflict": "boolean",
  "conflicting_employees": [
    {
      "name": "string",
      "email": "string",
      "period": "string (DD/MM - DD/MM)"
    }
  ],
  "team_coverage_percentage": "number (0-100)"
}
```

### 3.5 SharePoint List Schemas

#### Colaboradores_Aprovadores
| Column | Type | Required | Description |
|--------|------|----------|-------------|
| Email | Text | Yes | Employee email (unique) |
| Nome | Text | Yes | Full name |
| Email_Gestor | Text | Yes | Manager email |
| Nome_Gestor | Text | Yes | Manager name |
| Departamento | Text | Yes | Department |
| Data_Admissao | Date | Yes | Hire date |
| Ativo | Boolean | Yes | Is active employee |

#### Solicitacoes_Ferias
| Column | Type | Required | Description |
|--------|------|----------|-------------|
| ID | Auto | - | Auto-generated |
| Email_Colaborador | Text | Yes | Requester email |
| Data_Inicio | Date | Yes | Start date |
| Data_Fim | Date | Yes | End date |
| Total_Dias | Number | Yes | Duration in days |
| Status | Choice | Yes | PENDING/APPROVED/REJECTED/CANCELLED |
| Email_Aprovador | Text | Yes | Approver email |
| Tem_Conflito | Boolean | Yes | Has overlap with team |
| Observacoes | Multi-Text | No | Notes |
| Data_Criacao | DateTime | Yes | Created timestamp |
| Data_Aprovacao | DateTime | No | Approval timestamp |

#### Saldo_Ferias
| Column | Type | Required | Description |
|--------|------|----------|-------------|
| Email_Colaborador | Text | Yes | Employee email |
| Saldo_Dias | Number | Yes | Available days |
| Periodo_Aquisitivo | Text | Yes | Acquisition period |
| Data_Vencimento | Date | Yes | Expiration date |

#### Feriados
| Column | Type | Required | Description |
|--------|------|----------|-------------|
| Data | Date | Yes | Holiday date |
| Nome | Text | Yes | Holiday name |
| Tipo | Choice | Yes | NATIONAL/STATE/COMPANY |

---

## 4. Behavioral Rules (Detailed)

### 4.1 Authentication Rules
- All sensitive operations require authenticated user context
- User identity is obtained from Power Apps `User()` function (Azure AD SSO)

### 4.2 Conflict Detection Rules
- Before ANY request submission, system MUST check for conflicts
- If conflict exists: user must explicitly acknowledge before proceeding
- Conflict flag is sent to approver for visibility

### 4.3 Notification Rules
- On request creation: notify approver via Teams + Email
- On approval: notify employee via Teams + Email
- On rejection: notify employee with reason via Teams + Email
- 7 days before vacation: reminder to employee and manager

### 4.4 Validation Rules
```
IF (start_date - today) < 45 days THEN reject with message
IF (end_date - start_date) < 5 days THEN reject with message
IF (end_date - start_date) > 30 days THEN reject with message
IF (requested_days > available_balance) THEN reject with message
```

---

## 5. Architectural Invariants

### Layer 1: Documentation
```
c:\VMs\Projects\Copilot_Studio_Config\
├── docs/ADR-001-Architecture-Pivot.md    → Architecture decision record
├── Configuracao_Agente_Gestao_Ferias.md  → Agent config (Phase 2 reference)
├── Deploy_CLI_SharePoint.md              → Deployment SOP
├── Visao_Gerencial_Gestao_Ferias.md      → Business overview SOP
└── Checklist_Implementacao.md            → Implementation tracking
```

### Layer 2: UI (Power Apps)
- Canvas App with 5 screens: Home, New Request, My Requests, Approvals, Team Calendar
- Role-based navigation (employee vs manager via Colaboradores_Aprovadores lookup)
- Embedded in Teams as a tab/personal app

### Layer 3: Tools (Executors)
```
c:\VMs\Projects\Copilot_Studio_Config\
├── 01-Setup-Modulos.ps1        → Module installation
├── 02-Deploy-Listas.ps1        → List creation
├── 03-Importar-Dados.ps1       → Data import (bug fixed 2026-04-13)
└── 05-Seed-Saldo-Ferias.ps1    → Balance seeding (new 2026-04-13)
```

---

## 6. Integration Endpoints

### Power Automate Flows (MVP — 2 Flows, Standard License)

> ⚠️ No Premium license available. Architecture optimized for Standard connectors only.

| # | Flow Name | Trigger | Input | Output |
|---|-----------|---------|-------|--------|
| 1 | VacationApproval | SharePoint (item created) | auto from SP item | approval result + notifications |
| 2 | ScheduledAlerts | Recurrence (weekly) | — | alert records + notifications |

### Power Apps Embedded Logic (replaces Flows 3-5)

| Function | Implementation | Notes |
|----------|----------------|-------|
| Submit Request | `Patch()` → Solicitacoes_Ferias | Creates SP item, triggers Flow 1 |
| Cancel Request | `Patch()` → Status="CANCELLED" | Direct SP update, no flow needed |
| Check Conflicts | `Filter()` → Solicitacoes_Ferias | Real-time query by department + dates |
| Balance Validation | `LookUp()` → Saldo_Ferias | Client-side check before submit |
| Date Validation | Power Apps formulas | BR-001 to BR-003 rules enforced |

---

## 7. Maintenance Log

| Date | Action | Result | Notes |
|------|--------|--------|-------|
| 2026-01-25 04:10 | Project initialized | ✅ | B.L.A.S.T. protocol started |
| 2026-01-25 04:36 | gemini.md created | ✅ | Project constitution established |
| 2026-04-13 19:05 | **Architecture pivot approved** | ✅ | Copilot Studio → Power Apps + PA + SP |
| 2026-04-13 19:05 | Boolean bug fixed (03-Importar-Dados.ps1) | ✅ | R-003/TD-001 resolved |
| 2026-04-13 19:05 | Balance seeding script created | ✅ | 05-Seed-Saldo-Ferias.ps1 |
| 2026-04-13 19:26 | **No Premium license confirmed** | ✅ | 5 flows → 2 flows + Power Apps logic |
| 2026-04-13 19:50 | Flow blueprints created | ✅ | VacationApproval + ScheduledAlerts build guides |
| 2026-04-13 19:50 | Power Apps formula reference created | ✅ | All Power Fx for 5 screens |
| 2026-04-13 19:50 | Non-designer guide created | ✅ | Modern Controls + Fluent 2 themes |
| 2026-04-18 20:24 | **Cleanup: obsolete artifacts removed** | ✅ | flows/ folder, 7 scripts, old deploy guide |
| 2026-04-18 21:32 | **Phase 2: VacationApproval E2E verified** | ✅ | Full approval cycle tested (Title fix applied) |
| 2026-04-18 22:51 | **Phase 3: ScheduledAlerts E2E verified** | ✅ | Recurrence → filter → create alerts |
| 2026-04-19 05:42 | **Phase 4A: HTML Dashboard built** | ✅ | 6 files: dark-mode SPA (5 views) |
| 2026-04-19 06:15 | SP connector + deploy script created | ✅ | sp-connector.js + 11-Deploy-Dashboard-SP.ps1 |
| 2026-04-19 06:27 | **All project docs updated** | ✅ | CHECKPOINT, STATE, task, progress, gemini |

---

> ⚠️ **IMPORTANT**: This document is LAW. Any schema changes, rule additions, or architecture modifications MUST be reflected here before code changes.
