# Phase 4 — PLAN.md
# Power Apps — Create App + Home Screen

> **Created:** 2026-04-19T01:45  
> **Phase Status:** Planned → Ready for Execution  
> **Depends on:** Phase 1 ✅ (SP lists deployed + seeded)  
> **Build Method:** Guided browser build via make.powerapps.com  
> **Reference Docs:** PowerApps-Build-Guide.md §1-2, PowerApps-Formula-Reference.md §1-3

---

## Summary

Create the Canvas App in make.powerapps.com, connect all 6 SharePoint lists, configure App.OnStart with role detection + balance loading, build the Home screen with employee/manager views, and set up the navigation shell with role-based visibility. This is the foundation for all subsequent Power Apps screens (Phases 5-8).

---

## Open Questions Resolved

| # | Question | Decision |
|---|----------|----------|
| 1 | Canvas layout: Phone or Tablet? | **Tablet** (16:9 ratio for Teams desktop embed) |
| 2 | Navigation pattern? | **Bottom tab bar** (5 emoji icons, manager-only tabs hidden) |
| 3 | Color theme? | **Indra Blue (#004E98)** as primary, Fluent 2 default base |
| 4 | App name? | **GestaoFerias** (internal name) / **Gestão Férias** (display name) |

---

## Task Breakdown

### Wave 1: App Foundation (Steps 1-4)

These are sequential pre-requisites that must happen in order.

#### Task 1.1 — Create Canvas App
- **Where:** make.powerapps.com → ColOfertasBrasilPro environment
- **What:**
  1. Click **+ Create** → **Blank app** → **Blank canvas app**
  2. Name: `GestaoFerias`
  3. Format: **Tablet**
  4. Click **Create**
- **Verify:** App opens in Power Apps Studio

#### Task 1.2 — Enable Modern Controls
- **Where:** Power Apps Studio → Settings
- **What:**
  1. Click gear icon (top right) → **Upcoming features** → **Preview**
  2. Toggle ON: **Modern controls and themes**
  3. Close settings
- **Verify:** Modern controls appear in the Insert panel

#### Task 1.3 — Connect 6 SharePoint Data Sources
- **Where:** Power Apps Studio → Data panel (left sidebar)
- **What:**
  1. Click **+ Add data** → Search **SharePoint**
  2. Enter site: `https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA`
  3. Check all 6 lists:
     - ☑️ Colaboradores_Aprovadores
     - ☑️ Solicitacoes_Ferias
     - ☑️ Saldo_Ferias
     - ☑️ Feriados
     - ☑️ Historico_Ferias
     - ☑️ Alertas_Ferias
  4. Click **Connect**
- **Verify:** All 6 lists visible in Data panel

#### Task 1.4 — Configure App.OnStart
- **Where:** App object → OnStart property
- **Formula:** (copy from `docs/PowerApps-Formula-Reference.md` §1)
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
- **Verify:** Click ⋯ → **Run OnStart** → no errors in status bar

---

### Wave 2: Screens & Navigation Shell (Steps 5-6)

#### Task 2.1 — Create 5 Screens
- **Where:** Insert → New screen → Blank
- **What:**
  1. Create 4 additional blank screens (total 5 including default)
  2. Rename screens in the tree view:
     - `scrHome`
     - `scrNewRequest`
     - `scrMyRequests`
     - `scrApprovals`
     - `scrTeamCalendar`
  3. Delete `Screen1` (original default)
  4. Set all screens Fill: `RGBA(245, 245, 245, 1)` (light gray background)
- **Verify:** 5 screens visible in tree view with correct names

#### Task 2.2 — Build Navigation Bar (on scrHome, then copy)
- **Where:** scrHome → bottom area
- **What:**
  1. Insert **Container** (horizontal) → Name: `conNavBar`
     - X: 0, Y: `Parent.Height - 60`
     - Width: `Parent.Width`, Height: 60
     - Fill: White
     - BorderColor: `RGBA(200, 200, 200, 1)`, BorderThickness: 1
     - LayoutDirection: Horizontal
     - LayoutJustifyContent: SpaceEvenly
     - LayoutAlignItems: Center

  2. Inside container, add 5 buttons:

     | Name | Text | OnSelect | Visible |
     |------|------|----------|---------|
     | `navHome` | `"🏠"` | `Navigate(scrHome, ScreenTransition.None)` | `true` |
     | `navNewReq` | `"📝"` | `Navigate(scrNewRequest, ScreenTransition.None)` | `true` |
     | `navMyReqs` | `"📋"` | `Navigate(scrMyRequests, ScreenTransition.None)` | `true` |
     | `navApprovals` | `"✅"` | `Navigate(scrApprovals, ScreenTransition.None)` | `varIsManager` |
     | `navCalendar` | `"📅"` | `Navigate(scrTeamCalendar, ScreenTransition.None)` | `varIsManager` |

  3. Style each nav button:
     - Width: 60, Height: 45
     - Fill: Transparent
     - Size: 20
     - Color: `If(App.ActiveScreen = scrHome, RGBA(0, 78, 152, 1), RGBA(128, 128, 128, 1))`
     - *(update the screen reference per button on other screens)*

  4. **Copy** `conNavBar` to all 4 other screens (Ctrl+C → click target → Ctrl+V)
  5. Update each Color formula to highlight the correct active screen

- **Verify:** Tapping nav icons navigates between screens; active icon highlighted blue

---

### Wave 3: Home Screen Content (Steps 7-10)

#### Task 3.1 — Header Container
- **Where:** scrHome → top area
- **What:**
  1. Insert **Container** (horizontal) → Name: `conHeader`
     - X: 0, Y: 0, Width: `Parent.Width`, Height: 70
     - Fill: `RGBA(0, 78, 152, 1)` (Indra Blue)
     - LayoutDirection: Horizontal
     - LayoutAlignItems: Center
     - Padding: 16
  2. Inside:
     - Label `lblAppTitle` → Text: `"🏖️ Gestão Férias"`, Color: White, Size: 22, Bold
     - Label `lblUserName` → Text: `varEmployeeRecord.Nome`, Color: White, Size: 14, Align: Right

- **Verify:** Blue header shows app title and user name

#### Task 3.2 — Balance Card
- **Where:** scrHome → below header
- **What:**
  1. Insert **Container** (vertical) → Name: `conBalanceCard`
     - X: 24, Y: 90, Width: 380, Height: 200
     - Fill: White, BorderRadius: 12, DropShadow: Medium
     - Padding: 20
  2. Inside, add labels:

     | Name | Text | Size | Color | Weight |
     |------|------|------|-------|--------|
     | `lblBalanceTitle` | `"💰 Saldo de Férias"` | 16 | Indra Blue | Bold |
     | `lblBalanceDays` | `Text(varMyBalance.Saldo_Dias, "#,##0") & " dias"` | 36 | Indra Blue | Bold |
     | `lblBalancePeriod` | `"Período: " & varMyBalance.Periodo_Aquisitivo` | 12 | DarkGray | Normal |
     | `lblBalanceExpiry` | `"Vence: " & Text(varMyBalance.Data_Vencimento, "dd/mm/yyyy")` | 12 | DarkGray | Normal |

- **Verify:** Card shows "30 dias", acquisition period, and expiration date

#### Task 3.3 — Requests Summary Card
- **Where:** scrHome → right of balance card
- **What:**
  1. Insert **Container** (vertical) → Name: `conRequestsCard`
     - X: 420, Y: 90, Width: 380, Height: 200
     - Same styling as balance card
  2. Inside:

     | Name | Text |
     |------|------|
     | `lblReqTitle` | `"📅 Minhas Solicitações"` |
     | `lblPendingCount` | `CountRows(Filter(Solicitacoes_Ferias, Email_Colaborador = varCurrentUser.Email && Status.Value = "PENDING")) & " pendente(s)"` |
     | `lblApprovedCount` | `CountRows(Filter(Solicitacoes_Ferias, Email_Colaborador = varCurrentUser.Email && Status.Value = "APPROVED")) & " aprovada(s)"` |

- **Verify:** Card shows correct pending/approved counts (may be 0 initially)

#### Task 3.4 — Quick Action Buttons
- **Where:** scrHome → below cards
- **What:**
  1. Add 4 Modern Buttons arranged vertically:

     | Name | Text | OnSelect | Visible |
     |------|------|----------|---------|
     | `btnNewRequest` | `"📝 Nova Solicitação"` | `Navigate(scrNewRequest, ScreenTransition.None)` | `true` |
     | `btnMyRequests` | `"📋 Minhas Solicitações"` | `Navigate(scrMyRequests, ScreenTransition.None)` | `true` |
     | `btnApprovals` | `"✅ Aprovações"` | `Navigate(scrApprovals, ScreenTransition.None)` | `varIsManager` |
     | `btnTeamCalendar` | `"📅 Calendário do Time"` | `Navigate(scrTeamCalendar, ScreenTransition.None)` | `varIsManager` |

  2. Style each:
     - Width: 350, Height: 45, Fill: Indra Blue, Color: White, BorderRadius: 8
     - Arrange with 8px gaps starting at Y: 320

- **Verify:** All 4 buttons visible for manager, only 2 for employee; navigation works

#### Task 3.5 — Manager Panel (Conditional)
- **Where:** scrHome → below action buttons
- **What:**
  1. Insert **Container** → Name: `conManagerPanel`
     - Visible: `varIsManager`
     - X: 24, Y: 520, Width: 776, Height: 100
     - Fill: `RGBA(0, 78, 152, 0.05)`, BorderRadius: 12
  2. Inside:

     | Name | Text |
     |------|------|
     | `lblManagerTitle` | `"👔 Painel do Gestor"` |
     | `lblPendingApprovals` | `"⏳ Pendentes: " & CountRows(Filter(Solicitacoes_Ferias, Email_Aprovador = varCurrentUser.Email && Status.Value = "PENDING"))` |
     | `lblOnVacation` | `"🏖️ Em Férias Hoje: " & CountRows(Filter(Solicitacoes_Ferias, Email_Aprovador = varCurrentUser.Email && Status.Value = "APPROVED" && Data_Inicio <= Today() && Data_Fim >= Today()))` |

- **Verify:** Panel visible only for managers; shows correct counts

---

## Verification Plan

After all tasks complete, validate against Phase 4 UAT criteria:

| # | UAT Criterion | How to Verify |
|---|---------------|---------------|
| 1 | Canvas App created with Modern Controls + Fluent 2 theme | Check Settings → Upcoming features → "Modern controls" is ON |
| 2 | All 6 SharePoint lists connected | Check Data panel shows 6 lists |
| 3 | App.OnStart: role detection works | Run App.OnStart → check varIsManager value in App Monitor |
| 4 | Home shows balance card | Verify saldo, período, vencimento labels have data |
| 5 | Home shows pending requests count | Verify count label (may be 0 if no requests) |
| 6 | Manager sees quick stats | Log in as manager → verify pending/on-vacation counts |
| 7 | Navigation shows/hides manager screens | Employee: 3 nav items; Manager: 5 nav items |
| 8 | 100% PT-BR labels | Visual scan — all text in Portuguese |

### Test as Employee
1. Open app as a regular employee (non-manager)
2. Expect: Balance card ✅, Requests card ✅, 2 action buttons ✅, no manager panel ✅, 3 nav items ✅

### Test as Manager
1. Open app as someone who is `Email_Gestor` in Colaboradores_Aprovadores
2. Expect: Balance card ✅, Requests card ✅, 4 action buttons ✅, manager panel ✅, 5 nav items ✅

---

## Key Risks

| Risk | Mitigation |
|------|------------|
| SharePoint delegation warnings on `Filter()` | Use indexed columns (Email) for all filters; keep data < 500 rows |
| Modern Controls not available | Falls back to Classic controls; same formulas work |
| `User().Email` doesn't match SP records | Ensure email format matches (case-insensitive by default in SP) |
| Title field missing in SP items | Not relevant for Phase 4 (no writes), but noted for Phase 5 |

---

## Time Estimate

| Wave | Tasks | Est. Time |
|------|-------|-----------|
| Wave 1: Foundation | 4 tasks | ~20 min |
| Wave 2: Screens + Navigation | 2 tasks | ~15 min |
| Wave 3: Home Content | 5 tasks | ~30 min |
| Verification | UAT checks | ~10 min |
| **Total** | **11 tasks** | **~75 min** |

---

*Next step: Execute this plan by opening make.powerapps.com and following each task in order.*
