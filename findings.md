# 🔍 FINDINGS.MD - Research & Discoveries Log
> **Project:** Agente "Gestão Férias"  
> **Purpose:** Document all research, discoveries, and constraints  
> **Created:** 2026-01-25T04:36:00-03:00

---

## 📋 Table of Contents

1. [Environment Discoveries](#environment-discoveries)
2. [Technical Constraints](#technical-constraints)
3. [Business Rules Discovered](#business-rules-discovered)
4. [Integration Notes](#integration-notes)
5. [Open Questions](#open-questions)

---

## 1. Environment Discoveries

### SharePoint Configuration

| Discovery | Value | Date |
|-----------|-------|------|
| Tenant URL | `indra365.sharepoint.com` (NOT indracompany) | 2026-01-25 |
| Admin Account | `mbenicios@minsait.com` | 2026-01-25 |
| PnP Module Version | SharePointPnPPowerShellOnline (legacy) + v2.12/3.x | 2026-01-25 |

### Copilot Studio Configuration

| Discovery | Value | Date |
|-----------|-------|------|
| Agent Name | "Gestão Férias" | 2026-01-25 |
| Agent Status | Created and accessible | 2026-01-25 |

### File Locations

| Asset | Path | Status |
|-------|------|--------|
| Project Root | `c:\VMs\Projects\Copilot_Studio_Config` | ✅ |
| PowerShell Scripts | Same directory | ✅ |
| Employee Data | `Users_Approvers.xlsx` | ⚠️ Needs validation |

---

## 2. Technical Constraints

### PowerShell Execution

| Constraint | Details |
|------------|---------|
| Execution Environment | Must use Windows PowerShell (NOT VS Code) |
| Authentication | Browser-based OAuth flow (opens browser) |
| Module Compatibility | Using legacy PnP module for broader compatibility |

### SharePoint Lists

| Constraint | Details |
|------------|---------|
| List Names | Must use Portuguese names without accents |
| Column Types | Using SharePoint-native types only |
| Lookups | Avoided for simplicity in MVP |

### Power Automate

| Constraint | Details |
|------------|---------|
| License | Premium connectors may be required |
| HTTP Triggers | Required for Copilot Studio integration |
| Response Format | JSON for all flows |

---

## 3. Business Rules Discovered

### Confirmed Rules ✅

| Rule | Value | Source |
|------|-------|--------|
| Advance Notice | Minimum 45 days | Documentation |
| RH Handoff | NOT allowed (self-service only) | User confirmation |
| Holiday Calendar | Company-specific list | Documentation |
| Conflict Detection | Mandatory before submission | Documentation |
| Notification Channels | Teams AND Email | Documentation |

### Pending Confirmation ⚠️

| Rule | Proposed Value | Status |
|------|----------------|--------|
| Minimum days per request | 5 days | Awaiting confirmation |
| Maximum days per request | 30 days | Awaiting confirmation |

---

## 4. Integration Notes

### SharePoint Lists (6 Total)

```
1. Colaboradores_Aprovadores
   - Purpose: Employee-Manager mapping
   - Source: Excel import
   - Key: Email

2. Solicitacoes_Ferias
   - Purpose: Active requests
   - Key: Auto-ID
   - Relationships: Links to Colaboradores

3. Historico_Ferias
   - Purpose: Past vacation records
   - Key: Auto-ID

4. Saldo_Ferias
   - Purpose: Balance tracking
   - Key: Email
   - Update: After approval/rejection

5. Feriados
   - Purpose: Holiday calendar
   - Maintenance: Annual update

6. Alertas_Ferias
   - Purpose: Proactive notifications
   - Trigger: Scheduled flow
```

### Power Automate Flow Architecture

```
┌─────────────────────────────────────────────┐
│           Copilot Studio Agent              │
│         (Conversation Interface)            │
└─────────────────────────────────────────────┘
                    │
                    ▼ HTTP Triggers
┌─────────────────────────────────────────────┐
│          Power Automate Flows               │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐       │
│  │Consulta │ │ Criar   │ │Aprovar  │       │
│  │ Saldo   │ │Solicit. │ │Rejeitar │       │
│  └─────────┘ └─────────┘ └─────────┘       │
└─────────────────────────────────────────────┘
                    │
                    ▼ SharePoint Connector
┌─────────────────────────────────────────────┐
│           SharePoint Lists                  │
│    (Source of Truth for all data)           │
└─────────────────────────────────────────────┘
```

---

## 5. Open Questions

| # | Question | Priority | Asked To | Answer |
|---|----------|----------|----------|--------|
| 1 | Is Power Automate Premium license available? | 🔴 High | IT/Licensing | Pending |
| 2 | Minimum days per vacation request? | 🟡 Medium | Business | Pending |
| 3 | Maximum days per vacation request? | 🟡 Medium | Business | Pending |
| 4 | Are there blackout periods (no vacations allowed)? | 🟡 Medium | Business | Pending |
| 5 | Excel file column structure matches expected schema? | 🟡 Medium | Self-validate | Pending |

---

## 📝 Research Notes

### 2026-01-25: Initial Discovery

**Findings:**
- Tenant URL was initially assumed as `indracompany.sharepoint.com` but corrected to `indra365.sharepoint.com`
- PnP PowerShell has multiple versions; project uses legacy for compatibility
- All documentation is complete and comprehensive (4 main docs + 3 scripts)

**Implications:**
- Ready for SharePoint deployment (scripts exist)
- Power Automate phase blocked until license confirmation
- Copilot Studio configuration can proceed in parallel with SharePoint

---

> 💡 **Usage:** Update this file whenever you discover something new about the project environment, constraints, or integrations.
