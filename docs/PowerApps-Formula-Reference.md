# Power Apps Formula Reference — Gestão Férias

> **Purpose:** Ready-to-paste Power Fx formulas for all embedded business logic  
> **App Type:** Canvas App (with Modern Controls + Fluent 2 Theme enabled)  
> **Data Sources:** 6 SharePoint lists (connect all on app start)

---

## Table of Contents

1. [App Setup — OnStart & Data Sources](#1-app-setup)
2. [Role Detection (Employee vs Manager)](#2-role-detection)
3. [Screen 1: Home — Balance Card](#3-screen-1-home)
4. [Screen 2: New Request — Validations & Submit](#4-screen-2-new-request)
5. [Screen 3: My Requests — List & Cancel](#5-screen-3-my-requests)
6. [Screen 4: Approvals (Manager)](#6-screen-4-approvals)
7. [Screen 5: Team Calendar (Manager)](#7-screen-5-team-calendar)
8. [Common Patterns](#8-common-patterns)

---

## 1. App Setup

### App.OnStart

```
// Cache current user info
Set(varCurrentUser, User());

// Role detection - is the current user a manager?
Set(
    varEmployeeRecord,
    LookUp(
        Colaboradores_Aprovadores,
        Email = varCurrentUser.Email
    )
);

Set(
    varIsManager,
    CountRows(
        Filter(
            Colaboradores_Aprovadores,
            Email_Gestor = varCurrentUser.Email
        )
    ) > 0
);

// Cache current balance
Set(
    varMyBalance,
    LookUp(
        Saldo_Ferias,
        Email_Colaborador = varCurrentUser.Email
    )
);
```

### App.Formulas (named formulas — if using modern experience)

```
// Alternative: Use App.Formulas for reactive data
frmMyPendingRequests = Filter(
    Solicitacoes_Ferias,
    Email_Colaborador = User().Email
        && Status.Value = "PENDING"
);

frmMyApprovedRequests = Filter(
    Solicitacoes_Ferias,
    Email_Colaborador = User().Email
        && Status.Value = "APPROVED"
);
```

---

## 2. Role Detection

### Show/Hide Manager-Only Screens

On the navigation buttons for "Approvals" and "Team Calendar":

```
// Visible property of manager-only nav buttons
varIsManager
```

### Get My Team (for managers)

```
Set(
    colMyTeam,
    Filter(
        Colaboradores_Aprovadores,
        Email_Gestor = varCurrentUser.Email
            && Ativo = true
    )
);
```

---

## 3. Screen 1: Home — Balance Card

### Balance Display Values

```
// Available days — text label
Text(varMyBalance.Saldo_Dias, "#,##0")

// Acquisition period
varMyBalance.Periodo_Aquisitivo

// Expiration date
Text(varMyBalance.Data_Vencimento, "dd/mm/yyyy")
```

### Active Requests Count

```
CountRows(
    Filter(
        Solicitacoes_Ferias,
        Email_Colaborador = varCurrentUser.Email
            && Status.Value in ["PENDING", "APPROVED"]
    )
)
```

### Quick Stats (Manager view)

```
// Pending approvals count
CountRows(
    Filter(
        Solicitacoes_Ferias,
        Email_Aprovador = varCurrentUser.Email
            && Status.Value = "PENDING"
    )
)

// Team members on vacation right now
CountRows(
    Filter(
        Solicitacoes_Ferias,
        Email_Aprovador = varCurrentUser.Email
            && Status.Value = "APPROVED"
            && Data_Inicio <= Today()
            && Data_Fim >= Today()
    )
)
```

---

## 4. Screen 2: New Request — Validations & Submit

### 4.1 Date Validation (BR-001, BR-002, BR-003)

#### Calculate Working Days (excluding weekends and holidays)

```
// Store selected dates
Set(varStartDate, dtpStartDate.SelectedDate);
Set(varEndDate, dtpEndDate.SelectedDate);

// Total calendar days
Set(varCalendarDays, DateDiff(varStartDate, varEndDate, TimeUnit.Days) + 1);

// Count holidays in range
Set(
    varHolidaysInRange,
    CountRows(
        Filter(
            Feriados,
            Data >= varStartDate && Data <= varEndDate
        )
    )
);

// Count weekend days in range (rough estimate)
Set(
    varWeekendDays,
    RoundDown(varCalendarDays / 7, 0) * 2 +
    If(
        Mod(varCalendarDays, 7) > 0,
        If(Weekday(varStartDate) + Mod(varCalendarDays, 7) > 7, 
            Min(Mod(varCalendarDays, 7), 2), 
            0
        ),
        0
    )
);

// Business days (simplified)
Set(varBusinessDays, varCalendarDays - varWeekendDays - varHolidaysInRange);
```

#### BR-001: Minimum 45 days advance notice

```
// Error label Visible property
DateDiff(Today(), varStartDate, TimeUnit.Days) < 45

// Error message
"A solicitação deve ser feita com no mínimo 45 dias de antecedência."
```

#### BR-002: Minimum 5 days per request

```
// Error label Visible property
varBusinessDays < 5

// Error message
"O período mínimo é de 5 dias úteis."
```

#### BR-003: Maximum 30 days per request

```
// Error label Visible property
varBusinessDays > 30

// Error message
"O período máximo é de 30 dias úteis por solicitação."
```

#### Balance Validation

```
// Error label Visible property
varBusinessDays > varMyBalance.Saldo_Dias

// Error message
"Saldo insuficiente. Disponível: " & varMyBalance.Saldo_Dias & " dias."
```

#### Master Validation (Enable/Disable Submit Button)

```
// Submit button DisplayMode property
If(
    // All dates selected
    !IsBlank(varStartDate) && !IsBlank(varEndDate) &&
    // End after start
    varEndDate > varStartDate &&
    // BR-001: 45 days advance
    DateDiff(Today(), varStartDate, TimeUnit.Days) >= 45 &&
    // BR-002: Min 5 days
    varBusinessDays >= 5 &&
    // BR-003: Max 30 days
    varBusinessDays <= 30 &&
    // Balance check
    varBusinessDays <= varMyBalance.Saldo_Dias,
    
    DisplayMode.Edit,
    DisplayMode.Disabled
)
```

### 4.2 Conflict Detection

```
// Run on date change (OnChange of date pickers)
Set(
    colConflicts,
    Filter(
        Solicitacoes_Ferias,
        // Same department (look up via Colaboradores_Aprovadores)
        Email_Aprovador = varEmployeeRecord.Email_Gestor &&
        // Approved or Pending
        Status.Value in ["APPROVED", "PENDING"] &&
        // Not my own request
        Email_Colaborador <> varCurrentUser.Email &&
        // Date overlap: their start <= my end AND their end >= my start
        Data_Inicio <= varEndDate &&
        Data_Fim >= varStartDate
    )
);

Set(varHasConflict, CountRows(colConflicts) > 0);
```

#### Conflict Warning Display

```
// Warning container Visible property
varHasConflict

// Conflict gallery Items property
colConflicts

// Each conflict row text
ThisItem.Email_Colaborador & " — " & 
Text(ThisItem.Data_Inicio, "dd/mm") & " a " & 
Text(ThisItem.Data_Fim, "dd/mm")
```

### 4.3 Submit Request

```
// Submit button OnSelect
Set(varSubmitting, true);

// Create the request in SharePoint
// ⚠️ Title is REQUIRED — Power Automate trigger fails without it
Patch(
    Solicitacoes_Ferias,
    Defaults(Solicitacoes_Ferias),
    {
        Title: "Ferias - " & varEmployeeRecord.NomeCompleto,
        Email_Colaborador: varCurrentUser.Email,
        Data_Inicio: varStartDate,
        Data_Fim: varEndDate,
        Total_Dias: varBusinessDays,
        Status: {Value: "PENDING"},
        Email_Aprovador: varEmployeeRecord.Email_Gestor,
        Tem_Conflito: varHasConflict,
        Observacoes: txtNotes.Text,
        Data_Criacao: Now()
    }
);

// Refresh balance cache
Set(
    varMyBalance,
    LookUp(
        Saldo_Ferias,
        Email_Colaborador = varCurrentUser.Email
    )
);

// Show success and navigate
Notify("Solicitação enviada com sucesso! Aguardando aprovação.", NotificationType.Success);
Set(varSubmitting, false);
Navigate(scrMyRequests, ScreenTransition.None);
```

---

## 5. Screen 3: My Requests — List & Cancel

### Gallery Items

```
SortByColumns(
    Filter(
        Solicitacoes_Ferias,
        Email_Colaborador = varCurrentUser.Email
    ),
    "Data_Criacao",
    SortOrder.Descending
)
```

### Status Badge Color

```
// Color property of status label
Switch(
    ThisItem.Status.Value,
    "PENDING",  Color.Orange,
    "APPROVED", Color.Green,
    "REJECTED", Color.Red,
    "CANCELLED", Color.Gray,
    Color.DarkGray
)
```

### Cancel Button (only for PENDING requests)

```
// Visible property
ThisItem.Status.Value = "PENDING"

// OnSelect
Patch(
    Solicitacoes_Ferias,
    ThisItem,
    {
        Status: {Value: "CANCELLED"}
    }
);
Notify("Solicitação cancelada.", NotificationType.Warning);
```

---

## 6. Screen 4: Approvals (Manager only)

### Screen Visible Guard

```
// Screen OnVisible
If(!varIsManager, Navigate(scrHome, ScreenTransition.None));
```

### Pending Approvals Gallery

```
SortByColumns(
    Filter(
        Solicitacoes_Ferias,
        Email_Aprovador = varCurrentUser.Email
            && Status.Value = "PENDING"
    ),
    "Data_Criacao",
    SortOrder.Ascending
)
```

### Approve Button OnSelect

> ⚠️ **Note:** Actual approval is handled by Flow 1 (VacationApproval).  
> In the app, managers view pending requests. The approval action is via the **Teams Approvals** center where Flow 1 sends the request.

```
// If you want an in-app approve (alternative to Teams Approvals):
Patch(
    Solicitacoes_Ferias,
    ThisItem,
    {
        Status: {Value: "APPROVED"},
        Data_Aprovacao: Now()
    }
);

// Deduct balance
With(
    {currentBalance: LookUp(Saldo_Ferias, Email_Colaborador = ThisItem.Email_Colaborador)},
    Patch(
        Saldo_Ferias,
        currentBalance,
        {
            Saldo_Dias: currentBalance.Saldo_Dias - ThisItem.Total_Dias
        }
    )
);

Notify("Solicitação aprovada!", NotificationType.Success);
```

### Reject Button OnSelect

```
Patch(
    Solicitacoes_Ferias,
    ThisItem,
    {
        Status: {Value: "REJECTED"},
        Data_Aprovacao: Now(),
        Observacoes: ThisItem.Observacoes & " | REJEITADO: " & txtRejectReason.Text
    }
);
Notify("Solicitação rejeitada.", NotificationType.Warning);
```

---

## 7. Screen 5: Team Calendar (Manager only)

### Team Vacations for Current Month

```
Filter(
    Solicitacoes_Ferias,
    Email_Aprovador = varCurrentUser.Email
        && Status.Value = "APPROVED"
        && (
            // Vacation overlaps with selected month
            (Year(Data_Inicio) = Year(varSelectedMonth) && Month(Data_Inicio) = Month(varSelectedMonth))
            || (Year(Data_Fim) = Year(varSelectedMonth) && Month(Data_Fim) = Month(varSelectedMonth))
            || (Data_Inicio < varSelectedMonth && Data_Fim > DateAdd(varSelectedMonth, 1, TimeUnit.Months))
        )
)
```

### Month Navigation

```
// Back arrow OnSelect
Set(varSelectedMonth, DateAdd(varSelectedMonth, -1, TimeUnit.Months))

// Forward arrow OnSelect
Set(varSelectedMonth, DateAdd(varSelectedMonth, 1, TimeUnit.Months))

// Month label
Text(varSelectedMonth, "mmmm yyyy", "pt-BR")
```

### Team Coverage Indicator

```
// Count people on vacation on a given date
Set(
    varOnVacationToday,
    CountRows(
        Filter(
            Solicitacoes_Ferias,
            Email_Aprovador = varCurrentUser.Email
                && Status.Value = "APPROVED"
                && Data_Inicio <= Today()
                && Data_Fim >= Today()
        )
    )
);

// Coverage percentage
Set(
    varCoverage,
    Round(
        (CountRows(colMyTeam) - varOnVacationToday) / CountRows(colMyTeam) * 100,
        0
    )
);
```

---

## 8. Common Patterns

### Loading Spinner Pattern

```
// Show spinner
Set(varLoading, true);

// ... do work ...

Set(varLoading, false);

// Spinner Visible property
varLoading
```

### Error Handling with Patch

```
IfError(
    Patch(
        Solicitacoes_Ferias,
        Defaults(Solicitacoes_Ferias),
        { /* fields */ }
    ),
    Notify("Erro ao criar solicitação. Tente novamente.", NotificationType.Error),
    Notify("Solicitação criada com sucesso!", NotificationType.Success)
);
```

### Date Formatting (Brazilian)

```
// Display date as DD/MM/YYYY
Text(ThisItem.Data_Inicio, "dd/mm/yyyy")

// Display date range
Text(ThisItem.Data_Inicio, "dd/mm") & " a " & Text(ThisItem.Data_Fim, "dd/mm/yyyy")
```

### Refresh Data After Changes

```
// After any Patch operation, refresh the data source
Refresh(Solicitacoes_Ferias);
Refresh(Saldo_Ferias);

// Or refresh cache variable
Set(
    varMyBalance,
    LookUp(Saldo_Ferias, Email_Colaborador = varCurrentUser.Email)
);
```

### Navigation with Back Button

```
// Back button OnSelect (all screens)
Back()

// Or explicit navigation
Navigate(scrHome, ScreenTransition.None)
```

---

## Data Source Connection Checklist

Before starting, connect ALL 6 SharePoint lists:

| # | List Name | Use in App |
|---|-----------|------------|
| 1 | `Colaboradores_Aprovadores` | Role detection, employee info, team mapping |
| 2 | `Solicitacoes_Ferias` | All CRUD operations on requests |
| 3 | `Saldo_Ferias` | Balance display + validation |
| 4 | `Feriados` | Holiday exclusion in day calculation |
| 5 | `Historico_Ferias` | Past vacation reference |
| 6 | `Alertas_Ferias` | Alert display (optional in MVP) |

### How to Connect:

1. In Power Apps Studio: **Data** panel (left sidebar) → **+ Add data**
2. Search for **SharePoint**
3. Enter site URL: `https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA`
4. Select all 6 lists → **Connect**
