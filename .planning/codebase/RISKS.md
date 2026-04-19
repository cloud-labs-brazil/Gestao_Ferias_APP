# Risks & Technical Debt

## Critical Risks 🔴

### R-001: Power Automate Premium License Not Validated
| Property | Value |
|----------|-------|
| **Severity** | 🔴 Critical |
| **Impact** | Blocks ALL flow deployment (0/10 flows) |
| **Description** | HTTP Request triggers require Premium licenses. No confirmation the tenant has them. |
| **Mitigation** | Validate license before starting Phase 3. Fallback: Standard connectors only. |
| **Status** | ⏳ Open |

### R-002: Saldo_Ferias List Has No Initial Data
| Property | Value |
|----------|-------|
| **Severity** | 🔴 Critical |
| **Impact** | Balance queries return empty/defaults for all employees |
| **Description** | The `03-Importar-Dados.ps1` only imports employees and holidays. No balance records are seeded. |
| **Mitigation** | Create a `04-Seed-Saldos.ps1` script or add balance seeding to existing import. |
| **Status** | ⏳ Open |

---

## High Risks 🟡

### R-003: Boolean Logic Bug in `03-Importar-Dados.ps1`
| Property | Value |
|----------|-------|
| **Severity** | 🟡 High |
| **Location** | `03-Importar-Dados.ps1:80` |
| **Description** | Line 80 has a logic error: `$ehGestorRaw -eq "Não" -eq $false` is evaluated left-to-right, producing incorrect results. |
| **Impact** | `EhGestor` field may be incorrectly mapped for some employees. |
| **Fix** | Rewrite conditional to proper boolean evaluation. |

### R-004: Flow Definitions Not Validated Against Real Power Automate
| Property | Value |
|----------|-------|
| **Severity** | 🟡 High |
| **Impact** | JSON definitions may not import correctly into Power Automate |
| **Description** | All 10 flow JSONs are hand-crafted definitions. They serve as reference/templates, not importable workflows. Manual recreation is required. |
| **Mitigation** | Use `04-Deploy-Flows.ps1` guide. Consider using PAC CLI for automated deployment. |

### R-005: No Business-Day Calculation Logic
| Property | Value |
|----------|-------|
| **Severity** | 🟡 High |
| **Impact** | `DiasUteis` (working days) is passed as input, not calculated |
| **Description** | The `CriarSolicitacao` flow accepts `dias_uteis` as an input parameter. There's no server-side calculation that excludes weekends and holidays from the `Feriados` list. |
| **Mitigation** | Add a Power Automate step to calculate business days using the Feriados list. |

### R-006: Copilot Template Uses Placeholder Flow IDs
| Property | Value |
|----------|-------|
| **Severity** | 🟡 High |
| **Location** | `copilot/GestaoFerias_Template.yaml` |
| **Description** | All `flowId` references use `{{FLOW_*}}` placeholder tokens that must be manually replaced after flow deployment. |
| **Mitigation** | Document the replacement process. Create a script to auto-populate after deployment. |

---

## Medium Risks 🟢

### R-007: No Validation of 45-Day Advance Rule in Flow Definitions
| Property | Value |
|----------|-------|
| **Severity** | 🟢 Medium |
| **Description** | BR-001 (45-day advance notice) is documented but not enforced in any flow JSON. Validation logic needs to be added. |

### R-008: No Conflict Detection Logic in Flow Definitions
| Property | Value |
|----------|-------|
| **Severity** | 🟢 Medium |
| **Description** | `Flow_02_VerificarConflitos.json` exists but the conflict detection logic (date overlap algorithm) needs validation against actual SharePoint data queries. |

### R-009: Hardcoded SharePoint Site URL
| Property | Value |
|----------|-------|
| **Severity** | 🟢 Medium |
| **Location** | Multiple scripts and flow JSONs |
| **Description** | The SharePoint URL `https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA` is hardcoded in multiple locations. |
| **Mitigation** | Centralize to parameter/config file. |

### R-010: No Automated Tests
| Property | Value |
|----------|-------|
| **Severity** | 🟢 Medium |
| **Description** | No automated test suite exists. All testing is manual per `Checklist_Implementacao.md`. |

---

## Technical Debt

| ID | Description | Category | Effort |
|----|-------------|----------|--------|
| TD-001 | `EhGestor` boolean bug in import script (L80) | Bug | Small |
| TD-002 | No balance seeding script | Missing Feature | Medium |
| TD-003 | Hardcoded URLs across scripts/flows | Config | Medium |
| TD-004 | `04-Deploy-Flows.ps1` is manual guide, not automation | Automation Gap | Large |
| TD-005 | No schema validation for Excel import | Data Quality | Small |
| TD-006 | Adaptive Cards reference external icon URLs (icons8.com) | Dependency | Small |
| TD-007 | Mixed PowerShell module versions (legacy + modern) | Compatibility | Medium |
| TD-008 | `Descricao` column in `Feriados` defined but holidays use `Title` instead | Schema Mismatch | Small |
| TD-009 | No logging/audit trail for flow executions | Observability | Medium |
| TD-010 | Solution package (`GestaoFerias.zip`) is minimal/empty | Packaging | Large |
