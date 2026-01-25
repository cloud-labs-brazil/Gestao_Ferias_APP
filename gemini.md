# 🧠 GEMINI.MD - Project Constitution
> **Agente "Gestão Férias"** - Microsoft Copilot Studio  
> **Status:** PLANNING PHASE  
> **Last Updated:** 2026-01-25T04:36:00-03:00

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
| **Project Name** | Gestão Férias (Vacation Management Agent) |
| **Platform** | Microsoft Copilot Studio |
| **Backend** | SharePoint Online + Power Automate |
| **Target Users** | Employees + Managers (Minsait/Indra) |
| **Tenant** | `indra365.sharepoint.com` |
| **Admin Account** | `mbenicios@minsait.com` |

---

## 2. B.L.A.S.T. Discovery Answers

### 🎯 North Star
**What is the singular desired outcome?**
> A fully functional Copilot Studio agent that enables employees to:
> - Query vacation balance
> - Submit vacation requests (with conflict detection)
> - Track approval status
> - Managers: approve/reject requests and view team calendar

### 🔗 Integrations
**Which external services do we need? Are keys ready?**

| Service | Purpose | Status | Notes |
|---------|---------|--------|-------|
| SharePoint Online | Data storage (6 lists) | 🟡 pending deploy | Scripts ready |
| Power Automate | Business logic (10 flows) | ⏳ pending | Requires Premium license validation |
| Copilot Studio | Agent hosting | ✅ ready | Agent "Gestão Férias" created |
| Microsoft Teams | Delivery channel | ⏳ pending | Post go-live |
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
| Agent Responses | Microsoft Teams Chat | Adaptive Cards + Text |
| Approval Notifications | Teams + Email | Adaptive Cards |
| Status Updates | Teams + Email | Rich text |
| Manager Dashboard | Teams (via agent) | Formatted text/tables |

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
| BR-008 | Power Automate Premium license available | ✅ Confirmed (2026-01-25) |

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
- User identity is obtained from Copilot Studio authentication

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

### Layer 1: Architecture (SOPs)
```
c:\VMs\Projects\Copilot_Studio_Config\
├── Configuracao_Agente_Gestao_Ferias.md  → Agent configuration SOP
├── Deploy_CLI_SharePoint.md              → Deployment SOP
├── Visao_Gerencial_Gestao_Ferias.md      → Business overview SOP
└── checklist.md                          → Implementation tracking
```

### Layer 2: Navigation (Decision Making)
- Copilot Studio agent routes user intents to appropriate flows
- Topics map to Power Automate flows

### Layer 3: Tools (Executors)
```
c:\VMs\Projects\Copilot_Studio_Config\
├── 01-Setup-Modulos.ps1     → Module installation
├── 02-Deploy-Listas.ps1     → List creation
└── 03-Importar-Dados.ps1    → Data import
```

---

## 6. Integration Endpoints

### Power Automate Flows (To Be Created)

| Flow Name | Trigger | Input | Output |
|-----------|---------|-------|--------|
| ConsultarSaldoFerias | HTTP | email | balance object |
| VerificarConflitos | HTTP | dates, team_id | conflict object |
| CriarSolicitacao | HTTP | request payload | request response |
| AprovarSolicitacao | HTTP | request_id, decision | status |
| RejeitarSolicitacao | HTTP | request_id, reason | status |
| ConsultarStatusSolicitacao | HTTP | request_id | status object |
| CancelarSolicitacao | HTTP | request_id, reason | status |
| ObterDashboardGestor | HTTP | manager_email | dashboard data |
| ObterAlertasCriticos | HTTP | - | alerts array |
| EnviarNotificacaoTeams | HTTP | recipients, message | send status |

---

## 7. Maintenance Log

| Date | Action | Result | Notes |
|------|--------|--------|-------|
| 2026-01-25 04:10 | Project initialized | ✅ | B.L.A.S.T. protocol started |
| 2026-01-25 04:36 | gemini.md created | ✅ | Project constitution established |

---

> ⚠️ **IMPORTANT**: This document is LAW. Any schema changes, rule additions, or architecture modifications MUST be reflected here before code changes.
