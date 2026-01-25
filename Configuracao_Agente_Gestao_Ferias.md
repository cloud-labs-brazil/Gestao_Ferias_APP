# 🌴 Configuração Completa: Agente "Gestão Férias" - Microsoft Copilot Studio

> **Documento técnico completo** para configuração do agente de gestão de férias com detecção de conflitos, fluxo de aprovação e notificações multicanal.

---

## Índice

1. [Instruções do Agente](#1-instruções-do-agente)
2. [Ferramentas (Power Automate)](#2-ferramentas-power-automate)
3. [Gatilhos (Triggers)](#3-gatilhos-triggers)
4. [Agentes (Sub-agentes)](#4-agentes-sub-agentes)
5. [Mapa de Tópicos Completo](#5-mapa-de-tópicos-completo)
6. [Solicitações Sugeridas](#6-solicitações-sugeridas)
7. [Base de Conhecimento (Knowledge)](#7-base-de-conhecimento-knowledge)
8. [Configuração de Fallback e Escalonamento](#8-configuração-de-fallback-e-escalonamento)
9. [Fluxos Power Automate Detalhados](#9-fluxos-power-automate-detalhados)

---

## 1. Instruções do Agente

### 📋 Campo: Instruções (Instructions)

Cole o texto abaixo no campo **"Instruções"** do seu agente:

```
# IDENTIDADE E PROPÓSITO

Você é o Assistente de Gestão de Férias, um agente virtual especializado em gerenciar solicitações de férias para colaboradores. Você atende dois times: o time do usuário autenticado e o time do Diretor.

## ESCOPO DE ATUAÇÃO

### O que você PODE fazer:
- Consultar saldo de férias disponível do colaborador
- Iniciar solicitações de férias (novas, alterações, cancelamentos)
- Verificar conflitos de datas com férias já aprovadas de outros colaboradores
- Consultar status de solicitações pendentes ou históricas
- Informar sobre política de férias da empresa
- Mostrar calendário de feriados
- Para gestores: apresentar visão consolidada do time
- Encaminhar solicitações para aprovação do gestor direto
- Notificar colaboradores sobre aprovações/rejeições

### O que você NÃO pode fazer:
- Aprovar férias diretamente (somente gestores podem aprovar)
- Alterar períodos já aprovados sem nova solicitação
- Acessar informações de colaboradores de outros times
- Consultar dados salariais ou de benefícios
- Realizar cálculos de rescisão ou verbas trabalhistas

## PRIORIDADES E COMPORTAMENTO

1. **Autenticação obrigatória**: Sempre verifique a identidade do usuário antes de mostrar informações sensíveis ou processar solicitações.

2. **Verificação de conflitos é MANDATÓRIA**: Antes de submeter qualquer solicitação, SEMPRE verifique se há conflitos com férias já aprovadas. Se houver conflito:
   - Informe claramente quais colaboradores têm férias no mesmo período
   - Pergunte se o usuário deseja: a) Prosseguir mesmo assim, b) Cancelar, c) Alterar as datas
   - Se prosseguir com conflito, sinalize isso claramente ao gestor

3. **Comunicação clara e profissional**: Use linguagem cordial mas objetiva. Confirme informações críticas antes de processar.

4. **Notificações multicanal**: Após aprovação/rejeição, notifique via Teams E email.

5. **Fallback inteligente**: Se não conseguir ajudar, ofereça opções claras e, se necessário, escalone para o RH.

## LIMITES TÉCNICOS

- Solicitações de férias devem ter no mínimo 30 dias de antecedência
- Período mínimo: 5 dias corridos
- Período máximo por solicitação: 30 dias corridos
- Não é possível solicitar férias que ultrapassem o saldo disponível
- Bloqueio de solicitações em períodos críticos definidos pela empresa (ex: fechamento contábil)

## FONTE DE DADOS

- Lista de colaboradores e aprovadores: arquivo Excel em SharePoint
- Histórico de férias: lista SharePoint "Histórico_Férias"
- Políticas: documentos na Base de Conhecimento (RAG)

## PERSONALIDADE

Seja prestativo, empático e eficiente. Entenda que férias são importantes para o bem-estar do colaborador e trate cada solicitação com cuidado e respeito.
```

---

## 2. Ferramentas (Power Automate)

### 🔧 Ferramentas Necessárias

Adicione as seguintes ferramentas (Power Automate Flows) ao seu agente:

| Nº | Nome da Ferramenta | Descrição | Parâmetros de Entrada | Retorno |
|----|-------------------|-----------|----------------------|---------|
| 1 | `ConsultarSaldoFerias` | Consulta o saldo de férias disponível do colaborador | `email_colaborador` | `{ saldo_dias, periodo_aquisitivo, vencimento }` |
| 2 | `VerificarConflitos` | Verifica se há conflitos com férias já aprovadas | `data_inicio, data_fim, id_time` | `{ tem_conflito, colaboradores_conflito[] }` |
| 3 | `CriarSolicitacao` | Cria uma nova solicitação de férias | `email, data_inicio, data_fim, tem_conflito, observacoes` | `{ id_solicitacao, status }` |
| 4 | `ConsultarStatus` | Consulta status de uma ou mais solicitações | `email_colaborador, id_solicitacao?` | `{ solicitacoes[] }` |
| 5 | `CancelarSolicitacao` | Cancela uma solicitação pendente | `id_solicitacao, motivo` | `{ sucesso, mensagem }` |
| 6 | `ObterCalendarioTime` | Retorna calendário de férias do time | `id_gestor` | `{ ferias_aprovadas[], ferias_pendentes[] }` |
| 7 | `EnviarNotificacao` | Envia notificação por Teams e Email | `destinatarios[], tipo, mensagem, link_acao?` | `{ enviado }` |
| 8 | `ObterFeriados` | Retorna lista de feriados do ano | `ano` | `{ feriados[] }` |
| 9 | `ObterAprovador` | Busca o gestor direto do colaborador | `email_colaborador` | `{ nome_gestor, email_gestor }` |

### Configuração de Cada Ferramenta no Copilot Studio

**Para cada ferramenta, configure:**

#### Ferramenta 1: ConsultarSaldoFerias

```
Nome: ConsultarSaldoFerias
Descrição: Consulta quantos dias de férias o colaborador ainda tem disponíveis, incluindo período aquisitivo e data de vencimento.

Parâmetro de entrada:
- Nome: email_colaborador
- Tipo: String
- Descrição: Email corporativo do colaborador
- Obrigatório: Sim

Retorno esperado:
- saldo_dias (número): Quantidade de dias disponíveis
- periodo_aquisitivo (texto): Ex: "01/03/2025 a 28/02/2026"
- vencimento (data): Data limite para gozo
```

#### Ferramenta 2: VerificarConflitos

```
Nome: VerificarConflitos
Descrição: Verifica se o período solicitado conflita com férias já aprovadas de outros colaboradores do mesmo time.

Parâmetros de entrada:
- Nome: data_inicio
  Tipo: Date
  Descrição: Data de início das férias pretendidas
  Obrigatório: Sim

- Nome: data_fim
  Tipo: Date
  Descrição: Data de término das férias pretendidas
  Obrigatório: Sim

- Nome: id_time
  Tipo: String
  Descrição: Identificador do time/departamento
  Obrigatório: Sim

Retorno esperado:
- tem_conflito (boolean): true se houver conflito
- colaboradores_conflito (array): Lista com nomes e períodos conflitantes
```

#### Ferramenta 3: CriarSolicitacao

```
Nome: CriarSolicitacao
Descrição: Registra uma nova solicitação de férias para aprovação do gestor direto.

Parâmetros de entrada:
- email (String, obrigatório): Email do colaborador
- data_inicio (Date, obrigatório): Início das férias
- data_fim (Date, obrigatório): Término das férias
- tem_conflito (Boolean, obrigatório): Indica se há conflito conhecido
- observacoes (String, opcional): Observações adicionais

Retorno:
- id_solicitacao: Número da solicitação criada
- status: "Pendente de Aprovação"
```

---

## 3. Gatilhos (Triggers)

### ⚡ Configuração de Gatilhos

| Gatilho | Evento | Ação |
|---------|--------|------|
| `OnVacationApproved` | Quando uma solicitação é aprovada no SharePoint | Dispara notificação para colaborador e gestor |
| `OnVacationRejected` | Quando uma solicitação é rejeitada | Dispara notificação com motivo para colaborador |
| `OnVacationReminder` | 7 dias antes do início das férias | Envia lembrete ao colaborador e gestor |
| `OnBalanceExpiring` | 60 dias antes do vencimento do saldo | Alerta o colaborador sobre saldo prestes a vencer |

### Texto para Configurar o Gatilho "OnVacationApproved"

```
Nome do Gatilho: Férias Aprovadas
Descrição: Ativado automaticamente quando um gestor aprova uma solicitação de férias.

Quando: O campo "Status" na lista SharePoint "Solicitações_Férias" é alterado para "Aprovado"

Ação do Agente:
1. Buscar detalhes da solicitação
2. Compor mensagem de confirmação
3. Enviar notificação via Teams para o colaborador
4. Enviar email de confirmação para colaborador e gestor
5. Atualizar calendário do time
```

---

## 4. Agentes (Sub-agentes)

### 🤖 Sub-agentes Recomendados

Para modularizar o agente principal, considere criar os seguintes sub-agentes:

| Sub-agente | Função | Quando Chamar |
|------------|--------|---------------|
| `Agente_Consulta` | Especializado em consultas (saldo, status, histórico) | Quando usuário quer apenas informações |
| `Agente_Solicitação` | Especializado no fluxo de criação de solicitações | Quando usuário quer solicitar férias |
| `Agente_Gestor` | Visão exclusiva para gestores | Quando um gestor acessa o sistema |

> **Nota**: Para a configuração inicial, recomendo manter tudo no agente principal. Sub-agentes são úteis quando a complexidade aumenta.

---

## 5. Mapa de Tópicos Completo

### 📚 Tópicos Recomendados

#### 5.1 Tópico: Saudação (Greeting)

```
Nome: Saudação
Gatilho: Início de conversa / Cumprimentos
Frases de gatilho:
- "Olá"
- "Oi"
- "Bom dia"
- "Boa tarde"
- "Boa noite"
- "Começar"
- "Ajuda"

Mensagem:
---
Olá! 👋 Bem-vindo ao Assistente de Gestão de Férias.

Posso ajudar você com:
🔹 **Consultar saldo** de férias
🔹 **Solicitar férias** (novas, alterações ou cancelamentos)
🔹 **Verificar status** de solicitações
🔹 **Conhecer a política** de férias
🔹 **Ver calendário** de feriados

Se você é **gestor**, também pode:
🔸 Ver **calendário do time**
🔸 **Aprovar ou devolver** solicitações

Como posso ajudar você hoje?
---
```

#### 5.2 Tópico: Menu / Ajuda (Desambiguação)

```
Nome: Menu Principal
Gatilho: Usuário pede ajuda ou menu
Frases de gatilho:
- "Menu"
- "O que você pode fazer?"
- "Ajuda"
- "Opções"
- "Não entendi"

Mensagem:
---
Aqui estão as principais opções disponíveis:

📅 **Férias**
┣ Consultar meu saldo
┣ Solicitar férias
┣ Ver status da minha solicitação
┗ Cancelar solicitação

📋 **Informações**
┣ Política de férias
┗ Calendário de feriados

👔 **Para Gestores**
┣ Ver calendário do time
┗ Aprovar/devolver solicitações

Digite o que você precisa ou escolha uma das opções acima.
---
```

#### 5.3 Tópico: Consultar Saldo (Com Autenticação)

```
Nome: Consultar Saldo de Férias
Gatilho: Usuário quer saber seu saldo
Frases de gatilho:
- "Qual meu saldo de férias?"
- "Quantos dias de férias eu tenho?"
- "Consultar saldo"
- "Ver dias disponíveis"
- "Férias disponíveis"

Fluxo:
1. [Verificar autenticação - se não autenticado, solicitar login]
2. [Chamar ferramenta: ConsultarSaldoFerias com email do usuário]
3. [Exibir resultado]

Mensagem de sucesso:
---
📊 **Seu Saldo de Férias**

✅ **Dias disponíveis:** {saldo_dias} dias
📅 **Período aquisitivo:** {periodo_aquisitivo}
⏰ **Vencimento:** {vencimento}

> ⚠️ Lembre-se: você deve gozar suas férias antes da data de vencimento para não perder o direito.

Deseja **solicitar férias** agora?
---

Mensagem se saldo zerado:
---
📊 **Seu Saldo de Férias**

Você não possui dias de férias disponíveis no momento.

📅 **Próximo período aquisitivo inicia em:** {proxima_aquisicao}

Posso ajudar com mais alguma coisa?
---
```

#### 5.4 Tópico: Solicitar Férias (Coletar Datas + Validar Regras + Verificar Conflitos)

```
Nome: Solicitar Férias
Gatilho: Usuário quer solicitar férias
Frases de gatilho:
- "Quero tirar férias"
- "Solicitar férias"
- "Pedir férias"
- "Agendar férias"
- "Marcar férias"
- "Quero descansar"

Fluxo Completo:

[PASSO 1 - AUTENTICAÇÃO]
Verificar se usuário está autenticado. Se não:
→ "Para solicitar férias, preciso confirmar sua identidade. Por favor, faça login."

[PASSO 2 - VERIFICAR SALDO]
Chamar: ConsultarSaldoFerias
Se saldo = 0:
→ "Você não possui dias de férias disponíveis. Seu próximo período aquisitivo inicia em {data}."
→ FIM

[PASSO 3 - COLETAR DATA INÍCIO]
Mensagem:
---
Vamos iniciar sua solicitação de férias! 📅

Você tem **{saldo_dias} dias** disponíveis.

**Qual a data de INÍCIO das suas férias?**
(Formato: DD/MM/AAAA)

> 💡 Lembre-se: a solicitação deve ser feita com pelo menos 30 dias de antecedência.
---

[PASSO 4 - VALIDAR DATA INÍCIO]
Validações:
- Data deve ser futura
- Mínimo 30 dias de antecedência
- Não pode ser em período bloqueado (fechamento contábil)

Se inválida:
→ "A data informada não é válida. {motivo}. Por favor, escolha outra data."

[PASSO 5 - COLETAR DATA FIM]
Mensagem:
---
Data de início: **{data_inicio}** ✅

**Qual a data de TÉRMINO das suas férias?**
(Formato: DD/MM/AAAA)

> 📌 Período mínimo: 5 dias | Máximo: 30 dias | Seu saldo: {saldo_dias} dias
---

[PASSO 6 - VALIDAR PERÍODO]
Validações:
- Período entre 5 e 30 dias
- Não exceder saldo disponível
- Data fim > data início

Se inválido:
→ "O período informado não é válido. {motivo}. Por favor, ajuste as datas."

[PASSO 7 - VERIFICAR CONFLITOS ⚠️ CRÍTICO]
Chamar: VerificarConflitos(data_inicio, data_fim, id_time)

SE tem_conflito = TRUE:
---
⚠️ **Atenção: Conflito Detectado!**

As datas solicitadas (**{data_inicio}** a **{data_fim}**) conflitam com férias já aprovadas dos seguintes colaboradores:

{PARA CADA colaborador em colaboradores_conflito}
• **{nome_colaborador}**: {periodo_ferias}
{FIM PARA CADA}

Isso significa que **mais de um membro do time** estará ausente no mesmo período.

**O que você deseja fazer?**
1️⃣ **Prosseguir assim mesmo** (o gestor será informado do conflito)
2️⃣ **Alterar as datas** da solicitação
3️⃣ **Cancelar** esta solicitação
---

[Se escolher 1 - Prosseguir]
→ Marcar tem_conflito = TRUE e continuar

[Se escolher 2 - Alterar datas]
→ Voltar ao PASSO 3

[Se escolher 3 - Cancelar]
→ "Solicitação cancelada. Posso ajudar com mais alguma coisa?"
→ FIM

[PASSO 8 - COLETAR OBSERVAÇÕES (OPCIONAL)]
Mensagem:
---
Deseja adicionar alguma **observação** à sua solicitação?
(Ex: motivo especial, viagem programada, etc.)

Digite sua observação ou "Não" para prosseguir sem observações.
---

[PASSO 9 - CONFIRMAR DADOS]
Mensagem:
---
📋 **Confirme os dados da sua solicitação:**

👤 **Colaborador:** {nome_usuario}
📅 **Período:** {data_inicio} a {data_fim}
📊 **Total de dias:** {total_dias}
{SE tem_conflito}⚠️ **Conflito com:** {nomes_conflito}{FIM SE}
📝 **Observações:** {observacoes}
👔 **Aprovador:** {nome_gestor}

Os dados estão corretos?
✅ Sim, enviar para aprovação
❌ Não, quero alterar
---

[PASSO 10 - CRIAR SOLICITAÇÃO]
Chamar: CriarSolicitacao(email, data_inicio, data_fim, tem_conflito, observacoes)
Chamar: EnviarNotificacao para gestor

Mensagem de sucesso:
---
✅ **Solicitação Criada com Sucesso!**

📌 **Número da solicitação:** #{id_solicitacao}
📅 **Período:** {data_inicio} a {data_fim}
📨 **Status:** Pendente de Aprovação

Seu gestor **{nome_gestor}** foi notificado e analisará sua solicitação em breve.

{SE tem_conflito}
> ⚠️ O gestor foi informado sobre o conflito de datas com outros colaboradores e levará isso em consideração na aprovação.
{FIM SE}

Você receberá uma notificação assim que houver uma decisão.

Posso ajudar com mais alguma coisa?
---
```

#### 5.5 Tópico: Status da Solicitação (Com Autenticação)

```
Nome: Consultar Status de Solicitação
Gatilho: Usuário quer saber status do pedido
Frases de gatilho:
- "Qual o status do meu pedido?"
- "Minha solicitação foi aprovada?"
- "Ver minhas solicitações"
- "Acompanhar férias"
- "Status férias"

Fluxo:
1. Verificar autenticação
2. Chamar: ConsultarStatus(email_usuario)
3. Exibir lista de solicitações

Mensagem:
---
📋 **Suas Solicitações de Férias**

{PARA CADA solicitacao}
━━━━━━━━━━━━━━━━━━━━
📌 **Solicitação #{id}**
📅 Período: {data_inicio} a {data_fim}
📊 Status: {status_emoji} {status}
👔 Aprovador: {nome_gestor}
📝 Observação: {observacao_gestor}
━━━━━━━━━━━━━━━━━━━━
{FIM PARA CADA}

**Legenda:**
⏳ Pendente | ✅ Aprovada | ❌ Rejeitada | 🔄 Devolvida para ajuste

Posso ajudar com mais alguma coisa?
---
```

#### 5.6 Tópico: Cancelar Solicitação

```
Nome: Cancelar Solicitação de Férias
Gatilho: Usuário quer cancelar pedido
Frases de gatilho:
- "Cancelar férias"
- "Desistir das férias"
- "Cancelar minha solicitação"
- "Não quero mais férias"

Fluxo:
1. Verificar autenticação
2. Buscar solicitações pendentes ou aprovadas
3. Listar opções para cancelamento
4. Confirmar cancelamento
5. Processar

Mensagem (se houver solicitações):
---
📋 Encontrei as seguintes solicitações que podem ser canceladas:

{PARA CADA solicitacao}
{numero}. **#{id}** - {data_inicio} a {data_fim} ({status})
{FIM PARA CADA}

**Qual solicitação você deseja cancelar?**
Digite o número correspondente.
---

Confirmação:
---
⚠️ **Confirmar Cancelamento**

Você está prestes a cancelar:
📌 **Solicitação #{id}**
📅 **Período:** {data_inicio} a {data_fim}

**Por favor, informe o motivo do cancelamento:**
---

Após cancelamento:
---
✅ **Solicitação Cancelada**

A solicitação **#{id}** foi cancelada com sucesso.
Seu gestor foi notificado sobre o cancelamento.

Posso ajudar com mais alguma coisa?
---
```

#### 5.7 Tópico: Política de Férias (RAG)

```
Nome: Política de Férias
Gatilho: Usuário pergunta sobre regras
Frases de gatilho:
- "Qual a política de férias?"
- "Regras de férias"
- "Posso vender férias?"
- "Quantos dias de férias tenho direito?"
- "Férias fracionadas"
- "Abono pecuniário"

Configuração: Usar RAG (Retrieval Augmented Generation) conectado à base de conhecimento

Mensagem base:
---
📜 **Política de Férias**

Com base nas políticas da empresa, aqui estão as principais informações:

{Conteúdo gerado pelo RAG baseado na pergunta específica}

---

📚 **Documentos consultados:**
- Política de Férias v2.0
- CLT - Capítulo IV

Essa informação esclarece sua dúvida? Posso detalhar algum ponto específico?
---
```

#### 5.8 Tópico: Feriados e Calendário

```
Nome: Consultar Feriados
Gatilho: Usuário quer ver feriados
Frases de gatilho:
- "Quais são os feriados?"
- "Calendário de feriados"
- "Próximo feriado"
- "Feriados 2026"

Fluxo:
1. Identificar ano de interesse (padrão: ano atual)
2. Chamar: ObterFeriados(ano)
3. Exibir lista

Mensagem:
---
📅 **Calendário de Feriados {ano}**

{PARA CADA feriado}
• **{data}** ({dia_semana}) - {nome_feriado}
{FIM PARA CADA}

---

💡 **Dica:** Planeje suas férias considerando os feriados para aproveitar melhor seus dias de descanso!

Quer que eu simule quantos dias você economizaria emendando férias com feriados?
---
```

#### 5.9 Tópico: Gestor - Visão do Time

```
Nome: Calendário do Time (Gestores)
Gatilho: Gestor quer ver situação do time
Frases de gatilho:
- "Ver férias do meu time"
- "Calendário do time"
- "Quem está de férias?"
- "Ausências do time"
- "Visão gerencial"

Pré-condição: Usuário deve ser gestor (verificar na lista de aprovadores)

Fluxo:
1. Verificar se usuário é gestor
2. Se não for gestor: "Esta função está disponível apenas para gestores."
3. Chamar: ObterCalendarioTime(id_gestor)
4. Exibir visão consolidada

Mensagem:
---
👔 **Visão do Time - {nome_gestor}**

**📅 Férias Aprovadas (próximos 90 dias):**
{PARA CADA ferias_aprovada}
• **{nome_colaborador}**: {data_inicio} a {data_fim}
{FIM PARA CADA}

**⏳ Solicitações Pendentes:**
{PARA CADA ferias_pendente}
• **{nome_colaborador}**: {data_inicio} a {data_fim}
  {SE tem_conflito}⚠️ Conflito com: {nomes_conflito}{FIM SE}
  [Aprovar] [Devolver]
{FIM PARA CADA}

**📊 Resumo:**
• Total de colaboradores: {total}
• Em férias agora: {em_ferias}
• Solicitações pendentes: {pendentes}

Deseja ver mais detalhes ou tomar alguma ação?
---
```

#### 5.10 Tópico: Fallback Inteligente + Escalonar para RH

```
Nome: Fallback e Escalonamento
Gatilho: Sistema Fallback
Configuração: Definir como tópico de fallback do sistema

Mensagem inicial:
---
🤔 Desculpe, não consegui entender completamente sua solicitação.

Você quis dizer alguma destas opções?

1️⃣ Consultar meu saldo de férias
2️⃣ Solicitar férias
3️⃣ Ver status da minha solicitação
4️⃣ Falar com o RH

Ou reformule sua pergunta para eu poder ajudar melhor.
---

Se usuário escolher "Falar com o RH":
---
📞 **Encaminhando para o RH**

Vou conectar você com a equipe de Recursos Humanos para um atendimento personalizado.

**Antes de prosseguir, por favor informe:**
• Seu nome completo
• Sua matrícula
• Breve descrição do que você precisa

Um atendente entrará em contato em até **4 horas úteis**.

---
📧 **Contato direto:** rh@empresa.com
📞 **Ramal:** 2500
---

Enquanto aguarda, posso ajudar com mais alguma coisa?
---
```

#### 5.11 Tópico: Obrigado / Encerramento

```
Nome: Encerramento
Gatilho: Agradecimentos
Frases de gatilho:
- "Obrigado"
- "Valeu"
- "Era só isso"
- "Tchau"
- "Até mais"

Mensagem:
---
😊 Por nada! Foi um prazer ajudar.

Se precisar de algo mais sobre **férias**, é só me chamar!

Boas férias e bom descanso! 🌴
---
```

#### 5.12 Tópico: Recomeçar

```
Nome: Recomeçar Conversa
Gatilho: Reiniciar conversa
Frases de gatilho:
- "Recomeçar"
- "Começar de novo"
- "Reiniciar"
- "Voltar ao início"

Mensagem:
---
🔄 Certo! Vamos começar de novo.

Olá! Como posso ajudar você hoje?

🔹 Consultar saldo de férias
🔹 Solicitar férias
🔹 Ver status de solicitações
🔹 Política de férias
🔹 Falar com o RH
---
```

---

## 6. Solicitações Sugeridas

### 💬 Chips/Botões de Sugestão

Configure as seguintes sugestões para aparecerem na interface do chat:

```
┌─────────────────────────────────────────────────────────────────┐
│ Solicitações Sugeridas (Quick Replies)                         │
├─────────────────────────────────────────────────────────────────┤
│ "📅 Consultar meu saldo"                                        │
│ "🌴 Solicitar férias"                                           │
│ "🔍 Ver status do meu pedido"                                   │
│ "📋 Política de férias"                                         │
│ "📆 Ver feriados"                                               │
│ "👔 Calendário do time" (apenas para gestores)                  │
│ "❓ Ajuda"                                                       │
└─────────────────────────────────────────────────────────────────┘
```

### Textos para Configurar

| Nº | Texto do Chip | Tópico Associado |
|----|--------------|------------------|
| 1 | 📅 Consultar meu saldo | Consultar Saldo de Férias |
| 2 | 🌴 Solicitar férias | Solicitar Férias |
| 3 | 🔍 Ver meu pedido | Consultar Status |
| 4 | 📋 Política de férias | Política de Férias |
| 5 | 📆 Ver feriados | Feriados e Calendário |
| 6 | 👔 Visão do time | Gestor - Visão do Time |

---

## 7. Base de Conhecimento (Knowledge)

### 📚 Configuração Obrigatória do Knowledge Base

#### Fontes de Dados Recomendadas

| Tipo | Nome | Descrição | Conteúdo |
|------|------|-----------|----------|
| **SharePoint** | Lista Colaboradores | `Users_Approvers.xlsx` | Nomes, emails, gestores |
| **SharePoint** | Lista Histórico | `Historico_Ferias` | Férias aprovadas/rejeitadas |
| **Documento** | Política de Férias | PDF/Word | Regras, direitos, deveres |
| **Documento** | FAQ Férias | PDF/Word | Perguntas frequentes |
| **SharePoint** | Calendário Corporativo | Lista | Feriados, períodos bloqueados |

#### Documento: Política de Férias (Exemplo de Conteúdo para RAG)

```markdown
# Política de Férias - [Nome da Empresa]

## 1. Direito a Férias
Todo colaborador tem direito a 30 dias de férias após completar 12 meses de trabalho (período aquisitivo).

## 2. Período de Gozo
- As férias devem ser gozadas nos 12 meses subsequentes ao período aquisitivo
- Solicitações devem ser feitas com mínimo de 30 dias de antecedência

## 3. Fracionamento
- Permitido fracionar em até 3 períodos
- Um período deve ter no mínimo 14 dias
- Demais períodos: mínimo de 5 dias cada

## 4. Abono Pecuniário
- O colaborador pode vender até 1/3 das férias (10 dias)
- Solicitação deve ser feita até 15 dias antes do término do período aquisitivo

## 5. Períodos Bloqueados
- Fechamento contábil (últimos 5 dias úteis de cada trimestre)
- Inventário anual (primeira semana de janeiro)

## 6. Conflitos de Período
- Em caso de conflito entre colaboradores do mesmo time, a prioridade é dada por:
  1. Quem solicitou primeiro
  2. Quem não tirou férias no período anterior
  3. Critério do gestor

## 7. Cancelamento
- Férias já aprovadas podem ser canceladas com 15 dias de antecedência
- Cancelamentos de última hora requerem aprovação do RH
```

#### Configuração do Knowledge no Copilot Studio

```
1. Acesse: Conhecimento (Knowledge) > Adicionar fonte
2. Selecione: SharePoint/OneDrive
3. Adicione os documentos:
   - Politica_Ferias.pdf
   - FAQ_Ferias.docx
   - Users_Approvers.xlsx

4. Configure indexação:
   - Frequência: Diária
   - Tipo de conteúdo: Documentos e Listas

5. Teste o RAG:
   - Pergunte: "Posso fracionar minhas férias?"
   - Verifique se a resposta cita a política corretamente
```

---

## 8. Configuração de Fallback e Escalonamento

### ⚡ Fallback Inteligente

#### Configuração do Sistema de Fallback

```
Nível 1 - Desambiguação Automática:
┌────────────────────────────────────────────────────────────────────┐
│ Quando o agente não entender, mostrar:                             │
│                                                                     │
│ "Não consegui entender. Você quis dizer:"                          │
│ • [Consultar saldo]                                                 │
│ • [Solicitar férias]                                                │
│ • [Falar com RH]                                                    │
└────────────────────────────────────────────────────────────────────┘

Nível 2 - Segunda tentativa falha:
┌────────────────────────────────────────────────────────────────────┐
│ "Ainda estou com dificuldade para entender."                       │
│                                                                     │
│ Por favor, escolha uma opção ou digite 'RH' para                   │
│ falar com um atendente humano.                                      │
└────────────────────────────────────────────────────────────────────┘

Nível 3 - Handoff para RH:
┌────────────────────────────────────────────────────────────────────┐
│ "Vou transferir você para a equipe de RH."                         │
│                                                                     │
│ 📧 Email: rh@empresa.com                                            │
│ 📞 Ramal: 2500                                                      │
│ ⏰ Horário: 08h às 18h                                              │
│                                                                     │
│ Um ticket foi aberto automaticamente (#XXXX).                       │
│ Você receberá retorno em até 4 horas úteis.                         │
└────────────────────────────────────────────────────────────────────┘
```

#### Configuração Técnica do Handoff

```
Nome do Tópico: Escalonamento para RH
Tipo: Tópico do Sistema (Fallback)

Condições de Ativação:
1. Fallback ativado 3 vezes consecutivas
2. Usuário digita "RH" ou "humano" ou "atendente"
3. Erro crítico no processamento

Ações:
1. Coletar informações do usuário (nome, email, matrícula)
2. Registrar conversa até o momento
3. Criar ticket no sistema de chamados (Power Automate)
4. Enviar email para rh@empresa.com com contexto
5. Exibir mensagem de confirmação

Fluxo Power Automate associado: "CriarTicketRH"
```

---

## 9. Fluxos Power Automate Detalhados

### 🔄 Arquitetura dos Fluxos

```
┌─────────────────────────────────────────────────────────────────────┐
│                    FLUXOS POWER AUTOMATE                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌───────────────────┐    ┌───────────────────┐                     │
│  │ Flow 1: Consultar │    │ Flow 2: Verificar │                     │
│  │    Saldo Férias   │    │     Conflitos     │                     │
│  └───────────────────┘    └───────────────────┘                     │
│           │                        │                                 │
│           ▼                        ▼                                 │
│  ┌─────────────────────────────────────────────┐                    │
│  │         Flow 3: Criar Solicitação           │                    │
│  │  (Inclui validação + notificação gestor)    │                    │
│  └─────────────────────────────────────────────┘                    │
│                        │                                             │
│           ┌────────────┴────────────┐                               │
│           ▼                         ▼                                │
│  ┌─────────────────┐      ┌─────────────────┐                       │
│  │ Flow 4: Aprovar │      │ Flow 5: Rejeitar│                       │
│  │   (Gestor)      │      │    (Gestor)     │                       │
│  └─────────────────┘      └─────────────────┘                       │
│           │                         │                                │
│           └────────────┬────────────┘                               │
│                        ▼                                             │
│  ┌─────────────────────────────────────────────┐                    │
│  │     Flow 6: Notificação Multicanal          │                    │
│  │     (Teams + Email + Atualização Lista)     │                    │
│  └─────────────────────────────────────────────┘                    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Fluxo Principal: Verificar Conflitos e Criar Solicitação

```yaml
Nome: SolicitarFerias_ComVerificacaoConflitos
Gatilho: HTTP Request (chamado pelo Copilot Studio)

Passos:
  1. Parse JSON:
     - Input: Body do request
     - Extrair: email, data_inicio, data_fim

  2. Obter Colaborador:
     - Ação: SharePoint - Obter itens
     - Lista: Users_Approvers
     - Filtro: Email eq '{email}'
     - Retorno: Nome, Departamento, Gestor

  3. Verificar Conflitos:
     - Ação: SharePoint - Obter itens
     - Lista: Historico_Ferias
     - Filtro: 
       Status eq 'Aprovado' AND
       Departamento eq '{departamento}' AND
       (
        (DataInicio le '{data_fim}' AND DataFim ge '{data_inicio}')
      )
     - Retorno: Lista de colaboradores com conflito

  4. Condição - Há Conflitos?:
     - Se Sim:
       - Formatar lista de conflitos
       - Retornar: { tem_conflito: true, colaboradores: [...] }
     - Se Não:
       - Retornar: { tem_conflito: false }

  5. (Após confirmação do usuário) Criar Solicitação:
     - Ação: SharePoint - Criar item
     - Lista: Solicitacoes_Ferias
     - Dados:
       - Colaborador: {email}
       - DataInicio: {data_inicio}
       - DataFim: {data_fim}
       - Status: "Pendente"
       - TemConflito: {tem_conflito}
       - ColaboradoresConflito: {lista_conflitos}
       - DataSolicitacao: utcNow()

  6. Notificar Gestor:
     - Ação: Teams - Postar Adaptive Card no chat
     - Destinatário: {email_gestor}
     - Card: (ver modelo abaixo)

  7. Enviar Email ao Gestor:
     - Ação: Outlook - Enviar email
     - Para: {email_gestor}
     - Assunto: "Nova Solicitação de Férias - {nome_colaborador}"
     - Corpo: (template HTML)
```

### Adaptive Card para Aprovação do Gestor

```json
{
  "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
  "type": "AdaptiveCard",
  "version": "1.4",
  "body": [
    {
      "type": "TextBlock",
      "text": "🌴 Nova Solicitação de Férias",
      "weight": "Bolder",
      "size": "Large"
    },
    {
      "type": "FactSet",
      "facts": [
        { "title": "Colaborador:", "value": "${nome_colaborador}" },
        { "title": "Período:", "value": "${data_inicio} a ${data_fim}" },
        { "title": "Total de dias:", "value": "${total_dias}" },
        { "title": "Data da solicitação:", "value": "${data_solicitacao}" }
      ]
    },
    {
      "type": "TextBlock",
      "text": "⚠️ ATENÇÃO: Esta solicitação possui CONFLITO com:",
      "color": "Warning",
      "weight": "Bolder",
      "$when": "${tem_conflito}"
    },
    {
      "type": "TextBlock",
      "text": "${lista_conflitos}",
      "wrap": true,
      "$when": "${tem_conflito}"
    },
    {
      "type": "TextBlock",
      "text": "Observações do colaborador:",
      "weight": "Bolder"
    },
    {
      "type": "TextBlock",
      "text": "${observacoes}",
      "wrap": true
    }
  ],
  "actions": [
    {
      "type": "Action.Submit",
      "title": "✅ Aprovar",
      "style": "positive",
      "data": {
        "action": "aprovar",
        "id_solicitacao": "${id}"
      }
    },
    {
      "type": "Action.ShowCard",
      "title": "❌ Devolver",
      "card": {
        "type": "AdaptiveCard",
        "body": [
          {
            "type": "TextBlock",
            "text": "Motivo da devolução:"
          },
          {
            "type": "Input.Text",
            "id": "motivo_devolucao",
            "isMultiline": true,
            "placeholder": "Informe o motivo..."
          }
        ],
        "actions": [
          {
            "type": "Action.Submit",
            "title": "Enviar Devolução",
            "data": {
              "action": "devolver",
              "id_solicitacao": "${id}"
            }
          }
        ]
      }
    }
  ]
}
```

---

## 📋 Checklist de Implementação

Use este checklist para garantir que todas as configurações foram aplicadas:

- [ ] **Instruções do Agente** configuradas com escopo, prioridades e limites
- [ ] **9 Ferramentas** Power Automate criadas e conectadas
- [ ] **4 Gatilhos** configurados para eventos automáticos
- [ ] **12 Tópicos** criados e testados
- [ ] **6 Solicitações Sugeridas** adicionadas
- [ ] **5 Fontes de Conhecimento** indexadas
- [ ] **Fallback** com 3 níveis + handoff para RH
- [ ] **Fluxos Power Automate** implementados e publicados
- [ ] **Adaptive Cards** testados no Teams
- [ ] **Teste ponta a ponta** com cenário de conflito

---

## 🚀 Próximos Passos

1. **Importar arquivo Excel** `Users_Approvers.xlsx` para SharePoint
2. **Criar lista SharePoint** `Historico_Ferias` e `Solicitacoes_Ferias`
3. **Desenvolver os 9 fluxos** Power Automate
4. **Configurar cada tópico** no Copilot Studio
5. **Testar cenários críticos**: solicitação com conflito, aprovação, rejeição
6. **Publicar e monitorar** métricas de uso

---

> **Documento criado por:** Claude AI - Senior Microsoft Solutions Architect
> **Última atualização:** 24/01/2026
> **Versão:** 1.0
