# Phase 4 — CONTEXT.md
# Power Apps — Create App + Home Screen

> **Created:** 2026-04-18T21:38  
> **Phase Status:** Discussed → Ready for Planning  
> **Depends on:** Phase 1 ✅ (SP lists deployed + seeded)

---

## Decisions Made

### D-001: Build Method → Guided Browser Build
- **Decision:** Create the Canvas App manually via make.powerapps.com with agent providing step-by-step instructions and formulas
- **Rationale:** `.msapp` format is undocumented and fragile; browser build gives full control and visibility
- **Impact:** All Power Apps phases (4-8) will use this approach

### D-002: Phase Cadence → One Phase Per Screen
- **Decision:** Follow GSD framework strictly — each screen gets its own discuss → plan → execute cycle
- **Rationale:** User wants proper documentation and no shortcuts; merging phases risks incomplete artifacts
- **Impact:** Phases 4-8 remain separate as defined in ROADMAP.md

### D-003: Abono Pecuniário → Deferred Post-MVP
- **Decision:** The "sell vacation days" (abono pecuniário) feature is OUT of MVP scope
- **Rationale:** Adds form complexity; payroll integration is external anyway
- **Impact:** Phase 5 (New Request) will NOT include abono checkbox

### D-004: CLT Fracionamento → Simple Mode in Phase 5
- **Decision:** MVP uses single-request mode (one date range per request). User creates separate requests to split vacation.
- **Rationale:** Full multi-period validation (1 period ≥ 14 days, max 3 periods) is complex; simple mode ships faster
- **Impact:** Phase 5 form = single start/end date pair + standard validations (BR-001 to BR-003)

---

## Phase 4 Scope

### What This Phase Delivers
1. **Create Canvas App** in make.powerapps.com with Modern Controls enabled
2. **Connect all 6 SharePoint lists** as data sources
3. **App.OnStart logic:** user identification, role detection, balance loading
4. **Home Screen** with:
   - Employee view: balance card (saldo, período aquisitivo, vencimento) + active requests count
   - Manager view: same + pending approvals count + team members on vacation now
5. **Navigation shell** with role-based visibility (manager-only screens hidden for employees)
6. **100% PT-BR** labels and text

### What This Phase Does NOT Deliver
- No request submission form (Phase 5)
- No request history (Phase 6)
- No approval interface (Phase 7)
- No team calendar (Phase 8)
- No Teams embedding (Phase 9)
- No abono pecuniário (post-MVP)

---

## Technical Context

### Existing Assets Ready to Use
| Asset | Location | Usage |
|-------|----------|-------|
| App.OnStart formulas | `docs/PowerApps-Formula-Reference.md` §1 | Copy into app |
| Role detection formulas | `docs/PowerApps-Formula-Reference.md` §2 | varIsManager logic |
| Balance display formulas | `docs/PowerApps-Formula-Reference.md` §3 | Home screen cards |
| Non-designer build guide | `docs/PowerApps-NonDesigner-Guide.md` | Modern Controls + Fluent 2 setup |
| SP list schemas | `gemini.md` §3.5 | Column names and types |

### SharePoint Data Sources (6 lists)
1. Colaboradores_Aprovadores — employee/manager mapping
2. Solicitacoes_Ferias — vacation requests
3. Historico_Ferias — past vacations
4. Saldo_Ferias — balance per employee
5. Feriados — holidays
6. Alertas_Ferias — alerts

### Power Apps Environment
- **URL:** make.powerapps.com
- **Environment:** ColOfertasBrasilPro
- **App Type:** Canvas App (Phone or Tablet layout — TBD in planning)
- **Controls:** Modern Controls with Fluent 2 theme
- **Language:** PT-BR (display language + formula locale)

---

## Open Items for Planning

- [ ] Canvas layout: Phone layout (mobile-first for Teams mobile) or Tablet layout (desktop-first)?
- [ ] Navigation pattern: sidebar, tab bar, or hamburger menu?
- [ ] Color theme: use default Fluent 2 or customize with Minsait/Indra brand colors?
- [ ] App name: "Gestão Férias" or something else?

---

## Deferred Ideas

- Abono pecuniário toggle on Home screen balance card → post-MVP
- Push notification badges for pending items → post-MVP
- Dark mode toggle → post-MVP

---

*Next step: `/gsd-plan-phase 4` — create detailed task plan*
