# Architecture Pivot — Gestão Férias

> **Date:** 2026-04-13
> **Decision:** Pivot from Copilot Studio-first to Power Apps + SharePoint + Power Automate
> **Status:** APPROVED

---

## What Changed

| Aspect | Before | After |
|--------|--------|-------|
| **Primary UI** | Copilot Studio conversational agent | Power Apps canvas app in Teams |
| **Approval mechanism** | Custom HTTP-triggered flows | Power Automate Approvals connector |
| **Flow count** | 10 HTTP-triggered flows | 5 flows (Power Apps + Approvals trigger) |
| **Topics/configuration** | 11 Copilot Studio topics | 5 Power App screens |
| **Copilot Studio role** | Core (primary interface) | Deferred to Phase 2 (read-only Q&A) |
| **AI Builder** | Not planned | Excluded (no use case) |

## Why

1. **Conversational UI is wrong for form-based data entry** — date pickers are faster than typing dates in chat
2. **3 months of planning produced 0 deployed flows** — complexity overhead blocked delivery
3. **Power Apps + Approvals connector is the standard Microsoft pattern** for this exact use case
4. **Maintenance is easier** — Power Apps skills are more common than Copilot Studio skills
5. **Component count drops significantly** — 5 flows + 1 app vs. 10 flows + 11 topics + 6 cards

## What Is Preserved

- ✅ All 6 SharePoint lists (deployed, data imported)
- ✅ 10 flow JSON definitions (reference material)
- ✅ 6 Adaptive Card templates (Phase 2 use)
- ✅ Copilot Studio agent (Phase 2 Q&A layer)
- ✅ All documentation and SOPs
- ✅ All business rules and data schemas

## New Architecture

```
Teams → Power App (5 screens) → Power Automate (5 flows) → SharePoint Lists (6)
                                      ↓
                              Approvals Center (Teams built-in)
                                      ↓
                              Notifications (Teams + Email)
```

## References

- Full assessment: `implementation_plan.md`
- Original architecture: `.planning/codebase/ARCHITECTURE.md`
- Original risks: `.planning/codebase/RISKS.md`
