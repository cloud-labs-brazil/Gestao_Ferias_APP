# Gestão Férias

## What This Is

A vacation management app for Minsait/Indra employees embedded in Microsoft Teams. Employees can check their vacation balance, submit CLT-compliant vacation requests (including abono pecuniário), and track status. Managers approve/reject requests with conflict visibility and team calendar view. Built on Power Apps + Power Automate (Standard license) + SharePoint Online.

## Core Value

Employees can submit a CLT-compliant vacation request and have their manager approve it — all self-service via Teams, with no HR handoff and no manual processes.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

- ✓ SharePoint data layer deployed — 6 lists with schemas (Colaboradores_Aprovadores, Solicitacoes_Ferias, Historico_Ferias, Saldo_Ferias, Feriados, Alertas_Ferias) — existing
- ✓ Employee/approver mapping imported — 13 employees with manager assignments — existing
- ✓ Holiday calendar imported — 19 Brazilian holidays — existing
- ✓ Deployment automation scripts — 5 PowerShell scripts for SP provisioning — existing
- ✓ Architecture decision — Power Apps + Power Automate (Standard) over Copilot Studio — ADR-001

### Active

<!-- Current scope. Building toward these. -->

- [ ] Employee can view their vacation balance (saldo de férias) with período aquisitivo and vencimento
- [ ] Employee can submit a vacation request with date range selection
- [ ] System validates CLT rules before submission: 45-day advance notice, 5-30 day range per period, balance check
- [ ] System enforces CLT fracionamento: up to 3 periods, 1 period ≥ 14 days, others ≥ 5 days
- [ ] Employee can request abono pecuniário (sell up to 10 days / 1/3 of entitlement)
- [ ] System performs conflict detection against team members' approved vacations before submission
- [ ] System blocks requests that don't meet CLT prerequisites (insufficient balance, período aquisitivo not completed)
- [ ] Manager receives approval notification via Teams + Email
- [ ] Manager can approve or reject requests with visibility into conflicts
- [ ] On approval: balance is deducted, histórico is created, employee is notified
- [ ] On rejection: employee is notified with reason
- [ ] Employee can cancel a pending request
- [ ] Employee can view their request history and status
- [ ] Manager can view team vacation calendar
- [ ] Weekly scheduled alerts: 7-day vacation reminders + balance expiration warnings
- [ ] 100% Portuguese-BR (PT-BR) interface and messaging

### Out of Scope

- Copilot Studio chatbot — pivoted away (ADR-001), deferred to Phase 2
- Premium Power Automate connectors — no Premium license available
- Blackout periods — confirmed not needed (BR-007)
- RH handoff workflow — self-service model per BR-004
- Payroll integration for abono pecuniário — app tracks the request, payroll is handled externally
- Mobile-native app — Power Apps in Teams provides mobile access

## Context

- **Tenant:** indra365.sharepoint.com
- **Environment:** ColOfertasBrasilPro (Dataverse: colofertasbrasilpro.crm4.dynamics.com)
- **Admin account:** mbenicios@minsait.com
- **SharePoint lists:** Already deployed with data (13 employees, 19 holidays)
- **Saldo_Ferias:** Needs seeding — 05-Seed-Saldo-Ferias.ps1 not yet executed
- **Architecture pivot:** Originally Copilot Studio + 10 flows → now Power Apps + 2 flows (ADR-001, 2026-04-13)
- **Codebase intel:** 6 files mapped in .planning/codebase/ (reflects old architecture, needs mental offset)
- **Build approach:** Agent builds everything via CLI + browser automation (user is not a designer)
- **Timeline:** Project is delayed — prioritize speed of delivery
- **CLT compliance:** Brazilian labor law (Art. 134, Reforma Trabalhista 2017) — 30 days after 12 months, fracionamento, abono pecuniário

## Constraints

- **License:** Power Automate Standard only — no Premium connectors (HTTP, custom connectors, Dataverse)
- **Platform:** Power Apps Canvas App + Power Automate + SharePoint Online — no external services
- **Language:** 100% PT-BR — all labels, messages, notifications, error text
- **Delivery:** Embedded in Microsoft Teams as tab/personal app
- **Authentication:** Azure AD SSO via Power Apps User() function
- **Design:** Modern Controls + Fluent 2 themes (zero custom design — user is not a designer)
- **Build:** Agent-built via CLI (PnP.PowerShell, PAC CLI) + browser automation (make.powerapps.com)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Power Apps over Copilot Studio | Copilot Studio needs Premium for HTTP + custom connectors; Power Apps works with Standard license | ✓ Good |
| 2 flows instead of 10 | Standard license limits flow complexity; embed most logic in Power Apps formulas (Patch, Filter, LookUp) | ✓ Good |
| Modern Controls + Fluent 2 | Zero-design solution that automatically looks professional in Teams | — Pending |
| SharePoint as data store | Native M365 integration, no additional licensing, already deployed | ✓ Good |
| Abono pecuniário in-app | Track the sell request in the app; payroll integration is external | — Pending |
| Agent-built via CLI + browser | User is not a designer; maximize automation of the build process | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-13 after initialization*
