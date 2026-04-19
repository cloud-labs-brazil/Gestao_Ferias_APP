# Data Model

## Entity Relationship Diagram

```mermaid
erDiagram
    Colaboradores_Aprovadores ||--o{ Solicitacoes_Ferias : "submits"
    Colaboradores_Aprovadores ||--o{ Saldo_Ferias : "has balance"
    Colaboradores_Aprovadores ||--o{ Historico_Ferias : "has history"
    Colaboradores_Aprovadores ||--o{ Alertas_Ferias : "receives"
    Solicitacoes_Ferias ||--o{ Alertas_Ferias : "generates"

    Colaboradores_Aprovadores {
        text Title PK "Auto (display name)"
        text Email UK "Employee email"
        text NomeCompleto "Full name"
        text Departamento "Department"
        text Cargo "Position"
        text AprovadorEmail FK "Manager email"
        text AprovadorNome "Manager name"
        datetime DataAdmissao "Hire date"
        boolean Ativo "Is active"
    }

    Solicitacoes_Ferias {
        int ID PK "Auto-generated"
        text Title "Title (auto)"
        text ColaboradorEmail FK "Requester"
        text ColaboradorNome "Requester name"
        datetime DataInicio "Start date"
        datetime DataFim "End date"
        number DiasUteis "Working days"
        text Tipo "Type (Férias)"
        text Status "PENDING/APPROVED/REJECTED/CANCELLED"
        text AprovadorEmail FK "Approver"
        datetime DataAprovacao "Approval date"
        note Observacoes "Notes"
        boolean CriadoPorBot "Created by bot"
    }

    Saldo_Ferias {
        int ID PK "Auto-generated"
        text ColaboradorEmail FK "Employee email"
        number AnoReferencia "Reference year"
        number SaldoTotal "Total days"
        number DiasUsados "Used days"
        number DiasAgendados "Scheduled days"
        number SaldoDisponivel "Available days"
        datetime DataAtualizacao "Last update"
    }

    Historico_Ferias {
        int ID PK "Auto-generated"
        text ColaboradorEmail FK "Employee email"
        number AnoReferencia "Reference year"
        datetime DataInicio "Start date"
        datetime DataFim "End date"
        number DiasUteis "Working days"
        text Tipo "Type"
        text Status "Final status"
    }

    Feriados {
        int ID PK "Auto-generated"
        text Title "Holiday name"
        datetime Data "Date"
        text Descricao "Description"
        text Tipo "NACIONAL/PONTE/RECESSO"
        number Ano "Year"
    }

    Alertas_Ferias {
        int ID PK "Auto-generated"
        text ColaboradorEmail FK "Recipient"
        text TipoAlerta "Alert type"
        note Mensagem "Message text"
        datetime DataEnvio "Send date"
        boolean Enviado "Was sent"
        number SolicitacaoId FK "Related request"
    }
```

## Current Data Volumes

| List | Records | Sources |
|------|---------|---------|
| Colaboradores_Aprovadores | 13 | Excel import (`Users_Approvers.xlsx`) |
| Feriados | 19 | Script-generated (2026 holidays) |
| Solicitacoes_Ferias | 0 | Runtime (agent creates) |
| Historico_Ferias | 0 | Runtime (flow populates) |
| Saldo_Ferias | 0 | Runtime (flow manages) |
| Alertas_Ferias | 0 | Runtime (scheduled flow) |

## Key Relationships

| From | To | Type | Join Key |
|------|----|------|----------|
| Solicitacoes_Ferias | Colaboradores_Aprovadores | N:1 | `ColaboradorEmail` = `Email` |
| Solicitacoes_Ferias | Colaboradores_Aprovadores | N:1 | `AprovadorEmail` = `Email` |
| Saldo_Ferias | Colaboradores_Aprovadores | N:1 | `ColaboradorEmail` = `Email` |
| Historico_Ferias | Colaboradores_Aprovadores | N:1 | `ColaboradorEmail` = `Email` |
| Alertas_Ferias | Colaboradores_Aprovadores | N:1 | `ColaboradorEmail` = `Email` |
| Alertas_Ferias | Solicitacoes_Ferias | N:1 | `SolicitacaoId` = `ID` |

## Notes

- **No SharePoint lookups used** — all relationships are text-based (email keys) for simplicity
- **No cascading deletes** — all lists are independent
- **Saldo_Ferias** requires manual initial population or auto-creation on first balance query
- **Status enum values**: `Pendente`, `Aprovado`, `Rejeitado`, `Cancelado` (Portuguese)
