# 🏗️ Power Apps Build Guide — Gestão Férias

> **Type:** Canvas App (Modern Controls + Fluent 2)  
> **Screens:** 5 (Home, New Request, My Requests, Approvals, Team Calendar)  
> **Data:** 6 SharePoint Online Lists  
> **Target:** Embedded in Microsoft Teams  
> **Last Updated:** 2026-04-18

---

## Table of Contents

1. [Pre-Build Setup](#1-pre-build-setup)
2. [Screen 1: Home (scrHome)](#2-screen-1-home)
3. [Screen 2: New Request (scrNewRequest)](#3-screen-2-new-request)
4. [Screen 3: My Requests (scrMyRequests)](#4-screen-3-my-requests)
5. [Screen 4: Approvals (scrApprovals)](#5-screen-4-approvals)
6. [Screen 5: Team Calendar (scrTeamCalendar)](#6-screen-5-team-calendar)
7. [Navigation Bar (component)](#7-navigation-bar)
8. [Theme & Styling](#8-theme--styling)
9. [Testing Checklist](#9-testing-checklist)
10. [Deploy to Teams](#10-deploy-to-teams)

---

## 1. Pre-Build Setup

### Step 1.1: Create the Canvas App

1. Go to [make.powerapps.com](https://make.powerapps.com)
2. Select environment: **ColOfertasBrasilPro**
3. Click **+ Create** → **Blank app** → **Blank canvas app**
4. Name: `GestaoFerias`
5. Format: **Tablet** (for Teams embed — 16:9 ratio)
6. Click **Create**

### Step 1.2: Enable Modern Controls

1. **Settings** (gear icon, top right) → **Upcoming features** → **Preview**
2. Toggle ON: **Modern controls and themes**
3. Close settings

### Step 1.3: Connect Data Sources

1. Left sidebar → **Data** icon (cylinder) → **+ Add data**
2. Search: `SharePoint`
3. Enter site URL:
   ```
   https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA
   ```
4. Select ALL 6 lists:
   - ☑️ Colaboradores_Aprovadores
   - ☑️ Solicitacoes_Ferias
   - ☑️ Saldo_Ferias
   - ☑️ Feriados
   - ☑️ Historico_Ferias
   - ☑️ Alertas_Ferias
5. Click **Connect**

### Step 1.4: App.OnStart — Global Variables

Select the **App** object (left tree view) → **OnStart** property:

```
// 1. Cache current user
Set(varCurrentUser, User());

// 2. Find employee record
Set(
    varEmployeeRecord,
    LookUp(
        Colaboradores_Aprovadores,
        Email = varCurrentUser.Email
    )
);

// 3. Detect if user is a manager
Set(
    varIsManager,
    CountRows(
        Filter(
            Colaboradores_Aprovadores,
            Email_Gestor = varCurrentUser.Email
        )
    ) > 0
);

// 4. Cache balance
Set(
    varMyBalance,
    LookUp(
        Saldo_Ferias,
        Email_Colaborador = varCurrentUser.Email
    )
);

// 5. Cache team (for managers)
If(
    varIsManager,
    ClearCollect(
        colMyTeam,
        Filter(
            Colaboradores_Aprovadores,
            Email_Gestor = varCurrentUser.Email && Ativo = true
        )
    )
);

// 6. Initialize selected month for calendar
Set(varSelectedMonth, Today());
```

### Step 1.5: Create 5 Screens

1. **Insert** → **New screen** → **Blank** (repeat 4 more times)
2. Rename screens (double-click in tree view):
   - `scrHome`
   - `scrNewRequest`
   - `scrMyRequests`
   - `scrApprovals`
   - `scrTeamCalendar`
3. Delete the default `Screen1` if it exists

---

## 2. Screen 1: Home (scrHome)

> **Purpose:** Dashboard with balance card, quick actions, and manager stats.

### Layout Overview

```
┌─────────────────────────────────────────────────────────┐
│  🏖️ Gestão Férias                    [user name/photo]  │  ← Header
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────┐  ┌──────────────────┐              │
│  │ 💰 Saldo         │  │ 📅 Solicitações   │              │
│  │                   │  │                    │              │
│  │  30 dias          │  │  2 pendentes       │              │
│  │  Período:         │  │  1 aprovada        │              │
│  │  01/06/25-31/05/26│  │                    │              │
│  │  Vence: 31/05/26  │  │                    │              │
│  └─────────────────┘  └──────────────────┘              │
│                                                         │
│  ┌──── Quick Actions ────────────────────┐              │
│  │  [📝 Nova Solicitação]                 │              │
│  │  [📋 Minhas Solicitações]              │              │
│  │  [✅ Aprovações]        ← manager only │              │
│  │  [📅 Calendário Time]  ← manager only │              │
│  └────────────────────────────────────────┘              │
│                                                         │
│  ┌──── Manager Panel (if varIsManager) ──┐              │
│  │  ⏳ Pendentes: 3  |  🏖️ Em Férias: 1   │              │
│  └────────────────────────────────────────┘              │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  [🏠]     [📝]     [📋]     [✅]     [📅]              │  ← NavBar
└─────────────────────────────────────────────────────────┘
```

### Step-by-Step Build

#### 2.1 Header Container

1. **Insert** → **Container** (horizontal layout)
2. Properties:
   - **Name:** `conHeader`
   - **X:** 0, **Y:** 0, **Width:** Parent.Width, **Height:** 70
   - **Fill:** `RGBA(0, 78, 152, 1)` (Indra Blue)
   - **LayoutDirection:** Horizontal
   - **LayoutAlignItems:** Center
   - **Padding:** 16

3. Inside the container, add:
   - **Label** → Name: `lblAppTitle`
     - **Text:** `"🏖️ Gestão Férias"`
     - **Color:** White
     - **Size:** 22
     - **FontWeight:** Bold
   - **Label** → Name: `lblUserName`
     - **Text:** `varEmployeeRecord.Nome`
     - **Color:** White
     - **Size:** 14
     - **Align:** Right

#### 2.2 Balance Card

1. **Insert** → **Container** (vertical layout)
2. Properties:
   - **Name:** `conBalanceCard`
   - **X:** 24, **Y:** 90, **Width:** 380, **Height:** 200
   - **Fill:** White
   - **BorderColor:** `RGBA(0, 78, 152, 0.2)`
   - **BorderThickness:** 1
   - **RadiusTopLeft/TopRight/BottomLeft/BottomRight:** 12
   - **DropShadow:** Medium
   - **Padding:** 20

3. Inside, add labels:

| Control | Name | Text | Size | Color | FontWeight |
|---------|------|------|------|-------|------------|
| Label | `lblBalanceTitle` | `"💰 Saldo de Férias"` | 16 | `RGBA(0,78,152,1)` | Bold |
| Label | `lblBalanceDays` | `Text(varMyBalance.Saldo_Dias, "#,##0") & " dias"` | 36 | `RGBA(0,78,152,1)` | Bold |
| Label | `lblBalancePeriod` | `"Período: " & varMyBalance.Periodo_Aquisitivo` | 12 | DarkGray | Normal |
| Label | `lblBalanceExpiry` | `"Vence: " & Text(varMyBalance.Data_Vencimento, "dd/mm/yyyy")` | 12 | DarkGray | Normal |

#### 2.3 Requests Summary Card

1. **Insert** → **Container** (same pattern as above)
   - **Name:** `conRequestsCard`
   - **X:** 420, **Y:** 90, **Width:** 380, **Height:** 200

2. Inside:

| Control | Name | Text |
|---------|------|------|
| Label | `lblReqTitle` | `"📅 Minhas Solicitações"` |
| Label | `lblPendingCount` | `CountRows(Filter(Solicitacoes_Ferias, Email_Colaborador = varCurrentUser.Email && Status.Value = "PENDING")) & " pendente(s)"` |
| Label | `lblApprovedCount` | `CountRows(Filter(Solicitacoes_Ferias, Email_Colaborador = varCurrentUser.Email && Status.Value = "APPROVED")) & " aprovada(s)"` |

#### 2.4 Quick Action Buttons

Add 4 buttons (Modern Button control):

| # | Name | Text | OnSelect | Visible |
|---|------|------|----------|---------|
| 1 | `btnNewRequest` | `"📝 Nova Solicitação"` | `Navigate(scrNewRequest, ScreenTransition.None)` | `true` |
| 2 | `btnMyRequests` | `"📋 Minhas Solicitações"` | `Navigate(scrMyRequests, ScreenTransition.None)` | `true` |
| 3 | `btnApprovals` | `"✅ Aprovações"` | `Navigate(scrApprovals, ScreenTransition.None)` | `varIsManager` |
| 4 | `btnTeamCalendar` | `"📅 Calendário do Time"` | `Navigate(scrTeamCalendar, ScreenTransition.None)` | `varIsManager` |

Style each button:
- **Width:** 350, **Height:** 45
- **Fill:** `RGBA(0, 78, 152, 1)`
- **Color:** White
- **BorderRadius:** 8
- Arrange vertically with 8px gap, starting at **Y:** 320

#### 2.5 Manager Panel (conditional)

1. **Insert** → **Container**
   - **Name:** `conManagerPanel`
   - **Visible:** `varIsManager`
   - **X:** 24, **Y:** 520, **Width:** 776, **Height:** 100
   - **Fill:** `RGBA(0, 78, 152, 0.05)`
   - **BorderRadius:** 12

2. Inside, add:

| Control | Name | Text |
|---------|------|------|
| Label | `lblManagerTitle` | `"👔 Painel do Gestor"` |
| Label | `lblPendingApprovals` | `"⏳ Pendentes: " & CountRows(Filter(Solicitacoes_Ferias, Email_Aprovador = varCurrentUser.Email && Status.Value = "PENDING"))` |
| Label | `lblOnVacation` | `"🏖️ Em Férias Hoje: " & CountRows(Filter(Solicitacoes_Ferias, Email_Aprovador = varCurrentUser.Email && Status.Value = "APPROVED" && Data_Inicio <= Today() && Data_Fim >= Today()))` |

---

## 3. Screen 2: New Request (scrNewRequest)

> **Purpose:** Submit vacation request with all business rule validations + conflict detection.

### Layout Overview

```
┌─────────────────────────────────────────────────────────┐
│  ← Voltar    📝 Nova Solicitação                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  📅 Data Início:    [  date picker  ]                   │
│  📅 Data Fim:       [  date picker  ]                   │
│                                                         │
│  ┌── Resumo ─────────────────────────┐                  │
│  │  Total: 15 dias úteis              │                  │
│  │  Saldo após: 15 dias              │                  │
│  └────────────────────────────────────┘                  │
│                                                         │
│  ⚠️ ERRO: Antecedência mínima 45 dias   ← if invalid   │
│  ⚠️ ERRO: Mínimo 5 dias                 ← if invalid   │
│                                                         │
│  ┌── ⚠️ Conflitos ──────────────────┐   ← if conflict  │
│  │  João Silva — 10/07 a 20/07       │                  │
│  │  Maria Santos — 15/07 a 25/07     │                  │
│  └────────────────────────────────────┘                  │
│                                                         │
│  📝 Observações:  [  text input  ]                      │
│                                                         │
│  [       ENVIAR SOLICITAÇÃO        ]                    │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  [🏠]     [📝]     [📋]     [✅]     [📅]              │
└─────────────────────────────────────────────────────────┘
```

### Step-by-Step Build

#### 3.1 Header with Back Button

1. **Container** (horizontal) → Name: `conHeaderNewReq`
   - Same style as Home header
2. Inside:
   - **Button** → Name: `btnBack1`, Text: `"← Voltar"`, OnSelect: `Back()`
   - **Label** → `"📝 Nova Solicitação"`, Color: White, Size: 20, Bold

#### 3.2 Date Pickers

1. **Insert** → **Date Picker** (modern)
   - **Name:** `dtpStartDate`
   - **Label:** `"📅 Data Início"`
   - **X:** 24, **Y:** 90, **Width:** 350
   - **MinDate:** `DateAdd(Today(), 45, TimeUnit.Days)`

2. **Insert** → **Date Picker** (modern)
   - **Name:** `dtpEndDate`
   - **Label:** `"📅 Data Fim"`
   - **X:** 24, **Y:** 170, **Width:** 350
   - **MinDate:** `dtpStartDate.SelectedDate`

3. **OnChange of BOTH date pickers** (add to each's OnChange):

```
// Calculate business days
Set(varStartDate, dtpStartDate.SelectedDate);
Set(varEndDate, dtpEndDate.SelectedDate);
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

// Approximate weekend days
Set(
    varWeekendDays,
    RoundDown(varCalendarDays / 7, 0) * 2
);

// Business days
Set(varBusinessDays, Max(varCalendarDays - varWeekendDays - varHolidaysInRange, 0));

// Run conflict detection
ClearCollect(
    colConflicts,
    Filter(
        Solicitacoes_Ferias,
        Email_Aprovador = varEmployeeRecord.Email_Gestor &&
        Status.Value in ["APPROVED", "PENDING"] &&
        Email_Colaborador <> varCurrentUser.Email &&
        Data_Inicio <= varEndDate &&
        Data_Fim >= varStartDate
    )
);
Set(varHasConflict, CountRows(colConflicts) > 0);
```

#### 3.3 Summary Section

**Container** → Name: `conSummary`
- **Visible:** `!IsBlank(varStartDate) && !IsBlank(varEndDate)`
- **Fill:** `RGBA(0, 128, 0, 0.05)`, **BorderRadius:** 8

Inside:

| Label | Text |
|-------|------|
| `lblTotalDays` | `"📊 Total: " & varBusinessDays & " dias úteis"` |
| `lblRemainingBalance` | `"💰 Saldo após: " & (varMyBalance.Saldo_Dias - varBusinessDays) & " dias"` |

#### 3.4 Validation Error Messages

Add error labels (all initially hidden):

| Name | Text | Visible (shows error when true) |
|------|------|---------------------------------|
| `lblErr45Days` | `"⚠️ A solicitação deve ser feita com no mínimo 45 dias de antecedência."` | `!IsBlank(varStartDate) && DateDiff(Today(), varStartDate, TimeUnit.Days) < 45` |
| `lblErrMin5` | `"⚠️ O período mínimo é de 5 dias úteis."` | `!IsBlank(varEndDate) && varBusinessDays < 5` |
| `lblErrMax30` | `"⚠️ O período máximo é de 30 dias úteis."` | `!IsBlank(varEndDate) && varBusinessDays > 30` |
| `lblErrBalance` | `"⚠️ Saldo insuficiente. Disponível: " & varMyBalance.Saldo_Dias & " dias."` | `!IsBlank(varEndDate) && varBusinessDays > varMyBalance.Saldo_Dias` |

Style all error labels:
- **Color:** `RGBA(200, 0, 0, 1)` (red)
- **Size:** 12
- **Fill:** `RGBA(255, 230, 230, 1)` (light red background)
- **Padding:** 8, **BorderRadius:** 4

#### 3.5 Conflict Warning Section

1. **Container** → Name: `conConflicts`
   - **Visible:** `varHasConflict`
   - **Fill:** `RGBA(255, 165, 0, 0.1)` (light orange)
   - **BorderColor:** Orange
   - **BorderThickness:** 1
   - **BorderRadius:** 8

2. Inside:
   - **Label**: `"⚠️ Conflitos Detectados"`, Color: Orange, Bold
   - **Gallery** (vertical) → Name: `galConflicts`
     - **Items:** `colConflicts`
     - **Template Height:** 35
     - Inside template, add label:
       ```
       LookUp(Colaboradores_Aprovadores, Email = ThisItem.Email_Colaborador).Nome &
       " — " & Text(ThisItem.Data_Inicio, "dd/mm") &
       " a " & Text(ThisItem.Data_Fim, "dd/mm")
       ```

#### 3.6 Notes Field

1. **Insert** → **Text Input** (modern, multiline)
   - **Name:** `txtNotes`
   - **Label:** `"📝 Observações (opcional)"`
   - **Mode:** Multiline
   - **Width:** 750, **Height:** 80

#### 3.7 Submit Button

1. **Insert** → **Button** (modern)
   - **Name:** `btnSubmit`
   - **Text:** `"ENVIAR SOLICITAÇÃO"`
   - **Width:** 350, **Height:** 50
   - **Fill:** `RGBA(0, 128, 0, 1)` (green)
   - **Color:** White, **Size:** 16, Bold

2. **DisplayMode:**

```
If(
    !IsBlank(varStartDate) && !IsBlank(varEndDate) &&
    varEndDate > varStartDate &&
    DateDiff(Today(), varStartDate, TimeUnit.Days) >= 45 &&
    varBusinessDays >= 5 &&
    varBusinessDays <= 30 &&
    varBusinessDays <= varMyBalance.Saldo_Dias,
    DisplayMode.Edit,
    DisplayMode.Disabled
)
```

3. **OnSelect:**

```
Set(varSubmitting, true);

// ⚠️ Title is REQUIRED — Flow trigger fails without it
IfError(
    Patch(
        Solicitacoes_Ferias,
        Defaults(Solicitacoes_Ferias),
        {
            Title: "Ferias - " & varEmployeeRecord.Nome,
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
    ),
    // Error
    Notify("❌ Erro ao criar solicitação. Tente novamente.", NotificationType.Error);
    Set(varSubmitting, false),
    // Success
    Set(
        varMyBalance,
        LookUp(Saldo_Ferias, Email_Colaborador = varCurrentUser.Email)
    );
    Notify("✅ Solicitação enviada! Aguardando aprovação do gestor.", NotificationType.Success);
    Set(varSubmitting, false);
    Reset(dtpStartDate);
    Reset(dtpEndDate);
    Reset(txtNotes);
    Navigate(scrMyRequests, ScreenTransition.None)
);
```

---

## 4. Screen 3: My Requests (scrMyRequests)

> **Purpose:** View all requests with status badges + cancel pending ones.

### Layout Overview

```
┌─────────────────────────────────────────────────────────┐
│  ← Voltar    📋 Minhas Solicitações                     │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────────────────────────────────────┐    │
│  │ 10/07 - 25/07/2026  │ 15 dias │ 🟡 PENDENTE [X]│    │
│  ├─────────────────────────────────────────────────┤    │
│  │ 02/08 - 10/08/2026  │  8 dias │ 🟢 APROVADO    │    │
│  ├─────────────────────────────────────────────────┤    │
│  │ 15/03 - 25/03/2026  │ 10 dias │ 🔴 REJEITADO   │    │
│  └─────────────────────────────────────────────────┘    │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  [🏠]     [📝]     [📋]     [✅]     [📅]              │
└─────────────────────────────────────────────────────────┘
```

### Step-by-Step Build

#### 4.1 Header

Same pattern as other screens:
- Back button + title `"📋 Minhas Solicitações"`

#### 4.2 Requests Gallery

1. **Insert** → **Gallery** (Vertical, blank template)
   - **Name:** `galMyRequests`
   - **Items:**
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
   - **X:** 24, **Y:** 90, **Width:** Parent.Width - 48
   - **Height:** Parent.Height - 160 (leave space for nav)
   - **TemplateSize:** 80
   - **TemplatePadding:** 4

2. Inside template, add:

| Control | Name | Text / Properties |
|---------|------|-------------------|
| Label | `lblReqPeriod` | `Text(ThisItem.Data_Inicio, "dd/mm") & " - " & Text(ThisItem.Data_Fim, "dd/mm/yyyy")` |
| Label | `lblReqDays` | `ThisItem.Total_Dias & " dias"` |
| Label | `lblReqStatus` | `ThisItem.Status.Value` |
| Button | `btnCancel` | Text: `"✕"`, see below |

3. **Status badge color** (lblReqStatus.Color):
```
Switch(
    ThisItem.Status.Value,
    "PENDING",   RGBA(200, 150, 0, 1),
    "APPROVED",  RGBA(0, 128, 0, 1),
    "REJECTED",  RGBA(200, 0, 0, 1),
    "CANCELLED", RGBA(128, 128, 128, 1),
    Color.DarkGray
)
```

4. **Status badge Fill** (lblReqStatus.Fill):
```
Switch(
    ThisItem.Status.Value,
    "PENDING",   RGBA(255, 240, 200, 1),
    "APPROVED",  RGBA(220, 255, 220, 1),
    "REJECTED",  RGBA(255, 220, 220, 1),
    "CANCELLED", RGBA(230, 230, 230, 1),
    RGBA(240, 240, 240, 1)
)
```

5. **Cancel button** (`btnCancel`):
   - **Visible:** `ThisItem.Status.Value = "PENDING"`
   - **Fill:** `RGBA(200, 0, 0, 1)`, **Color:** White
   - **Width:** 40, **Height:** 30, **BorderRadius:** 4
   - **OnSelect:**
     ```
     Patch(
         Solicitacoes_Ferias,
         ThisItem,
         {
             Status: {Value: "CANCELLED"}
         }
     );
     Notify("Solicitação cancelada.", NotificationType.Warning);
     Refresh(Solicitacoes_Ferias);
     ```

#### 4.3 Empty State

Add a label visible when there are no requests:
- **Name:** `lblNoRequests`
- **Text:** `"Você ainda não tem solicitações de férias."`
- **Visible:** `CountRows(galMyRequests.AllItems) = 0`
- **Align:** Center, **Y:** 300, **Color:** Gray

---

## 5. Screen 4: Approvals (scrApprovals)

> **Purpose:** Manager view — approve or reject pending requests.  
> **Access:** Manager only (redirect if not manager).

### Screen.OnVisible

```
If(!varIsManager, Navigate(scrHome, ScreenTransition.None));
```

### Layout Overview

```
┌─────────────────────────────────────────────────────────┐
│  ← Voltar    ✅ Aprovações (3 pendentes)                │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────────────────────────────────────┐    │
│  │ João Silva              10/07-25/07  15 dias    │    │
│  │ ⚠️ Conflito com Maria                           │    │
│  │ Obs: Viagem familiar                            │    │
│  │              [✅ Aprovar]  [❌ Rejeitar]          │    │
│  ├─────────────────────────────────────────────────┤    │
│  │ Ana Costa               02/08-10/08   8 dias    │    │
│  │ Sem conflitos                                   │    │
│  │              [✅ Aprovar]  [❌ Rejeitar]          │    │
│  └─────────────────────────────────────────────────┘    │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  [🏠]     [📝]     [📋]     [✅]     [📅]              │
└─────────────────────────────────────────────────────────┘
```

### Step-by-Step Build

#### 5.1 Header

- Title: `"✅ Aprovações (" & CountRows(Filter(Solicitacoes_Ferias, Email_Aprovador = varCurrentUser.Email && Status.Value = "PENDING")) & " pendentes)"`

#### 5.2 Pending Approvals Gallery

1. **Insert** → **Gallery** (Vertical, blank template)
   - **Name:** `galApprovals`
   - **Items:**
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
   - **TemplateSize:** 130

2. Inside template:

| Control | Name | Text |
|---------|------|------|
| Label | `lblApprName` | `LookUp(Colaboradores_Aprovadores, Email = ThisItem.Email_Colaborador).Nome` |
| Label | `lblApprPeriod` | `Text(ThisItem.Data_Inicio, "dd/mm") & " - " & Text(ThisItem.Data_Fim, "dd/mm/yyyy") & "  (" & ThisItem.Total_Dias & " dias)"` |
| Label | `lblApprConflict` | `If(ThisItem.Tem_Conflito, "⚠️ Possui conflito com a equipe", "✅ Sem conflitos")` |
| Label | `lblApprNotes` | `If(!IsBlank(ThisItem.Observacoes), "📝 " & ThisItem.Observacoes, "")` |
| Button | `btnApprove` | (see below) |
| Button | `btnReject` | (see below) |

3. **Approve Button** (`btnApprove`):
   - **Text:** `"✅ Aprovar"`
   - **Fill:** `RGBA(0, 128, 0, 1)`, **Color:** White
   - **OnSelect:**
     ```
     // Update request status
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

     Notify("✅ Solicitação de " & LookUp(Colaboradores_Aprovadores, Email = ThisItem.Email_Colaborador).Nome & " aprovada!", NotificationType.Success);
     Refresh(Solicitacoes_Ferias);
     Refresh(Saldo_Ferias);
     ```

4. **Reject Button** (`btnReject`):
   - **Text:** `"❌ Rejeitar"`
   - **Fill:** `RGBA(200, 0, 0, 1)`, **Color:** White
   - **OnSelect:**
     ```
     // Show reject reason dialog
     Set(varShowRejectDialog, true);
     Set(varRejectItem, ThisItem);
     ```

#### 5.3 Reject Reason Dialog (overlay)

1. **Container** → Name: `conRejectDialog`
   - **Visible:** `varShowRejectDialog`
   - **Fill:** `RGBA(0, 0, 0, 0.5)` (overlay backdrop)
   - **X:** 0, **Y:** 0, **Width:** Parent.Width, **Height:** Parent.Height

2. Inside, another **Container** (white card):
   - **Width:** 400, **Height:** 250
   - **X:** (Parent.Width - 400) / 2, **Y:** (Parent.Height - 250) / 2
   - **Fill:** White, **BorderRadius:** 12, **DropShadow:** Heavy

3. Inside white card:
   - **Label:** `"Motivo da Rejeição"`, Bold, Size: 16
   - **Text Input** → Name: `txtRejectReason`, Multiline, Height: 80
   - **Button** `"Confirmar Rejeição"`, OnSelect:
     ```
     Patch(
         Solicitacoes_Ferias,
         varRejectItem,
         {
             Status: {Value: "REJECTED"},
             Data_Aprovacao: Now(),
             Observacoes: varRejectItem.Observacoes & " | REJEITADO: " & txtRejectReason.Text
         }
     );
     Set(varShowRejectDialog, false);
     Reset(txtRejectReason);
     Notify("Solicitação rejeitada.", NotificationType.Warning);
     Refresh(Solicitacoes_Ferias);
     ```
   - **Button** `"Cancelar"`, OnSelect: `Set(varShowRejectDialog, false)`

---

## 6. Screen 5: Team Calendar (scrTeamCalendar)

> **Purpose:** Manager-only visual view of team vacations by month.

### Screen.OnVisible

```
If(!varIsManager, Navigate(scrHome, ScreenTransition.None));
```

### Layout Overview

```
┌─────────────────────────────────────────────────────────┐
│  ← Voltar    📅 Calendário do Time                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│       [◄]     Julho 2026     [►]                        │
│                                                         │
│  Cobertura do Time: 85% (11/13 disponíveis)             │
│                                                         │
│  ┌─────────────────────────────────────────────────┐    │
│  │ João Silva       |██████████████|     15 dias   │    │
│  │ Maria Santos     |      ██████████| 10 dias     │    │
│  │ Ana Costa        |             ████|  5 dias     │    │
│  └─────────────────────────────────────────────────┘    │
│                                                         │
│  📊 Total do Mês: 3 colaboradores de férias             │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  [🏠]     [📝]     [📋]     [✅]     [📅]              │
└─────────────────────────────────────────────────────────┘
```

### Step-by-Step Build

#### 6.1 Month Navigation

1. **Container** (horizontal) → center aligned
2. Inside:
   - **Button** `"◄"` → OnSelect: `Set(varSelectedMonth, DateAdd(varSelectedMonth, -1, TimeUnit.Months))`
   - **Label** → Text: `Upper(Text(varSelectedMonth, "mmmm yyyy", "pt-BR"))`
   - **Button** `"►"` → OnSelect: `Set(varSelectedMonth, DateAdd(varSelectedMonth, 1, TimeUnit.Months))`

#### 6.2 Coverage Indicator

1. **Label** → Name: `lblCoverage`
   - **Text:**
     ```
     With(
         {
             onVacation: CountRows(
                 Filter(
                     Solicitacoes_Ferias,
                     Email_Aprovador = varCurrentUser.Email &&
                     Status.Value = "APPROVED" &&
                     Data_Inicio <= Today() &&
                     Data_Fim >= Today()
                 )
             ),
             totalTeam: CountRows(colMyTeam)
         },
         "Cobertura: " & Round((totalTeam - onVacation) / totalTeam * 100, 0) &
         "% (" & (totalTeam - onVacation) & "/" & totalTeam & " disponíveis)"
     )
     ```

#### 6.3 Team Vacations Gallery

1. **Insert** → **Gallery** (Vertical, blank template)
   - **Name:** `galTeamCalendar`
   - **Items:**
     ```
     Filter(
         Solicitacoes_Ferias,
         Email_Aprovador = varCurrentUser.Email &&
         Status.Value = "APPROVED" &&
         (
             (Month(Data_Inicio) = Month(varSelectedMonth) && Year(Data_Inicio) = Year(varSelectedMonth)) ||
             (Month(Data_Fim) = Month(varSelectedMonth) && Year(Data_Fim) = Year(varSelectedMonth)) ||
             (Data_Inicio < varSelectedMonth && Data_Fim > DateAdd(varSelectedMonth, 1, TimeUnit.Months))
         )
     )
     ```
   - **TemplateSize:** 50

2. Inside template:

| Control | Text |
|---------|------|
| Label (name) | `LookUp(Colaboradores_Aprovadores, Email = ThisItem.Email_Colaborador).Nome` |
| Label (period) | `Text(ThisItem.Data_Inicio, "dd/mm") & " - " & Text(ThisItem.Data_Fim, "dd/mm")` |
| Label (days) | `ThisItem.Total_Dias & " dias"` |

#### 6.4 Monthly Summary

```
"📊 Total: " & CountRows(galTeamCalendar.AllItems) & " colaborador(es) de férias em " &
Text(varSelectedMonth, "mmmm", "pt-BR")
```

---

## 7. Navigation Bar

> Add this to the BOTTOM of every screen for consistent navigation.

### Build Once, Copy to All Screens

1. **Container** (horizontal) → Name: `conNavBar`
   - **X:** 0, **Y:** Parent.Height - 60
   - **Width:** Parent.Width, **Height:** 60
   - **Fill:** White
   - **BorderColor:** `RGBA(200, 200, 200, 1)` (top border line)
   - **BorderThickness:** 1
   - **LayoutDirection:** Horizontal
   - **LayoutJustifyContent:** SpaceEvenly
   - **LayoutAlignItems:** Center

2. Inside, add 5 buttons:

| Name | Text | OnSelect | Visible |
|------|------|----------|---------|
| `navHome` | `"🏠"` | `Navigate(scrHome, ScreenTransition.None)` | `true` |
| `navNewReq` | `"📝"` | `Navigate(scrNewRequest, ScreenTransition.None)` | `true` |
| `navMyReqs` | `"📋"` | `Navigate(scrMyRequests, ScreenTransition.None)` | `true` |
| `navApprovals` | `"✅"` | `Navigate(scrApprovals, ScreenTransition.None)` | `varIsManager` |
| `navCalendar` | `"📅"` | `Navigate(scrTeamCalendar, ScreenTransition.None)` | `varIsManager` |

Style each nav button:
- **Width:** 60, **Height:** 45
- **Fill:** Transparent
- **Size:** 20
- **Color:** Change to Indra Blue when on that screen:
  ```
  If(App.ActiveScreen = scrHome, RGBA(0, 78, 152, 1), RGBA(128, 128, 128, 1))
  ```

3. **Copy** `conNavBar` to all 5 screens (Ctrl+C → click target screen → Ctrl+V)

---

## 8. Theme & Styling

### Color Palette

| Use | Color | Hex | RGBA |
|-----|-------|-----|------|
| Primary (Indra Blue) | 🟦 | `#004E98` | `RGBA(0, 78, 152, 1)` |
| Primary Light | 🔵 | `#E8F0FE` | `RGBA(232, 240, 254, 1)` |
| Success | 🟢 | `#008000` | `RGBA(0, 128, 0, 1)` |
| Warning | 🟡 | `#C89600` | `RGBA(200, 150, 0, 1)` |
| Error | 🔴 | `#C80000` | `RGBA(200, 0, 0, 1)` |
| Background | ⚪ | `#F5F5F5` | `RGBA(245, 245, 245, 1)` |
| Card | ⬜ | `#FFFFFF` | `RGBA(255, 255, 255, 1)` |
| Text Primary | ⬛ | `#333333` | `RGBA(51, 51, 51, 1)` |
| Text Secondary | 🔘 | `#666666` | `RGBA(102, 102, 102, 1)` |

### Screen Background

Set on all screens:
- **Fill:** `RGBA(245, 245, 245, 1)` (light gray)

### Card Pattern

For all card containers:
- **Fill:** White
- **BorderRadius:** 12
- **DropShadow:** Medium (or set `Shadow` property)
- **Padding:** 16

### Font Standards

| Element | Size | Weight |
|---------|------|--------|
| Screen title | 20-22 | Bold |
| Card title | 16 | Bold |
| Body text | 14 | Normal |
| Secondary text | 12 | Normal |
| Big numbers (balance) | 36 | Bold |
| Buttons | 14-16 | Semibold |

---

## 9. Testing Checklist

### Employee Role Tests

| # | Test | Expected | ✅ |
|---|------|----------|---|
| 1 | Open app as employee | Home shows balance, no manager buttons | ☐ |
| 2 | Submit request with valid dates (45+ days, 5-30 days) | Success, navigates to My Requests | ☐ |
| 3 | Submit with < 45 days advance | Button disabled, error shown | ☐ |
| 4 | Submit with < 5 days | Button disabled, error shown | ☐ |
| 5 | Submit with > 30 days | Button disabled, error shown | ☐ |
| 6 | Submit exceeding balance | Button disabled, error shown | ☐ |
| 7 | Dates cause conflict with team | Warning shown, can still submit | ☐ |
| 8 | View My Requests | List shows with correct status colors | ☐ |
| 9 | Cancel a PENDING request | Status changes to CANCELLED | ☐ |
| 10 | Cancel button hidden for APPROVED | Only PENDING shows cancel | ☐ |

### Manager Role Tests

| # | Test | Expected | ✅ |
|---|------|----------|---|
| 11 | Open app as manager | Shows manager panel + nav buttons | ☐ |
| 12 | Approvals screen shows pending items | Gallery filtered correctly | ☐ |
| 13 | Approve a request | Status → APPROVED, balance deducted | ☐ |
| 14 | Reject with reason | Status → REJECTED, reason saved | ☐ |
| 15 | Team Calendar shows month view | Correct vacations for selected month | ☐ |
| 16 | Month navigation works | Month changes, data refreshes | ☐ |

### Integration Tests

| # | Test | Expected | ✅ |
|---|------|----------|---|
| 17 | Submit triggers VacationApproval flow | Approval card appears in Teams | ☐ |
| 18 | Flow approval updates SP list | Status = APPROVED, balance deducted | ☐ |
| 19 | Teams notification received | Employee gets approval notification | ☐ |

---

## 10. Deploy to Teams

### Step 10.1: Publish the App

1. **File** → **Save** (Ctrl+S)
2. **File** → **Publish** → **Publish this version**

### Step 10.2: Add to Teams

1. In Power Apps Studio: **File** → **Settings** → **General**
2. Set **App name**: `Gestão Férias`
3. Set **Description**: `Gerenciamento de férias - consultar saldo, solicitar, aprovar`
4. Set **Icon**: Upload a vacation icon (🏖️)

### Step 10.3: Create Teams Tab

**Option A — Personal App (recommended):**
1. Go to [Teams Admin Center](https://admin.teams.microsoft.com)
2. **Teams apps** → **Manage apps** → **Upload** → upload the Power Apps package

**Option B — Quick embed:**
1. In any Teams channel → **+** tab → search for **Power Apps**
2. Select your `GestaoFerias` app
3. Save

### Step 10.4: Share with Users

1. In [make.powerapps.com](https://make.powerapps.com) → **Apps**
2. Click **⋮** on `GestaoFerias` → **Share**
3. Add all 13 employees from Colaboradores_Aprovadores
4. Set permission: **User** (not Co-owner)

---

## 📁 Quick Reference Files

| Document | Content |
|----------|---------|
| [PowerApps-Formula-Reference.md](./PowerApps-Formula-Reference.md) | All Power Fx formulas (copy-pasteable) |
| [Manual_Usuario.md](./Manual_Usuario.md) | Employee user guide |
| [Guia_Gestor.md](./Guia_Gestor.md) | Manager user guide |
| [gemini.md](../gemini.md) | Project constitution — all rules |

---

> **Estimated build time:** 3-5 hours if following this guide step-by-step.  
> **Tip:** Build Screen 1 (Home) first, then Screen 3 (My Requests — simpler), then Screen 2 (New Request — complex), then Screens 4-5 (manager-only).
