# Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                       │
│  ┌──────────────────────┐  ┌──────────────────────────────┐ │
│  │   Microsoft Teams    │  │    Outlook Email              │ │
│  │   (Primary Channel)  │  │    (Notifications)            │ │
│  └──────────┬───────────┘  └──────────────┬───────────────┘ │
└─────────────┼─────────────────────────────┼─────────────────┘
              │                             │
              ▼                             │
┌─────────────────────────────────────────────────────────────┐
│                  CONVERSATION LAYER                         │
│  ┌──────────────────────────────────────────────────┐       │
│  │            Copilot Studio Agent                  │       │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────────────┐ │       │
│  │  │ Topics   │ │ Entities │ │ Adaptive Cards   │ │       │
│  │  │ (11)     │ │ (Date,   │ │ (6 templates)    │ │       │
│  │  │          │ │  String) │ │                  │ │       │
│  │  └──────────┘ └──────────┘ └──────────────────┘ │       │
│  └──────────────────────┬───────────────────────────┘       │
└─────────────────────────┼───────────────────────────────────┘
                          │ HTTP Triggers
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                   BUSINESS LOGIC LAYER                      │
│  ┌──────────────────────────────────────────────────┐       │
│  │           Power Automate Flows (10)              │       │
│  │                                                  │       │
│  │  P1 (Core):        P2 (Approval):   P3 (Extra): │       │
│  │  ├ ConsultarSaldo  ├ Aprovar        ├ Cancelar   │       │
│  │  ├ VerificarConfl  ├ Rejeitar       ├ Dashboard  │       │
│  │  └ CriarSolicit    ├ ConsultStatus  └ Alertas    │       │
│  │                    └ NotifTeams                   │       │
│  └──────────────────────┬───────────────────────────┘       │
└─────────────────────────┼───────────────────────────────────┘
                          │ SharePoint Connector
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    DATA LAYER                               │
│  ┌──────────────────────────────────────────────────┐       │
│  │        SharePoint Online Lists (6)               │       │
│  │                                                  │       │
│  │  ┌───────────────────┐  ┌──────────────────┐     │       │
│  │  │ Colaboradores_    │  │ Solicitacoes_    │     │       │
│  │  │ Aprovadores (13)  │─▶│ Ferias           │     │       │
│  │  └───────────────────┘  └──────────────────┘     │       │
│  │  ┌───────────────────┐  ┌──────────────────┐     │       │
│  │  │ Saldo_Ferias      │  │ Historico_Ferias │     │       │
│  │  └───────────────────┘  └──────────────────┘     │       │
│  │  ┌───────────────────┐  ┌──────────────────┐     │       │
│  │  │ Feriados (19)     │  │ Alertas_Ferias   │     │       │
│  │  └───────────────────┘  └──────────────────┘     │       │
│  └──────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow

### Employee Request Flow
```
User (Teams) → Copilot Agent → Topic (CriarSolicitacao)
  → Power Automate (CriarSolicitacao flow)
    → SharePoint: Get approver from Colaboradores_Aprovadores
    → SharePoint: Create item in Solicitacoes_Ferias
    → Teams: Notify approver
    → HTTP Response → Adaptive Card to user
```

### Manager Approval Flow
```
Manager (Teams) → Copilot Agent → Topic (AprovarSolicitacao)
  → Power Automate (AprovarSolicitacao flow)
    → SharePoint: Update Solicitacoes_Ferias status
    → SharePoint: Update Saldo_Ferias
    → SharePoint: Create Historico_Ferias entry
    → Teams: Notify employee
    → HTTP Response → Adaptive Card to manager
```

## Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Data Store | SharePoint Lists | Native M365 integration, no additional licensing |
| Business Logic | Power Automate | HTTP triggers for Copilot Studio, low-code |
| Authentication | OAuth (browser-based) | Corporate SSO via Azure AD |
| Notifications | Teams + Email | Dual-channel per BR-006 |
| Solution Packaging | PAC CLI + .cdsproj | Standard Power Platform ALM |
| Column naming | No accents, no spaces | SharePoint internal name compatibility |

## Security Model

- **Authentication**: Azure AD SSO through Copilot Studio
- **User identity**: `System.User.Email` from authenticated session
- **Data access**: Through Power Automate service account
- **Approver resolution**: Lookup in `Colaboradores_Aprovadores` list
- **No RLS**: All data accessible through flows (filtered by email)
