# Flow 2: ScheduledAlerts — Build Blueprint

> **License:** Standard (No Premium)  
> **Connectors Used:** SharePoint, Office 365 Outlook, Microsoft Teams  
> **Trigger:** Recurrence (weekly)  
> **Estimated Build Time:** 20-30 minutes  
> **Last Updated:** 2026-04-18 — Fixed all column names to match deployed SP schema

---

## Overview

This flow runs weekly and generates proactive alerts:
1. **7-day reminder:** Vacations starting in the next 7 days → notify employee + manager
2. **Balance expiration warning:** Balances where the "vacation birthday" deadline is within 60 days → notify employee
3. **Writes alert records** to `Alertas_Ferias` for audit trail

### CLT "Vacation Birthday" Rule
- Each employee's hiring date anniversary ("aniversário de admissão") determines their vacation cycle
- If an employee accumulates 2 unused periods (60 days), the company must pay a penalty ("dobra")
- The `DataVencimento` column in `Saldo_Ferias` tracks this deadline per employee

---

## SharePoint Column Reference (ACTUAL deployed names)

> ⚠️ **CRITICAL:** Use these EXACT names in filter queries and dynamic content. No underscores, no aliases.

### Solicitacoes_Ferias
| Column | Internal Name | Type |
|--------|---------------|------|
| Employee Email | `ColaboradorEmail` | Text |
| Employee Name | `ColaboradorNome` | Text |
| Start Date | `DataInicio` | DateTime |
| End Date | `DataFim` | DateTime |
| Business Days | `DiasUteis` | Number |
| Type | `Tipo` | Text |
| Status | `Status` | Text |
| Approver Email | `AprovadorEmail` | Text |
| Approval Date | `DataAprovacao` | DateTime |
| Notes | `Observacoes` | Note |

### Colaboradores_Aprovadores
| Column | Internal Name | Type |
|--------|---------------|------|
| Employee Email | `Email` | Text |
| Full Name | `NomeCompleto` | Text |
| Department | `Departamento` | Text |
| Approver Email | `AprovadorEmail` | Text |
| Approver Name | `AprovadorNome` | Text |
| Hire Date | `DataAdmissao` | DateTime |
| Active | `Ativo` | Boolean |

### Saldo_Ferias
| Column | Internal Name | Type |
|--------|---------------|------|
| Employee Email | `ColaboradorEmail` | Text |
| Reference Year | `AnoReferencia` | Number |
| Total Balance | `SaldoTotal` | Number |
| Days Used | `DiasUsados` | Number |
| Days Scheduled | `DiasAgendados` | Number |
| Available Balance | `SaldoDisponivel` | Number |
| Last Updated | `DataAtualizacao` | DateTime |
| **Expiration Date** | **`DataVencimento`** | **DateTime** |

> 📌 `DataVencimento` is added by script `09-Add-DataVencimento-Column.ps1`. Run it before building this flow.

### Alertas_Ferias
| Column | Internal Name | Type |
|--------|---------------|------|
| Employee Email | `ColaboradorEmail` | Text |
| Alert Type | `TipoAlerta` | Text |
| Message | `Mensagem` | Note |
| Sent Date | `DataEnvio` | DateTime |
| Was Sent | `Enviado` | Boolean |
| Request ID | `SolicitacaoId` | Number |

---

## Step-by-Step Build Instructions

### Step 0: Create the Flow

1. Go to [make.powerautomate.com](https://make.powerautomate.com)
2. Click **+ Create** → **Scheduled cloud flow**
3. Name: `GestaoFerias_ScheduledAlerts`
4. Starting: `next Monday, 08:00 AM`
5. Repeat every: `1 Week`
6. Click **Create**

---

### Step 1: Trigger — Recurrence

| Setting | Value |
|---------|-------|
| **Frequency** | `Week` |
| **Interval** | `1` |
| **On These Days** | `Monday` |
| **At These Hours** | `8` |
| **Time Zone** | `(UTC-03:00) Brasilia` |

---

### Step 2: Initialize Date Variables

#### Variable: `varToday`
| Setting | Value |
|---------|-------|
| Name | `varToday` |
| Type | String |
| Value | `@{formatDateTime(utcNow(), 'yyyy-MM-dd')}` |

#### Variable: `var7DaysFromNow`
| Setting | Value |
|---------|-------|
| Name | `var7DaysFromNow` |
| Type | String |
| Value | `@{formatDateTime(addDays(utcNow(), 7), 'yyyy-MM-dd')}` |

#### Variable: `var60DaysFromNow`
| Setting | Value |
|---------|-------|
| Name | `var60DaysFromNow` |
| Type | String |
| Value | `@{formatDateTime(addDays(utcNow(), 60), 'yyyy-MM-dd')}` |

#### Variable: `varAlertCount`
| Setting | Value |
|---------|-------|
| Name | `varAlertCount` |
| Type | Integer |
| Value | `0` |

---

## SECTION A: Upcoming Vacation Reminders (7 days)

### Step 3: Get Approved Vacations Starting Soon

Add **Get items** (SharePoint):

| Setting | Value |
|---------|-------|
| Site Address | `https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA` |
| List Name | `Solicitacoes_Ferias` |
| Filter Query | `Status eq 'APPROVED' and DataInicio ge '@{variables('varToday')}' and DataInicio le '@{variables('var7DaysFromNow')}'` |
| Top Count | `100` |

> **Rename** to `GetUpcomingVacations`

---

### Step 4: Apply to Each — Upcoming Vacation

Add **Apply to each** → select `@{outputs('GetUpcomingVacations')?['body/value']}`:

Inside the loop:

#### 4.1 — Get Employee Info

Add **Get items** (SharePoint):

| Setting | Value |
|---------|-------|
| List Name | `Colaboradores_Aprovadores` |
| Filter Query | `Email eq '@{items('Apply_to_each')?['ColaboradorEmail']}'` |
| Top Count | `1` |

> **Rename** to `GetEmpInfo`

#### 4.2 — Notify Employee (Teams)

Add **Post message in a chat or channel** (Microsoft Teams):

| Setting | Value |
|---------|-------|
| Post As | `Flow bot` |
| Post In | `Chat with Flow bot` |
| Recipient | `@{items('Apply_to_each')?['ColaboradorEmail']}` |
| Message | _(see below)_ |

```
📅 Lembrete: Suas férias começam em breve!

📆 Início: @{formatDateTime(items('Apply_to_each')?['DataInicio'], 'dd/MM/yyyy')}
📆 Fim: @{formatDateTime(items('Apply_to_each')?['DataFim'], 'dd/MM/yyyy')}
📊 Duração: @{items('Apply_to_each')?['DiasUteis']} dias úteis

Lembre-se de preparar suas entregas e delegar suas atividades.
```

#### 4.3 — Notify Manager (Teams)

Add **Post message in a chat or channel** (Microsoft Teams):

| Setting | Value |
|---------|-------|
| Post As | `Flow bot` |
| Post In | `Chat with Flow bot` |
| Recipient | `@{items('Apply_to_each')?['AprovadorEmail']}` |
| Message | _(see below)_ |

```
📅 Lembrete: Férias do colaborador @{first(outputs('GetEmpInfo')?['body/value'])?['NomeCompleto']} começam em breve!

📆 Período: @{formatDateTime(items('Apply_to_each')?['DataInicio'], 'dd/MM/yyyy')} a @{formatDateTime(items('Apply_to_each')?['DataFim'], 'dd/MM/yyyy')}
📊 Duração: @{items('Apply_to_each')?['DiasUteis']} dias úteis

Certifique-se de que as atividades estão cobertas durante a ausência.
```

#### 4.4 — Create Alert Record

Add **Create item** (SharePoint):

| Setting | Value |
|---------|-------|
| List Name | `Alertas_Ferias` |
| Title | `Lembrete 7 dias - @{first(outputs('GetEmpInfo')?['body/value'])?['NomeCompleto']}` |
| TipoAlerta | `LEMBRETE_7_DIAS` |
| ColaboradorEmail | `@{items('Apply_to_each')?['ColaboradorEmail']}` |
| DataEnvio | `@{utcNow()}` |
| Mensagem | `Férias iniciam em @{formatDateTime(items('Apply_to_each')?['DataInicio'], 'dd/MM/yyyy')}` |
| Enviado | `true` |

#### 4.5 — Increment Alert Count

Add **Increment variable**: `varAlertCount` by `1`

---

## SECTION B: Balance Expiration Warnings (60 days)

### Step 5: Get Balances with Upcoming Expiration

Add **Get items** (SharePoint):

| Setting | Value |
|---------|-------|
| List Name | `Saldo_Ferias` |
| Filter Query | `SaldoDisponivel gt 0 and DataVencimento le '@{variables('var60DaysFromNow')}'` |
| Top Count | `100` |

> **Rename** to `GetExpiringBalances`

---

### Step 6: Apply to Each — Expiring Balance

Add **Apply to each** → select `@{outputs('GetExpiringBalances')?['body/value']}`:

Inside the loop:

#### 6.1 — Notify Employee (Email)

Add **Send an email (V2)** (Office 365 Outlook):

| Setting | Value |
|---------|-------|
| To | `@{items('Apply_to_each_-_Expiring')?['ColaboradorEmail']}` |
| Subject | `⚠️ Saldo de Férias próximo ao vencimento` |
| Body | _(see below)_ |

```html
<p>Olá,</p>
<p>Seu saldo de férias está próximo ao <b>vencimento</b> (aniversário de admissão):</p>
<ul>
  <li><b>Dias restantes:</b> @{items('Apply_to_each_-_Expiring')?['SaldoDisponivel']}</li>
  <li><b>Prazo limite:</b> @{formatDateTime(items('Apply_to_each_-_Expiring')?['DataVencimento'], 'dd/MM/yyyy')}</li>
  <li><b>Ano referência:</b> @{items('Apply_to_each_-_Expiring')?['AnoReferencia']}</li>
</ul>
<p>⚠️ Caso o saldo não seja utilizado até esta data, a empresa pode incorrer em penalidade ("dobra") conforme a CLT.</p>
<p>Agende suas férias o quanto antes. Acesse o app <b>Gestão Férias</b> no Teams para solicitar.</p>
```

#### 6.2 — Notify Manager (Teams)

Add **Get items** (SharePoint) to find the employee's manager:

| Setting | Value |
|---------|-------|
| List Name | `Colaboradores_Aprovadores` |
| Filter Query | `Email eq '@{items('Apply_to_each_-_Expiring')?['ColaboradorEmail']}'` |
| Top Count | `1` |

> **Rename** to `GetEmpManager`

Add **Post message in a chat or channel** (Microsoft Teams):

| Setting | Value |
|---------|-------|
| Post As | `Flow bot` |
| Post In | `Chat with Flow bot` |
| Recipient | `@{first(outputs('GetEmpManager')?['body/value'])?['AprovadorEmail']}` |
| Message | _(see below)_ |

```
⚠️ Alerta: Saldo de férias do colaborador @{first(outputs('GetEmpManager')?['body/value'])?['NomeCompleto']} vence em breve!

📊 Dias restantes: @{items('Apply_to_each_-_Expiring')?['SaldoDisponivel']}
📆 Prazo limite: @{formatDateTime(items('Apply_to_each_-_Expiring')?['DataVencimento'], 'dd/MM/yyyy')}

Caso não sejam agendadas, a empresa pode incorrer em penalidade (CLT "dobra").
Alinhe com o colaborador para agendar as férias.
```

#### 6.3 — Create Alert Record

Add **Create item** (SharePoint):

| Setting | Value |
|---------|-------|
| List Name | `Alertas_Ferias` |
| Title | `Vencimento saldo - @{items('Apply_to_each_-_Expiring')?['ColaboradorEmail']}` |
| TipoAlerta | `VENCIMENTO_SALDO` |
| ColaboradorEmail | `@{items('Apply_to_each_-_Expiring')?['ColaboradorEmail']}` |
| DataEnvio | `@{utcNow()}` |
| Mensagem | `Saldo de @{items('Apply_to_each_-_Expiring')?['SaldoDisponivel']} dias vence em @{formatDateTime(items('Apply_to_each_-_Expiring')?['DataVencimento'], 'dd/MM/yyyy')}` |
| Enviado | `true` |

#### 6.4 — Increment Alert Count

Add **Increment variable**: `varAlertCount` by `1`

---

## Flow Diagram Summary

```
Recurrence (Weekly, Monday 08:00 BRT)
    │
    ├── Initialize Variables (varToday, var7DaysFromNow, var60DaysFromNow, varAlertCount)
    │
    ├── SECTION A: Upcoming Vacation Reminders
    │   └── Get Approved Vacations from Solicitacoes_Ferias (next 7 days)
    │       └── FOR EACH vacation:
    │           ├── Get Employee Info from Colaboradores_Aprovadores
    │           ├── Notify Employee (Teams chat)
    │           ├── Notify Manager (Teams chat)
    │           ├── Create Alert Record in Alertas_Ferias
    │           └── Increment varAlertCount
    │
    └── SECTION B: Balance Expiration Warnings (CLT "dobra")
        └── Get Balances from Saldo_Ferias (DataVencimento within 60 days)
            └── FOR EACH expiring balance:
                ├── Notify Employee (Email)
                ├── Get Manager + Notify Manager (Teams chat)
                ├── Create Alert Record in Alertas_Ferias
                └── Increment varAlertCount
```

---

## Testing Checklist

- [ ] Run `09-Add-DataVencimento-Column.ps1` to add the missing column
- [ ] Run `10-Test-ScheduledAlerts.ps1 -Action setup` to create test data
- [ ] Manually trigger the flow (click "Test" → "Manually")
- [ ] Verify Teams notification sent to employee (Section A)
- [ ] Verify Teams notification sent to manager (Section A)
- [ ] Verify email sent for expiring balance (Section B)
- [ ] Verify alert records created in `Alertas_Ferias`
- [ ] Run `10-Test-ScheduledAlerts.ps1 -Action verify` to check results
- [ ] Run `10-Test-ScheduledAlerts.ps1 -Action cleanup` to remove test data

---

## Common Issues & Fixes

| Issue | Fix |
|-------|-----|
| `A coluna 'DataVencimento' não existe` | Run `09-Add-DataVencimento-Column.ps1` first |
| ODATA filter fails on date comparison | Ensure dates are in `yyyy-MM-dd` ISO format |
| `ColaboradorEmail` not found | Column was previously named `Email_Colaborador` — use exact internal name from SP |
| Flow timeout on large datasets | Use `Top Count: 100` and pagination settings |
| `Alertas_Ferias` columns don't match | Use: `ColaboradorEmail`, `TipoAlerta`, `Mensagem`, `DataEnvio`, `Enviado` |
