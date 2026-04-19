# 🚀 Production Delivery Guide: How Reports Work Inside Teams

> **Purpose**: This document explains HOW the Gestão Férias dashboard, calendar, and reports
> are delivered to directors/managers/employees inside Microsoft Teams using production
> Microsoft solutions — no custom HTML/JS, no external hosting.

---

## ⚡ TL;DR

| What | How | License |
|------|-----|---------|
| **Vacation requests + approvals** | Power Apps canvas app (Teams tab) | M365 included |
| **Dashboard (KPIs, charts)** | Power Apps screen OR Power BI tab | M365 / Power BI Pro |
| **Team calendar** | Power Apps screen (Gallery-based grid) | M365 included |
| **Director-level analytics** | Power BI report (embedded in Teams) | Power BI Pro |
| **Notifications** | Power Automate → Teams + Email | Standard (confirmed) |
| **Approvals** | Power Automate Approvals connector | Standard (confirmed) |

---

## 📐 Architecture: What Runs Where

```
┌─────────────────────────────────────────────────────────┐
│                    MICROSOFT TEAMS                       │
│                                                         │
│  ┌─────────────────────┐  ┌──────────────────────────┐ │
│  │   Tab 1: Power App  │  │  Tab 2: Power BI Report  │ │
│  │   ─────────────────  │  │  ────────────────────── │ │
│  │ • Home (Dashboard)   │  │ • Advanced analytics     │ │
│  │ • Nova Solicitação   │  │ • 90-day forecast        │ │
│  │ • Minhas Férias      │  │ • Dept. drilldown        │ │
│  │ • Aprovações (mgr)   │  │ • Trend lines            │ │
│  │ • Calendário Equipe  │  │ • Cross-team coverage    │ │
│  └────────┬─────────────┘  └──────────┬───────────────┘ │
│           │                           │                  │
│           ▼                           ▼                  │
│  ┌─────────────────────────────────────────────────────┐ │
│  │           SharePoint Online Lists (Data)            │ │
│  │  Colaboradores | Solicitações | Saldo | Feriados    │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                         │
│  ┌─────────────────────────────────────────────────────┐ │
│  │           Power Automate (Standard)                 │ │
│  │  Flow 1: VacationApproval (on item created)         │ │
│  │  Flow 2: ScheduledAlerts (weekly recurrence)        │ │
│  └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

---

## 1️⃣ TAB 1: Power Apps Canvas App (PRIMARY)

This is the **main experience**. It replaces this HTML dashboard 1:1.

### How to Publish to Teams

1. Build the Canvas App in **make.powerapps.com** (environment: `ColOfertasBrasilPro`)
2. Connect to the 6 SharePoint lists as data sources
3. In Power Apps Studio → **File → Settings → General → App name** = "Gestão Férias"
4. **Publish** the app
5. Go to **Teams Admin Center** → **Teams apps** → **Manage apps**
6. OR in Power Apps: **File → Publish to Teams** → Select a team/channel → **Add as a Tab**

### What Each Screen Does (Power Fx)

| Screen | Dashboard View | How It Works in Power Apps |
|--------|---------------|---------------------------|
| **Home** | KPI cards + recent requests | `CountRows(Filter(Solicitacoes, Status="PENDING"))` etc. |
| **Nova Solicitação** | Form to submit request | `EditForm` + `Patch()` to Solicitacoes_Ferias |
| **Minhas Férias** | Employee's own requests | `Filter(Solicitacoes, Email_Colaborador = User().Email)` |
| **Aprovações** | Manager's pending list | `Filter(Solicitacoes, Email_Aprovador = User().Email, Status="PENDING")` |
| **Calendário** | Team calendar grid | `Gallery` with date-range layout + conditional colors |

### Role Detection (No Extra Config)

```
// In App.OnStart:
Set(varCurrentUser, User().Email);
Set(varIsManager,
    CountRows(
        Filter(Colaboradores_Aprovadores,
            Email_Gestor = varCurrentUser)
    ) > 0
);

// Then conditionally show/hide the "Aprovações" nav button:
// Button.Visible = varIsManager
```

> **Key point**: The **same app** serves both employees and managers.
> The app detects the user's role at startup and shows/hides screens accordingly.

---

## 2️⃣ TAB 2: Power BI Report (OPTIONAL — For Director/Advanced Analytics)

### When to Use Power BI vs. Power Apps

| Need | Use Power Apps | Use Power BI |
|------|---------------|-------------|
| Submit/approve requests | ✅ | ❌ |
| Simple KPIs (counts, totals) | ✅ | ✅ |
| Interactive charts with drilldown | ⚠️ limited | ✅ |
| Trend analysis over time | ❌ | ✅ |
| 90-day forecast / coverage % | ⚠️ hard | ✅ |
| Export to PDF/Excel | ❌ | ✅ |
| Schedule email reports | ❌ | ✅ (subscriptions) |

### How to Set Up Power BI with SharePoint Data

1. Open **Power BI Desktop**
2. **Get Data → SharePoint Online List**
3. Enter: `https://indra365.sharepoint.com/sites/YOUR_SITE`
4. Select lists: `Solicitacoes_Ferias`, `Colaboradores_Aprovadores`, `Saldo_Ferias`, `Feriados`
5. Build relationships in Model view (Email_Colaborador ↔ Email)
6. Create report pages:
   - **Page 1**: Dashboard (Cards + Donut + Bar chart) — mirrors our HTML dashboard
   - **Page 2**: Team Calendar (Matrix visual with dates as columns)
   - **Page 3**: Department Coverage (Stacked bar showing headcount vs. days out)
   - **Page 4**: Balance Analysis (Scatter plot: balance vs. expiry date)
7. **Publish** to Power BI Service → Workspace
8. In **Teams** → Channel → **Add a Tab** → **Power BI** → Select the report

### License Requirement

| License | Cost | What You Get |
|---------|------|-------------|
| Power BI Free | $0 | Desktop only, no sharing |
| **Power BI Pro** | **~$10/user/month** | Publish + Share + Teams embed |
| Power BI Premium Per User | ~$20/user/month | All Pro + larger datasets |

> ⚠️ If budget doesn't allow Power BI Pro, the **Power Apps dashboard screen
> covers 80% of the reporting needs** — charts are more basic but functional.

---

## 3️⃣ Alternative: SharePoint Dashboard Page (FREE, Basic)

If neither Power Apps charts nor Power BI are available:

1. Go to the SharePoint site
2. Create a new **Page**
3. Add **List** web parts showing filtered views of each list
4. Add the **Highlighted Content** web part for recent items
5. Pin this page as a **Teams Tab** (Website tab → SharePoint URL)

### Limitations
- No real charts (only list views with conditional formatting)
- No role-based filtering (everyone sees the same page)
- Basic aesthetics

---

## 🗺️ Recommended Rollout Plan

### Phase 1 (Week 1-2): Power Apps Core
```
✅ Build 5-screen Canvas App
✅ Connect to SharePoint lists
✅ Implement role detection (employee vs. manager)
✅ Publish to Teams as Tab
✅ Wire Power Automate approval flow
```

### Phase 2 (Week 3): Power BI Report (if licensed)
```
⬜ Connect Power BI Desktop to SharePoint
⬜ Build 4 report pages (Dashboard, Calendar, Coverage, Balance)
⬜ Publish to Power BI Service
⬜ Add as second Teams tab
⬜ Set up email subscriptions for directors
```

### Phase 3 (Week 4+): Polish
```
⬜ Copilot Studio Q&A bot (read-only queries)
⬜ Power BI alerts (when conflict rate exceeds threshold)
⬜ Mobile optimization (Power Apps responsive layout)
```

---

## 📝 FAQ

### Q: Can a manager see a calendar view in Power Apps?
**Yes.** Use a **Vertical Gallery** with 42 items (6 weeks × 7 days). Each item shows the
date number and a nested gallery of events for that date. The color-coding (green/orange/red)
works with conditional `Fill` properties based on the event status.

### Q: Can employees see this dashboard on mobile?
**Yes.** Power Apps Canvas Apps run natively on:
- Teams desktop
- Teams web
- Teams mobile (iOS/Android)
- Power Apps mobile app

### Q: Does the approval happen inside the app or in Teams?
**In Teams Approval Center.** Power Automate's Approvals connector creates a Teams approval
card. The manager can approve/reject from:
- Teams notification
- Teams Approvals app
- Email link

### Q: What about the HTML dashboard we built?
The HTML dashboard is a **design prototype** and **specification reference**. It shows
exactly what each Power Apps screen should look like. Use it as the design blueprint
when building screens in Power Apps Studio.

---

> **Bottom line**: Your primary production vehicle is a **Power Apps Canvas App published
> as a Teams tab**. For advanced director reporting, add a **Power BI report as a second tab**.
> No custom hosting, no HTML deployment, no external servers needed.
