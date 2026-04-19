# Component Inventory

## 1. Deployment Scripts (PowerShell)

### `01-Setup-Modulos.ps1`
| Property | Value |
|----------|-------|
| **Purpose** | Install required PowerShell modules |
| **Dependencies** | None (first script to run) |
| **Modules Installed** | `ImportExcel`, `PnP.PowerShell` |
| **Status** | ✅ Complete & Tested |
| **Lines** | 37 |

### `02-Deploy-Listas.ps1`
| Property | Value |
|----------|-------|
| **Purpose** | Create 6 SharePoint lists with columns |
| **Dependencies** | `PnP.PowerShell` module |
| **Input Parameter** | `$SiteUrl` (default: indra365 site) |
| **Auth Method** | `Connect-PnPOnline -UseWebLogin` |
| **Idempotent** | ✅ Yes (skip-if-exists logic) |
| **Status** | ✅ Complete & Deployed |
| **Lines** | 165 |

### `03-Importar-Dados.ps1`
| Property | Value |
|----------|-------|
| **Purpose** | Import employees from Excel + seed holidays |
| **Dependencies** | `ImportExcel`, `PnP.PowerShell` |
| **Input Parameters** | `$SiteUrl`, `$ExcelPath` |
| **Data Source** | `Users_Approvers.xlsx` |
| **Records** | 13 employees + 19 holidays (2026) |
| **Column Mapping** | Flexible (supports multiple header names) |
| **Status** | ✅ Complete & Deployed |
| **Lines** | 173 |

### `04-Deploy-Flows.ps1`
| Property | Value |
|----------|-------|
| **Purpose** | Guide/audit for Power Automate flow deployment |
| **Note** | Not automated — provides step-by-step instructions |
| **Lists Flows** | 10 flows with priority and file status |
| **Status** | ✅ Complete (guide only) |
| **Lines** | 114 |

---

## 2. Power Automate Flow Definitions (JSON)

| # | Flow File | Priority | Trigger | Actions | Lines |
|---|-----------|----------|---------|---------|-------|
| 01 | `Flow_01_ConsultarSaldoFerias.json` | P1 | HTTP | Parse → SP GetItems → Conditional Response | 105 |
| 02 | `Flow_02_VerificarConflitos.json` | P1 | HTTP | Parse → SP GetItems → Filter → Response | ~130 |
| 03 | `Flow_03_CriarSolicitacao.json` | P1 | HTTP | Parse → Get Approver → Create Item → Teams Notif → Response | 176 |
| 04 | `Flow_04_AprovarSolicitacao.json` | P2 | HTTP | Parse → Update Item → Create History → Teams Notif → Response | ~150 |
| 05 | `Flow_05_RejeitarSolicitacao.json` | P2 | HTTP | Parse → Update Item → Teams Notif → Response | ~120 |
| 06 | `Flow_06_ConsultarStatusSolicitacao.json` | P2 | HTTP | Parse → SP GetItems → Response | ~70 |
| 07 | `Flow_07_CancelarSolicitacao.json` | P3 | HTTP | Parse → Validate → Update → Response | ~130 |
| 08 | `Flow_08_ObterDashboardGestor.json` | P3 | HTTP | Parse → Get Team → Get Requests → Aggregate → Response | ~110 |
| 09 | `Flow_09_ObterAlertasCriticos.json` | P3 | HTTP | Get Alerts → Filter → Response | ~65 |
| 10 | `Flow_10_EnviarNotificacaoTeams.json` | P2 | HTTP | Parse → Teams Post → Response | ~110 |

**Deployment Status**: All 10 definition files created ✅ | 0/10 deployed to Power Automate ⏳

---

## 3. Copilot Studio Agent

### `copilot/GestaoFerias_Template.yaml`
| Property | Value |
|----------|-------|
| **Schema** | AdaptiveTrigger 1.0.0 |
| **Topics Defined** | 11 (including fallback) |
| **Flow References** | 9 (via `{{FLOW_*}}` placeholders) |
| **Entities Used** | `DateTimeEntity`, `StringEntity` |
| **Lines** | 278 |

### Topics Inventory

| Topic | Display Name | Type | Flow Connected |
|-------|-------------|------|----------------|
| OnConversationStart | Welcome | System | None |
| ConsultarSaldo | Consultar Saldo de Férias | Employee | ConsultarSaldoFerias |
| CriarSolicitacao | Criar Solicitação de Férias | Employee | CriarSolicitacao |
| ConsultarStatus | Consultar Status | Employee | ConsultarStatus |
| VerificarConflitos | Verificar Conflitos de Equipe | Employee | VerificarConflitos |
| CancelarSolicitacao | Cancelar Solicitação | Employee | CancelarSolicitacao |
| AprovarSolicitacao | Aprovar Solicitação (Gestor) | Manager | AprovarSolicitacao |
| RejeitarSolicitacao | Rejeitar Solicitação (Gestor) | Manager | RejeitarSolicitacao |
| DashboardGestor | Dashboard do Gestor | Manager | DashboardGestor |
| AlertasCriticos | Alertas Críticos | System | AlertasCriticos |
| Ajuda | Ajuda e Informações | System | None |
| Fallback | Resposta Padrão | System | None |

---

## 4. Adaptive Cards

| Card | Purpose | Size | Key Data |
|------|---------|------|----------|
| `SaldoFerias_Card.json` | Display balance | 3.5KB | days, period, expiration |
| `SolicitacaoCriada_Card.json` | Confirm request created | 3.8KB | request ID, dates, approver |
| `Conflitos_Card.json` | Show team conflicts | 5.8KB | conflicting employees, dates |
| `StatusSolicitacoes_Card.json` | List request statuses | 5.7KB | multiple requests, filters |
| `DashboardGestor_Card.json` | Manager overview | 9.6KB | team stats, pending items |
| `Alertas_Card.json` | Critical alerts | 5.0KB | expiring balances, reminders |

**Adaptive Card Version**: 1.4

---

## 5. Power Platform Solution

### `GestaoFerias/GestaoFerias.cdsproj`
| Property | Value |
|----------|-------|
| **GUID** | `849f592d-f8be-4060-99aa-fedbce29f708` |
| **Target Framework** | .NET 4.6.2 |
| **Solution Root** | `src/` |
| **MSBuild Package** | `Microsoft.PowerApps.MSBuild.Solution 1.*` |

### Solution XML Files
| File | Location | Purpose |
|------|----------|---------|
| `Solution.xml` | `src/Other/` | Solution manifest (4.5KB) |
| `Customizations.xml` | `src/Other/` | Component definitions (460B) |
| `Relationships.xml` | `src/Other/` | Entity relationships (120B) |

### Exported Package
| File | Location | Size |
|------|----------|------|
| `GestaoFerias.zip` | `GestaoFerias_Solution/` | 1.8KB |

---

## 6. Documentation

| Document | Purpose | Size | Status |
|----------|---------|------|--------|
| `gemini.md` | Project constitution / GEMINI.MD | 9.6KB | ✅ Active (LAW) |
| `Configuracao_Agente_Gestao_Ferias.md` | Full agent config SOP | 39KB | ✅ Complete |
| `Visao_Gerencial_Gestao_Ferias.md` | Business overview SOP | 28KB | ✅ Complete |
| `Deploy_CLI_SharePoint.md` | SharePoint deployment SOP | 28KB | ✅ Complete |
| `Guia_Deploy_Flows.md` | Flow deployment guide | 4.3KB | ✅ Complete |
| `guia_de_conexao_pac_cli.md` | PAC CLI connection guide | 19KB | ✅ Complete |
| `Checklist_Implementacao.md` | Implementation tracking | 8.4KB | ✅ Active |
| `findings.md` | Research & discoveries log | 6.4KB | ✅ Active |
| `progress.md` | Execution progress log | 2.4KB | ✅ Active |
| `task.md` | Task tracking | 1.4KB | ✅ Active |
| `task_plan.md` | Task planning | 2.6KB | ✅ Active |
| `docs/Manual_Usuario.md` | End-user manual | 3.9KB | ✅ Complete |
| `docs/Guia_Gestor.md` | Manager guide | 2.3KB | ✅ Complete |

---

## 7. Data Files

| File | Purpose | Size |
|------|---------|------|
| `Users_Approvers.xlsx` | Employee/manager mapping seed data | 4.6KB |

---

## 8. Media Files (Screenshots)

| File | Purpose |
|------|---------|
| `sharepoint_create_lists_*.webp` | Screenshot of SharePoint list creation |
| `uploaded_media_0_*.png` | Project reference image |
| `uploaded_media_1_*.png` | Project reference image |
| `uploaded_media_*.png` | Additional reference image |
