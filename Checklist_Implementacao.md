# 📋 Checklist de Implementação - Agente "Gestão Férias"

> **Última atualização:** 25/01/2026 04:10
> **Responsável:** Equipe Arquitetura de Soluções

---

## 📊 Resumo de Progresso

| Fase | Total | Concluído | Pendente | % Concluído |
|------|-------|-----------|----------|-------------|
| 1. Pré-requisitos | 6 | 4 | 2 | 67% |
| 2. SharePoint (Listas) | 8 | 0 | 8 | 0% |
| 3. Power Automate (Flows) | 10 | 0 | 10 | 0% |
| 4. Copilot Studio (Tópicos) | 14 | 0 | 14 | 0% |
| 5. Testes | 8 | 0 | 8 | 0% |
| 6. Go-Live | 4 | 0 | 4 | 0% |
| **TOTAL** | **50** | **4** | **46** | **8%** |

```
[████░░░░░░░░░░░░░░░░] 8% Concluído
```

---

## 🔧 FASE 1: Pré-requisitos (4/6 = 67%)

### Ambiente e Ferramentas

| # | Tarefa | Status | Data | Observação |
|---|--------|--------|------|------------|
| 1.1 | [x] Instalar módulo `ImportExcel` PowerShell | ✅ Concluído | 25/01 | Instalado via script |
| 1.2 | [x] Instalar módulo `PnP.PowerShell` | ✅ Concluído | 25/01 | Versão legada (SharePointPnPPowerShellOnline) + versão 2.12/3.x disponíveis |
| 1.3 | [x] Validar acesso admin ao SharePoint | ✅ Concluído | 25/01 | URL corrigida: `indra365.sharepoint.com` (não indracompany) |
| 1.4 | [ ] Validar acesso ao Power Automate | ⏳ Pendente | - | Licença Premium necessária para conectores |
| 1.5 | [x] Validar acesso ao Copilot Studio | ✅ Concluído | 25/01 | Agente "Gestão Férias" confirmado |
| 1.6 | [ ] Validar estrutura do arquivo Excel | ⏳ Pendente | - | `Users_Approvers.xlsx` existe mas precisa validar colunas |

---

## 📂 FASE 2: SharePoint - Listas (0/8 = 0%)

> **⚠️ STATUS:** Scripts prontos para criar as listas. Aguardando execução.

### Scripts Criados

| Script | Função | Status |
|--------|--------|--------|
| `01-Setup-Modulos.ps1` | Instalar módulos PowerShell | ✅ Criado |
| `02-Deploy-Listas.ps1` | Criar 6 listas + colunas | ✅ Criado |
| `03-Importar-Dados.ps1` | Importar dados do Excel | ✅ Criado |

### Criação das Listas

| # | Tarefa | Status | Data | Observação |
|---|--------|--------|------|------------|
| 2.1 | [ ] Criar lista `Colaboradores_Aprovadores` | ⏳ Pendente | - | Script pronto, aguardando execução |
| 2.2 | [ ] Criar lista `Solicitacoes_Ferias` | ⏳ Pendente | - | Script pronto |
| 2.3 | [ ] Criar lista `Historico_Ferias` | ⏳ Pendente | - | Script pronto |
| 2.4 | [ ] Criar lista `Saldo_Ferias` | ⏳ Pendente | - | Script pronto |
| 2.5 | [ ] Criar lista `Feriados` | ⏳ Pendente | - | Script pronto |
| 2.6 | [ ] Criar lista `Alertas_Ferias` | ⏳ Pendente | - | Script pronto |
| 2.7 | [ ] Importar dados do Excel | ⏳ Pendente | - | Script `03-Importar-Dados.ps1` criado |
| 2.8 | [ ] Criar Views personalizadas | ⏳ Pendente | - | Após listas criadas |

### Comando para Executar

```powershell
# Abrir Windows PowerShell (não VS Code)
cd D:\VMs\Projetos\Copilot_Studio_Config\Scripts
.\02-Deploy-Listas.ps1
# → Vai abrir browser para login com mbenicios@minsait.com
```

---

## ⚡ FASE 3: Power Automate - Flows (0/10 = 0%)

### Flows Principais

| # | Tarefa | Status | Data | Observação |
|---|--------|--------|------|------------|
| 3.1 | [ ] Flow: `ConsultarSaldoFerias` | ⏳ Pendente | - | Entrada: email → Saída: saldo |
| 3.2 | [ ] Flow: `VerificarConflitos` | ⏳ Pendente | - | Verifica sobreposição de datas |
| 3.3 | [ ] Flow: `CriarSolicitacao` | ⏳ Pendente | - | Cria item na lista + notifica gestor |
| 3.4 | [ ] Flow: `AprovarSolicitacao` | ⏳ Pendente | - | Atualiza status + notifica colaborador |
| 3.5 | [ ] Flow: `RejeitarSolicitacao` | ⏳ Pendente | - | Atualiza status + motivo |
| 3.6 | [ ] Flow: `ConsultarStatusSolicitacao` | ⏳ Pendente | - | Retorna status atual |
| 3.7 | [ ] Flow: `CancelarSolicitacao` | ⏳ Pendente | - | Cancela solicitação pendente |
| 3.8 | [ ] Flow: `ObterDashboardGestor` | ⏳ Pendente | - | Dados consolidados do time |
| 3.9 | [ ] Flow: `ObterAlertasCriticos` | ⏳ Pendente | - | Férias vencendo |
| 3.10 | [ ] Flow: `EnviarNotificacaoTeams` | ⏳ Pendente | - | Adaptive Cards |

---

## 🤖 FASE 4: Copilot Studio - Tópicos (0/14 = 0%)

### Configuração do Agente

| # | Tarefa | Status | Data | Observação |
|---|--------|--------|------|------------|
| 4.1 | [ ] Configurar Instruções do Agente | ⏳ Pendente | - | Documento pronto: `Configuracao_Agente_Gestao_Ferias.md` |
| 4.2 | [ ] Conectar ferramentas (Power Automate) | ⏳ Pendente | - | Depende das listas + flows |

### Tópicos

| # | Tarefa | Status | Data | Observação |
|---|--------|--------|------|------------|
| 4.3 | [ ] Tópico: Saudação | ⏳ Pendente | - | Texto pronto no documento |
| 4.4 | [ ] Tópico: Menu/Ajuda | ⏳ Pendente | - | Texto pronto |
| 4.5 | [ ] Tópico: Consultar Saldo | ⏳ Pendente | - | Texto pronto |
| 4.6 | [ ] Tópico: Solicitar Férias | ⏳ Pendente | - | Texto pronto com fluxo de conflitos |
| 4.7 | [ ] Tópico: Status da Solicitação | ⏳ Pendente | - | Texto pronto |
| 4.8 | [ ] Tópico: Cancelar Solicitação | ⏳ Pendente | - | Texto pronto |
| 4.9 | [ ] Tópico: Política de Férias | ⏳ Pendente | - | RAG do Knowledge |
| 4.10 | [ ] Tópico: Feriados/Calendário | ⏳ Pendente | - | Texto pronto |
| 4.11 | [ ] Tópico: Dashboard Gestor | ⏳ Pendente | - | Texto pronto |
| 4.12 | [ ] Tópico: Aprovar Solicitações | ⏳ Pendente | - | Texto pronto |
| 4.13 | [ ] Tópico: Fallback | ⏳ Pendente | - | Autoatendimento (sem RH) |
| 4.14 | [ ] Configurar Solicitações Sugeridas | ⏳ Pendente | - | 6 chips/botões prontos |

---

## 🧪 FASE 5: Testes (0/8 = 0%)

| # | Tarefa | Status | Data | Observação |
|---|--------|--------|------|------------|
| 5.1 | [ ] Teste: Consultar saldo | ⏳ Pendente | - | - |
| 5.2 | [ ] Teste: Solicitar férias (sem conflito) | ⏳ Pendente | - | - |
| 5.3 | [ ] Teste: Solicitar férias (com conflito) | ⏳ Pendente | - | - |
| 5.4 | [ ] Teste: Solicitar com < 45 dias | ⏳ Pendente | - | Deve bloquear |
| 5.5 | [ ] Teste: Aprovar via gestor | ⏳ Pendente | - | - |
| 5.6 | [ ] Teste: Rejeitar via gestor | ⏳ Pendente | - | - |
| 5.7 | [ ] Teste: Dashboard gerencial | ⏳ Pendente | - | - |
| 5.8 | [ ] Teste: Alertas proativos | ⏳ Pendente | - | - |

---

## 🚀 FASE 6: Go-Live (0/4 = 0%)

| # | Tarefa | Status | Data | Observação |
|---|--------|--------|------|------------|
| 6.1 | [ ] Publicar agente no Teams | ⏳ Pendente | - | - |
| 6.2 | [ ] Comunicação para usuários | ⏳ Pendente | - | - |
| 6.3 | [ ] Documentação de suporte | ⏳ Pendente | - | - |
| 6.4 | [ ] Monitoramento pós-go-live | ⏳ Pendente | - | - |

---

## 📁 Artefatos Produzidos

| Tipo | Arquivo | Status |
|------|---------|--------|
| 📄 Documentação | `Configuracao_Agente_Gestao_Ferias.md` | ✅ Completo |
| 📄 Documentação | `Visao_Gerencial_Gestao_Ferias.md` | ✅ Completo |
| 📄 Documentação | `Deploy_CLI_SharePoint.md` | ✅ Completo |
| 📄 Checklist | `Checklist_Implementacao.md` | ✅ Atualizado |
| 📜 Script | `01-Setup-Modulos.ps1` | ✅ Criado |
| 📜 Script | `02-Deploy-Listas.ps1` | ✅ Criado |
| 📜 Script | `03-Importar-Dados.ps1` | ✅ Criado |

---

## 📌 Regras de Negócio Confirmadas

| Regra | Valor | Confirmado |
|-------|-------|------------|
| Antecedência mínima para solicitar | **45 dias** | ✅ |
| Mínimo de dias por solicitação | 5 dias | ⏳ Confirmar |
| Máximo de dias por solicitação | 30 dias | ⏳ Confirmar |
| Handoff para RH | **NÃO** (autoatendimento) | ✅ |
| Calendário de feriados | Lista própria da empresa | ✅ |
| Tenant SharePoint | **indra365.sharepoint.com** | ✅ |
| Conta SharePoint | **mbenicios@minsait.com** | ✅ |

---

## ⚠️ Próximos Passos

1. **IMEDIATO:** Executar `02-Deploy-Listas.ps1` para criar as 6 listas
2. **IMEDIATO:** Executar `03-Importar-Dados.ps1` para popular colaboradores
3. Criar os 10 Power Automate Flows
4. Configurar tópicos no Copilot Studio

---

## 📅 Histórico de Atualizações

| Data | Fase | Ação | Por |
|------|------|------|-----|
| 25/01/2026 00:09 | Setup | Documento criado | Claude |
| 25/01/2026 04:10 | Setup | **Atualizado status real do projeto** | Claude |
