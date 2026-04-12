# Project Conventions

## File Organization

```
Copilot_Studio_Config/
├── 0X-*.ps1                    # Numbered deployment scripts (execution order)
├── *.md                        # Documentation and SOPs (root level)
├── gemini.md                   # Project constitution (LAW)
├── flows/                      # Power Automate flow definitions (JSON)
│   └── Flow_NN_Name.json       # Numbered flow definitions
├── adaptive_cards/             # Adaptive Card templates (JSON)
│   └── *_Card.json             # Card templates by feature
├── copilot/                    # Copilot Studio agent configuration
│   └── *.yaml                  # Topic and trigger definitions
├── docs/                       # End-user documentation
│   ├── Manual_Usuario.md       # User manual
│   └── Guia_Gestor.md          # Manager guide
├── GestaoFerias/               # Power Platform solution project
│   ├── GestaoFerias.cdsproj    # MSBuild solution project
│   └── src/Other/              # Solution XML metadata
├── GestaoFerias_Solution/      # Exported solution package
│   └── GestaoFerias.zip        # Packed solution
└── .planning/                  # GSD planning directory
    └── codebase/               # Codebase mapping documents
```

## Naming Conventions

### Files
| Pattern | Convention | Example |
|---------|-----------|---------|
| PowerShell scripts | `NN-PascalCase.ps1` | `02-Deploy-Listas.ps1` |
| Flow definitions | `Flow_NN_PascalCase.json` | `Flow_03_CriarSolicitacao.json` |
| Adaptive Cards | `PascalCase_Card.json` | `SaldoFerias_Card.json` |
| Documentation | `PascalCase_With_Underscores.md` | `Checklist_Implementacao.md` |

### SharePoint Lists
| Convention | Example |
|-----------|---------|
| PascalCase with underscores | `Colaboradores_Aprovadores` |
| No accents/diacritics | `Solicitacoes_Ferias` (not `Solicitações_Férias`) |
| Portuguese language | All list and column names in PT-BR |

### SharePoint Columns
| Convention | Example |
|-----------|---------|
| PascalCase (no spaces) | `ColaboradorEmail`, `DataInicio` |
| Internal = Display name | Both are identical |
| Boolean prefix: `Is/Eh/Tem/Ativo` | `Ativo`, `CriadoPorBot` |

### Power Automate Flows
| Convention | Example |
|-----------|---------|
| PascalCase verb-first | `ConsultarSaldoFerias` |
| Priority tagging (P1/P2/P3) | P1 = Core, P2 = Approval, P3 = Extra |
| All use HTTP Request trigger | Copilot Studio integration pattern |

## Language & Localization

- **Code comments**: Portuguese (PT-BR)
- **Variables**: Portuguese or English (mixed)
- **Documentation**: Portuguese (PT-BR)
- **UI text (agent)**: Portuguese (PT-BR)
- **Log output**: Portuguese (PT-BR)
- **API payloads**: Portuguese field names (e.g., `email_colaborador`)

## Error Handling Patterns

### PowerShell Scripts
```powershell
# Try-catch with colored output
try {
    # operation
    Write-Host "[OK] Success message" -ForegroundColor Green
}
catch {
    Write-Host "[ERRO] Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
```

### Power Automate Flows
- Always return HTTP 200 (even on errors)
- Error info in response body: `{ "sucesso": false, "erro": "message" }`
- Fallback defaults for missing data (e.g., default 30-day balance)

## Business Rule Constants

| Rule | Value | Enforcement Point |
|------|-------|--------------------|
| BR-001: Advance notice | 45 days minimum | Flow validation |
| BR-002: Min days/request | 5 days | Flow validation |
| BR-003: Max days/request | 30 days | Flow validation |
| BR-004: No RH handoff | Self-service only | Agent design |
| BR-005: Conflict detection | Mandatory | Before submission |
| BR-006: Dual notifications | Teams + Email | After state changes |
| BR-007: No blackout periods | None | N/A |
