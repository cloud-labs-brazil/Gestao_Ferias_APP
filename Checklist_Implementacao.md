# 📋 Checklist de Implementação — Gestão Férias

> **Última atualização:** 19/04/2026 16:51
> **Responsável:** Equipe Arquitetura de Soluções
> **Arquitetura:** Power Apps (Canvas) + Power Automate (Standard) + SharePoint Online

---

## ⚠️ Decisões Críticas de Arquitetura

| # | Decisão | Data | Status |
|---|---------|------|--------|
| ADR-001 | **Pivot:** Copilot Studio → Power Apps + Power Automate + SharePoint | 13/04/2026 | ✅ Aprovado |
| ADR-002 | **Licença:** Standard only (sem Premium) → 2 flows + lógica no Power Apps | 13/04/2026 | ✅ Confirmado |
| ADR-003 | **Backend:** SharePoint é fonte ÚNICA de dados (6 listas). Sem Dataverse. | 19/04/2026 | ✅ Confirmado |
| ADR-004 | **App:** Criar Canvas App NOVO ("GestaoFerias") — ignorar app existente com Dataverse | 19/04/2026 | ✅ Confirmado |

---

## 📊 Resumo de Progresso

| Fase | Total | ✅ | ⏳ | % |
|------|-------|----|-----|---|
| 1. Pré-requisitos + SP Deploy | 10 | 10 | 0 | 100% |
| 2. Power Automate (2 Flows) | 2 | 2 | 0 | 100% |
| 3. HTML Dashboard (bônus) | 6 | 6 | 0 | 100% |
| 4. Power Apps — App + Home Screen | 8 | 0 | 8 | 0% |
| 5. Power Apps — Tela Nova Solicitação | 6 | 0 | 6 | 0% |
| 6. Power Apps — Tela Minhas Solicitações | 5 | 0 | 5 | 0% |
| 7. Power Apps — Tela Aprovações (Gestor) | 5 | 0 | 5 | 0% |
| 8. Power Apps — Calendário do Time | 5 | 0 | 5 | 0% |
| 9. Deploy Teams + Go-Live | 6 | 0 | 6 | 0% |
| **TOTAL** | **53** | **18** | **35** | **34%** |

```
[███████░░░░░░░░░░░░░] 34% Concluído
```

---

## ✅ FASE 1: Pré-requisitos + SharePoint Deploy (10/10 = 100%)

> **Status:** COMPLETO — Todos os 6 listas SP criadas, dados importados, saldos semeados.

| # | Tarefa | Status | Data | Observação |
|---|--------|--------|------|------------|
| 1.1 | Instalar módulos PowerShell (PnP + ImportExcel) | ✅ | 25/01 | `01-Setup-Modulos.ps1` |
| 1.2 | Validar acesso admin ao SharePoint | ✅ | 25/01 | indra365.sharepoint.com |
| 1.3 | Criar lista `Colaboradores_Aprovadores` | ✅ | 13/04 | `02-Deploy-Listas.ps1` |
| 1.4 | Criar lista `Solicitacoes_Ferias` | ✅ | 13/04 | Inclui Status choice |
| 1.5 | Criar lista `Historico_Ferias` | ✅ | 13/04 | — |
| 1.6 | Criar lista `Saldo_Ferias` | ✅ | 13/04 | — |
| 1.7 | Criar lista `Feriados` | ✅ | 13/04 | 12 feriados nacionais |
| 1.8 | Criar lista `Alertas_Ferias` | ✅ | 13/04 | — |
| 1.9 | Importar dados colaboradores | ✅ | 13/04 | `03-Importar-Dados.ps1` (bug boolean corrigido) |
| 1.10 | Semear saldos de férias | ✅ | 13/04 | `05-Seed-Saldo-Ferias.ps1` (32 registros) |

---

## ✅ FASE 2: Power Automate — 2 Flows Standard (2/2 = 100%)

> **Status:** COMPLETO — Ambos flows testados E2E com dados reais do SharePoint.

| # | Tarefa | Status | Data | Observação |
|---|--------|--------|------|------------|
| 2.1 | Flow `VacationApproval` | ✅ | 18/04 | Trigger: SP item created → Approval → Update status + Notify |
| 2.2 | Flow `ScheduledAlerts` | ✅ | 18/04 | Recurrence weekly → Filter balances → Create alert records |

**Lógica migrada para Power Apps (não precisa de flow):**
- Submit Request → `Patch()` direto no SP
- Cancel Request → `Patch()` status = "CANCELLED"
- Check Conflicts → `Filter()` por departamento + datas
- Balance Validation → `LookUp()` no Saldo_Ferias
- Date Validation → Fórmulas Power Fx (BR-001 a BR-003)

---

## ✅ FASE 3: HTML Dashboard — Bônus (6/6 = 100%)

> **Status:** COMPLETO — SPA dark-mode com 5 views.

| # | Tarefa | Status | Data | Observação |
|---|--------|--------|------|------------|
| 3.1 | Dashboard HTML SPA | ✅ | 19/04 | `dashboard/index.html` |
| 3.2 | SP Connector JS | ✅ | 19/04 | `dashboard/sp-connector.js` |
| 3.3 | Estilos dark-mode | ✅ | 19/04 | CSS completo |
| 3.4 | 5 views implementadas | ✅ | 19/04 | Home, Requests, Calendar, Alerts, Settings |
| 3.5 | Deploy script SP | ✅ | 19/04 | `11-Deploy-Dashboard-SP.ps1` |
| 3.6 | Documentação | ✅ | 19/04 | — |

---

## ⏳ FASE 4: Power Apps — Criar App + Home Screen (0/8 = 0%) ← **ATUAL**

> **Status:** DISCUSS completo, PLAN criado. Pronto para EXECUÇÃO.
> **Método:** Guided browser build em make.powerapps.com
> **Decisão:** Criar app NOVO (não usar app existente com Dataverse)

| # | Tarefa | Status | Observação |
|---|--------|--------|------------|
| 4.1 | Criar Canvas App "GestaoFerias" em make.powerapps.com | ⏳ | Tablet layout, Modern Controls |
| 4.2 | Habilitar Modern Controls + Fluent 2 theme | ⏳ | Settings → Upcoming features |
| 4.3 | Conectar 6 listas SharePoint como Data Sources | ⏳ | **SharePoint ONLY — sem Dataverse** |
| 4.4 | Configurar App.OnStart (user detection + role) | ⏳ | varCurrentUser, varIsManager, varUserBalance |
| 4.5 | Criar Home Screen — Employee view (saldo + requests) | ⏳ | Balance card + active requests count |
| 4.6 | Criar Home Screen — Manager view (team stats) | ⏳ | Pending approvals + team on vacation |
| 4.7 | Criar Navigation shell (bottom tab bar) | ⏳ | 5 tabs, manager-only hidden para employees |
| 4.8 | Publicar primeira versão (save + publish) | ⏳ | — |

### Referências para Fase 4
| Artefato | Localização |
|----------|-------------|
| Fórmulas App.OnStart | `docs/PowerApps-Formula-Reference.md` §1 |
| Detecção de role | `docs/PowerApps-Formula-Reference.md` §2 |
| Fórmulas de saldo | `docs/PowerApps-Formula-Reference.md` §3 |
| Guia de build (Modern Controls) | `docs/PowerApps-NonDesigner-Guide.md` |
| Schemas das listas SP | `gemini.md` §3.5 |
| Plan detalhado | `.planning/phases/04-power-apps-home-screen/04-PLAN.md` |
| Decisões de contexto | `.planning/phases/04-power-apps-home-screen/04-CONTEXT.md` |

---

## ⏳ FASE 5: Power Apps — Tela Nova Solicitação (0/6 = 0%)

| # | Tarefa | Status | Observação |
|---|--------|--------|------------|
| 5.1 | Formulário: Data Início, Data Fim, Observações | ⏳ | Date pickers + text input |
| 5.2 | Validação BR-001 (45 dias antecedência) | ⏳ | Power Fx client-side |
| 5.3 | Validação BR-002/BR-003 (5-30 dias) | ⏳ | Power Fx client-side |
| 5.4 | Verificação de conflitos (Filter SP) | ⏳ | Departamento + datas sobrepostas |
| 5.5 | Submit via Patch() para Solicitacoes_Ferias | ⏳ | Triggers VacationApproval flow |
| 5.6 | Confirmação + reset do formulário | ⏳ | — |

---

## ⏳ FASE 6: Power Apps — Tela Minhas Solicitações (0/5 = 0%)

| # | Tarefa | Status | Observação |
|---|--------|--------|------------|
| 6.1 | Gallery com solicitações do usuário | ⏳ | Filter por Email_Colaborador |
| 6.2 | Status badges (Pending/Approved/Rejected/Cancelled) | ⏳ | Color-coded |
| 6.3 | Detalhes do request (expand) | ⏳ | Todas as colunas visíveis |
| 6.4 | Botão Cancelar (para status PENDING) | ⏳ | Patch → CANCELLED |
| 6.5 | Sort + Filter por status/data | ⏳ | — |

---

## ⏳ FASE 7: Power Apps — Tela Aprovações Gestor (0/5 = 0%)

| # | Tarefa | Status | Observação |
|---|--------|--------|------------|
| 7.1 | Gallery com solicitações pendentes do time | ⏳ | Filter: Email_Aprovador + Status=PENDING |
| 7.2 | Botões Aprovar/Rejeitar | ⏳ | Patch → APPROVED/REJECTED |
| 7.3 | Campo motivo rejeição | ⏳ | Obrigatório se rejeitar |
| 7.4 | Conflict indicator badge | ⏳ | Tem_Conflito = true → warning |
| 7.5 | Visível apenas para managers | ⏳ | varIsManager check |

---

## ⏳ FASE 8: Power Apps — Calendário do Time (0/5 = 0%)

| # | Tarefa | Status | Observação |
|---|--------|--------|------------|
| 8.1 | Calendar/timeline view do time | ⏳ | Férias aprovadas do departamento |
| 8.2 | Filtro por período (mês) | ⏳ | — |
| 8.3 | Indicador de cobertura do time | ⏳ | % de equipe disponível |
| 8.4 | Detalhes ao clicar | ⏳ | Nome, período, status |
| 8.5 | Visível apenas para managers | ⏳ | varIsManager check |

---

## ⏳ FASE 9: Deploy Teams + Go-Live (0/6 = 0%)

| # | Tarefa | Status | Observação |
|---|--------|--------|------------|
| 9.1 | Publicar Power App como Teams Tab | ⏳ | — |
| 9.2 | Testar E2E no Teams (employee flow) | ⏳ | Submit → Approve → Balance update |
| 9.3 | Testar E2E no Teams (manager flow) | ⏳ | View requests → Approve/Reject |
| 9.4 | Comunicação para usuários | ⏳ | — |
| 9.5 | Documentação de suporte | ⏳ | — |
| 9.6 | Monitoramento pós-go-live | ⏳ | — |

---

## 📁 Artefatos Produzidos

| Tipo | Arquivo | Fase | Status |
|------|---------|------|--------|
| 📄 Config | `gemini.md` | — | ✅ Project constitution |
| 📄 ADR | `docs/ADR-001-Architecture-Pivot.md` | — | ✅ Copilot → Power Apps |
| 📜 Script | `01-Setup-Modulos.ps1` | 1 | ✅ Module installation |
| 📜 Script | `02-Deploy-Listas.ps1` | 1 | ✅ 6 lists + columns |
| 📜 Script | `03-Importar-Dados.ps1` | 1 | ✅ Data import (bool bug fixed) |
| 📜 Script | `05-Seed-Saldo-Ferias.ps1` | 1 | ✅ Balance seeding |
| ⚡ Flow | VacationApproval | 2 | ✅ E2E tested |
| ⚡ Flow | ScheduledAlerts | 2 | ✅ E2E tested |
| 📄 Formulas | `docs/PowerApps-Formula-Reference.md` | 4-8 | ✅ All Power Fx ready |
| 📄 Guide | `docs/PowerApps-NonDesigner-Guide.md` | 4-8 | ✅ Modern Controls guide |
| 🌐 Dashboard | `dashboard/*` (6 files) | 3 | ✅ Dark-mode SPA |
| 📜 Script | `11-Deploy-Dashboard-SP.ps1` | 3 | ✅ SP deploy script |
| 📄 Plan | `.planning/phases/04-*/04-PLAN.md` | 4 | ✅ Task plan ready |
| 📄 Context | `.planning/phases/04-*/04-CONTEXT.md` | 4 | ✅ 6 decisions documented |

---

## 📌 Regras de Negócio Confirmadas

| Regra | Valor | Status |
|-------|-------|--------|
| BR-001 | Antecedência mínima: **45 dias** | ✅ Confirmado |
| BR-002 | Mínimo por solicitação: **5 dias** | ✅ Confirmado |
| BR-003 | Máximo por solicitação: **30 dias** | ✅ Confirmado |
| BR-004 | Sem handoff para RH (autoatendimento) | ✅ Confirmado |
| BR-005 | Detecção de conflito OBRIGATÓRIA | ✅ Confirmado |
| BR-006 | Notificações via Teams + Email | ✅ Confirmado |
| BR-007 | Sem períodos de bloqueio (blackout) | ✅ Confirmado |
| BR-008 | Power Automate Standard only (sem Premium) | ✅ Confirmado |

---

## 📅 Histórico de Atualizações

| Data | Fase | Ação | Por |
|------|------|------|-----|
| 25/01/2026 | Setup | Documento criado | Claude |
| 25/01/2026 | Setup | Status real do projeto atualizado | Claude |
| 13/04/2026 | 1 | Pivot arquitetura: Copilot → Power Apps + PA + SP | Claude |
| 13/04/2026 | 1 | 6 listas SP criadas + dados importados + saldos semeados | Claude |
| 18/04/2026 | 2 | VacationApproval flow E2E testado | Claude |
| 18/04/2026 | 2 | ScheduledAlerts flow E2E testado | Claude |
| 19/04/2026 | 3 | HTML Dashboard completo (6 files) | Claude |
| 19/04/2026 | 4 | **CONTEXTO:** SharePoint = único backend (ADR-003) | Claude |
| 19/04/2026 | 4 | **CONTEXTO:** App novo clean state (ADR-004) | Claude |
| 19/04/2026 | 4 | **Checklist reescrito** — refletir estado real pós-pivot | Claude |
