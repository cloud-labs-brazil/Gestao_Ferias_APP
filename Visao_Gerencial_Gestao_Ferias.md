# 👔 Visão Gerencial Completa - Agente "Gestão Férias"

> **Documento complementar** focado nas funcionalidades de visualização e gestão para gerentes e diretores.

---

## Índice

1. [Visão Geral da Solução para Gestores](#1-visão-geral-da-solução-para-gestores)
2. [Dashboard de Situação Atual](#2-dashboard-de-situação-atual)
3. [Alertas Proativos](#3-alertas-proativos)
4. [Tópicos Específicos para Gestores](#4-tópicos-específicos-para-gestores)
5. [Adaptive Cards para Gestores](#5-adaptive-cards-para-gestores)
6. [Relatórios e Exportações](#6-relatórios-e-exportações)
7. [Fallback Revisado (Sem RH)](#7-fallback-revisado-sem-rh)

---

## 1. Visão Geral da Solução para Gestores

### 🎯 Objetivos da Visão Gerencial

```
┌─────────────────────────────────────────────────────────────────────┐
│                    VISIBILIDADE PARA GESTÃO                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  📊 SITUAÇÃO ATUAL                                                  │
│  • Quem está de férias AGORA?                                       │
│  • Quantos colaboradores do time estão ausentes?                    │
│  • Há solicitações pendentes de aprovação?                          │
│                                                                      │
│  📅 PRÓXIMOS 30/60/90 DIAS                                          │
│  • Quem entra de férias em breve?                                   │
│  • Há períodos com muitos ausentes ao mesmo tempo?                  │
│  • Quais datas estão "críticas" (muita sobreposição)?               │
│                                                                      │
│  ⚠️ ALERTAS CRÍTICOS                                                │
│  • Quem tem férias vencendo nos próximos 60 dias?                   │
│  • Quem tem DUAS férias prestes a vencer?                           │
│  • Quem nunca tirou férias no último ano?                           │
│                                                                      │
│  📈 PLANEJAMENTO                                                    │
│  • Calendário visual do time                                        │
│  • Exportação para Excel/PDF                                        │
│  • Integração com calendário Outlook/Teams                          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 2. Dashboard de Situação Atual

### 📊 Tópico: Dashboard Gerencial

```
Nome: Dashboard do Gestor
Gatilho: Gestor pede visão geral
Frases de gatilho:
- "Dashboard"
- "Situação do time"
- "Visão geral"
- "Resumo de férias"
- "Como está meu time?"
- "Painel gerencial"

Pré-condição: Verificar se usuário é gestor (buscar em Users_Approvers.xlsx)

Mensagem Principal:
---
👔 **Dashboard de Férias - {nome_gestor}**
📅 Atualizado em: {data_hora_atual}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 📍 AGORA (Colaboradores de Férias Hoje)

{SE nenhum_de_ferias}
✅ Nenhum colaborador está de férias hoje.
{SENÃO}
{PARA CADA colaborador_em_ferias}
🌴 **{nome}** - até {data_retorno} ({dias_restantes} dias restantes)
{FIM PARA CADA}
{FIM SE}

**Total ausentes:** {total_ausentes} de {total_time} colaboradores

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 📅 PRÓXIMOS 30 DIAS

{PARA CADA ferias_futuras ordenado por data}
📆 **{data_inicio}** → {nome} ({total_dias} dias)
{FIM PARA CADA}

{SE ha_sobreposicoes}
⚠️ **Atenção:** Há períodos com **{max_sobreposicao} pessoas** ausentes simultaneamente.
{FIM SE}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## ⏳ PENDENTES DE APROVAÇÃO

{SE ha_pendentes}
{PARA CADA solicitacao_pendente}
🔔 **{nome}**: {data_inicio} a {data_fim}
   {SE tem_conflito}⚠️ Conflito com: {nomes_conflito}{FIM SE}
   [👍 Aprovar] [👎 Devolver] [📋 Detalhes]
{FIM PARA CADA}
{SENÃO}
✅ Não há solicitações pendentes de aprovação.
{FIM SE}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 🚨 ALERTAS CRÍTICOS

{PARA CADA alerta}
{SE tipo = "vencimento_proximo"}
⚠️ **{nome}** tem {dias_ferias} dias vencendo em **{data_vencimento}** ({dias_restantes} dias)
{FIM SE}
{SE tipo = "duas_ferias_vencendo"}
🔴 **{nome}** tem **2 períodos** prestes a vencer! Total: {total_dias} dias
{FIM SE}
{SE tipo = "nunca_tirou"}
⚠️ **{nome}** não tirou férias nos últimos 12 meses
{FIM SE}
{FIM PARA CADA}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**O que você gostaria de fazer?**
📆 Ver calendário completo
📊 Ver detalhes de um colaborador
📋 Aprovar solicitações pendentes
📤 Exportar relatório
---
```

---

## 3. Alertas Proativos

### 🔔 Sistema de Alertas Automáticos

Configure os seguintes gatilhos para enviar alertas proativos aos gestores:

| Alerta | Condição | Frequência | Canal |
|--------|----------|------------|-------|
| **Férias Vencendo** | Saldo vence em ≤ 60 dias | Semanal (segunda-feira) | Teams + Email |
| **Férias Duplas Críticas** | 2 períodos vencendo em ≤ 90 dias | Imediato ao detectar | Teams + Email |
| **Solicitação Pendente** | Aguardando aprovação há > 48h | Diário | Teams |
| **Alta Sobreposição** | ≥ 3 pessoas do time ausentes no mesmo período | Ao criar solicitação | Teams |
| **Resumo Semanal** | Toda segunda-feira | Semanal | Email |

### Mensagem de Alerta: Férias Vencendo

```
🚨 **Alerta: Férias Prestes a Vencer**

Olá {nome_gestor},

Os seguintes colaboradores do seu time têm férias vencendo em breve:

{PARA CADA colaborador}
━━━━━━━━━━━━━━━━━━━━━━━━━━
👤 **{nome_colaborador}**
📊 Saldo: {dias_disponiveis} dias
📅 Vencimento: {data_vencimento}
⏰ Dias restantes: {dias_para_vencer}
━━━━━━━━━━━━━━━━━━━━━━━━━━
{FIM PARA CADA}

**Ação recomendada:** Entre em contato com esses colaboradores para planejar as férias antes do vencimento.

[📅 Ver Calendário do Time] [💬 Abrir Chat com Bot]
```

### Mensagem de Alerta: Duas Férias Vencendo (CRÍTICO)

```
🔴 **ALERTA CRÍTICO: Férias Duplas Prestes a Vencer**

Olá {nome_gestor},

**{nome_colaborador}** possui **2 períodos de férias** que vencerão em breve!

┌─────────────────────────────────────────┐
│ 📅 **Período 1**                        │
│ Saldo: {dias_1} dias                    │
│ Vencimento: {vencimento_1}              │
├─────────────────────────────────────────┤
│ 📅 **Período 2**                        │
│ Saldo: {dias_2} dias                    │
│ Vencimento: {vencimento_2}              │
├─────────────────────────────────────────┤
│ 📊 **TOTAL EM RISCO:** {total} dias     │
└─────────────────────────────────────────┘

⚠️ **Ação urgente necessária!**
O colaborador precisa programar {total} dias de férias nos próximos {dias_disponiveis} dias.

**Sugestão:** Agende uma conversa com {nome_colaborador} para definir as datas o mais rápido possível.

[📞 Agendar Reunião] [📧 Enviar Lembrete ao Colaborador]
```

### Mensagem: Resumo Semanal (Segunda-feira)

```
📊 **Resumo Semanal de Férias - {nome_time}**
Semana de {data_inicio_semana} a {data_fim_semana}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 🌴 DE FÉRIAS ESTA SEMANA
{PARA CADA em_ferias}
• {nome} ({data_inicio} - {data_fim})
{FIM PARA CADA}
{SE nenhum}• Nenhum colaborador de férias{FIM SE}

## 📆 RETORNANDO ESTA SEMANA
{PARA CADA retornando}
• {nome} retorna em {data_retorno}
{FIM PARA CADA}
{SE nenhum}• Nenhum retorno previsto{FIM SE}

## 🗓️ SAINDO DE FÉRIAS ESTA SEMANA
{PARA CADA saindo}
• {nome} sai em {data_inicio}
{FIM PARA CADA}
{SE nenhum}• Nenhuma saída prevista{FIM SE}

## ⚠️ ATENÇÃO NECESSÁRIA
• **{qtd_pendentes}** solicitações aguardando sua aprovação
• **{qtd_vencendo}** colaboradores com férias vencendo em 60 dias
• **{qtd_critico}** casos críticos (2 períodos vencendo)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[📊 Abrir Dashboard Completo] [📅 Ver Calendário]
```

---

## 4. Tópicos Específicos para Gestores

### 📅 Tópico: Calendário Visual do Time

```
Nome: Calendário do Time
Gatilho: Gestor quer ver calendário
Frases de gatilho:
- "Calendário do time"
- "Mostrar férias do time"
- "Visualizar ausências"
- "Agenda de férias"
- "Quem vai sair de férias?"

Mensagem:
---
📅 **Calendário de Férias - {nome_time}**

Selecione o período que deseja visualizar:
1️⃣ Este mês ({mes_atual})
2️⃣ Próximos 30 dias
3️⃣ Próximos 60 dias
4️⃣ Próximos 90 dias
5️⃣ Mês específico
---

Após seleção (exemplo: próximos 30 dias):
---
📅 **Férias Programadas: {data_inicio} a {data_fim}**

```

       JANEIRO 2026
   D   S   T   Q   Q   S   S
               1   2   3   4
   5   6   7   8   9  10  11
  12  13  14  15  16  17  18
  19  20  21  22  23  24  25
  26  27  28  29  30  31

🔵 = João Silva (15-22)
🟢 = Maria Santos (18-25)
🟡 = Pedro Alves (20-31)

```

**Detalhamento:**
| Colaborador | Período | Dias | Status |
|-------------|---------|------|--------|
| João Silva | 15/01 - 22/01 | 8 | ✅ Aprovado |
| Maria Santos | 18/01 - 25/01 | 8 | ✅ Aprovado |
| Pedro Alves | 20/01 - 31/01 | 12 | ⏳ Pendente |

⚠️ **Atenção:** Entre 20/01 e 22/01 haverá **3 pessoas** ausentes simultaneamente.

**Opções:**
📤 Exportar calendário (Excel/PDF)
📧 Compartilhar com outro gestor
📅 Sincronizar com Outlook
---
```

### 📋 Tópico: Ver Saldo de Todo o Time

```
Nome: Saldo do Time
Gatilho: Gestor quer ver saldos
Frases de gatilho:
- "Saldo do time"
- "Férias disponíveis do time"
- "Quem tem mais férias?"
- "Colaboradores com férias vencendo"

Mensagem:
---
📊 **Saldo de Férias do Time - {nome_time}**

| Colaborador | Saldo | Vencimento | Status |
|-------------|-------|------------|--------|
{PARA CADA colaborador ordenado por vencimento}
| {nome} | {saldo} dias | {vencimento} | {status_emoji} |
{FIM PARA CADA}

**Legenda:**
🔴 Crítico (vence em < 30 dias)
🟡 Atenção (vence em < 60 dias)
🟢 OK (vence em > 60 dias)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Resumo:**
• Total de dias a vencer no time: **{total_dias}**
• Colaboradores em situação crítica: **{qtd_criticos}**
• Colaboradores com 2 períodos: **{qtd_duplos}**

Deseja enviar lembrete para os colaboradores em situação crítica?
[📧 Sim, enviar lembretes] [📋 Ver detalhes de um colaborador]
---
```

### 👤 Tópico: Detalhe de Colaborador Específico

```
Nome: Consultar Colaborador
Gatilho: Gestor quer ver detalhes de alguém
Frases de gatilho:
- "Ver férias de [nome]"
- "Situação do [nome]"
- "Consultar [nome]"
- "Histórico de férias de [nome]"

Fluxo:
1. Identificar colaborador mencionado (ou pedir nome)
2. Verificar se faz parte do time do gestor
3. Buscar informações completas

Mensagem:
---
👤 **Perfil de Férias: {nome_colaborador}**

**📊 Saldo Atual**
┌─────────────────────────────────────┐
│ Período 1 (2024/2025)               │
│ Saldo: {saldo_1} dias               │
│ Vencimento: {venc_1}                │
│ Status: {status_1}                  │
├─────────────────────────────────────┤
│ Período 2 (2025/2026)               │
│ Saldo: {saldo_2} dias               │
│ Vencimento: {venc_2}                │
│ Status: {status_2}                  │
└─────────────────────────────────────┘

**📅 Férias Programadas**
{PARA CADA ferias_futuras}
• {data_inicio} - {data_fim} ({dias} dias) - {status}
{FIM PARA CADA}
{SE nenhuma}• Nenhuma férias programada{FIM SE}

**📜 Histórico (últimos 2 anos)**
{PARA CADA ferias_passadas}
• {data_inicio} - {data_fim} ({dias} dias)
{FIM PARA CADA}

**📈 Estatísticas**
• Total de férias tiradas (2 anos): {total_dias_tirados} dias
• Última férias: {data_ultima_ferias}
• Dias desde a última férias: {dias_desde_ultima}

**Ações disponíveis:**
[📧 Enviar lembrete] [📅 Sugerir datas] [📊 Voltar ao dashboard]
---
```

### 🔄 Tópico: Aprovar/Devolver Solicitações em Lote

```
Nome: Gestão de Solicitações
Gatilho: Gestor quer gerenciar pendências
Frases de gatilho:
- "Ver solicitações pendentes"
- "Aprovar férias"
- "Minhas pendências"
- "O que preciso aprovar?"

Mensagem:
---
📋 **Solicitações Pendentes de Aprovação**

{SE nenhuma_pendente}
✅ Não há solicitações pendentes. Seu time está em dia!
{SENÃO}

Você tem **{total_pendentes}** solicitações aguardando aprovação:

{PARA CADA solicitacao ordenado por data_solicitacao}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📌 **Solicitação #{id}**
👤 Colaborador: **{nome_colaborador}**
📅 Período solicitado: {data_inicio} a {data_fim}
📊 Total: {total_dias} dias
⏰ Solicitado há: {dias_aguardando} dias

{SE tem_conflito}
⚠️ **CONFLITO DETECTADO:**
Esta solicitação conflita com:
{PARA CADA conflito}
   • {nome_conflito}: {periodo_conflito}
{FIM PARA CADA}
{FIM SE}

📝 Observação: {observacao}

[✅ Aprovar] [❌ Devolver] [📋 Ver mais detalhes]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
{FIM PARA CADA}

**Ação em lote:**
[✅ Aprovar todas sem conflito] [📊 Voltar ao Dashboard]
{FIM SE}
---
```

---

## 5. Adaptive Cards para Gestores

### Card: Dashboard Resumido (para Teams)

```json
{
  "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
  "type": "AdaptiveCard",
  "version": "1.4",
  "body": [
    {
      "type": "TextBlock",
      "text": "👔 Dashboard de Férias",
      "weight": "Bolder",
      "size": "Large"
    },
    {
      "type": "TextBlock",
      "text": "Atualizado: ${data_hora}",
      "isSubtle": true,
      "size": "Small"
    },
    {
      "type": "ColumnSet",
      "columns": [
        {
          "type": "Column",
          "width": "stretch",
          "items": [
            {
              "type": "TextBlock",
              "text": "🌴 De Férias",
              "weight": "Bolder"
            },
            {
              "type": "TextBlock",
              "text": "${qtd_ferias}",
              "size": "ExtraLarge",
              "color": "Good"
            }
          ]
        },
        {
          "type": "Column",
          "width": "stretch",
          "items": [
            {
              "type": "TextBlock",
              "text": "⏳ Pendentes",
              "weight": "Bolder"
            },
            {
              "type": "TextBlock",
              "text": "${qtd_pendentes}",
              "size": "ExtraLarge",
              "color": "Warning"
            }
          ]
        },
        {
          "type": "Column",
          "width": "stretch",
          "items": [
            {
              "type": "TextBlock",
              "text": "🚨 Alertas",
              "weight": "Bolder"
            },
            {
              "type": "TextBlock",
              "text": "${qtd_alertas}",
              "size": "ExtraLarge",
              "color": "Attention"
            }
          ]
        }
      ]
    },
    {
      "type": "TextBlock",
      "text": "Próximas Férias (7 dias)",
      "weight": "Bolder",
      "separator": true
    },
    {
      "type": "FactSet",
      "facts": [
        {
          "title": "${nome_1}",
          "value": "${periodo_1}"
        },
        {
          "title": "${nome_2}",
          "value": "${periodo_2}"
        },
        {
          "title": "${nome_3}",
          "value": "${periodo_3}"
        }
      ]
    },
    {
      "type": "TextBlock",
      "text": "⚠️ Alertas Críticos",
      "weight": "Bolder",
      "color": "Attention",
      "separator": true,
      "$when": "${qtd_alertas > 0}"
    },
    {
      "type": "TextBlock",
      "text": "${lista_alertas}",
      "wrap": true,
      "$when": "${qtd_alertas > 0}"
    }
  ],
  "actions": [
    {
      "type": "Action.Submit",
      "title": "📊 Dashboard Completo",
      "data": {
        "action": "dashboard_completo"
      }
    },
    {
      "type": "Action.Submit",
      "title": "📋 Ver Pendências",
      "data": {
        "action": "ver_pendencias"
      }
    },
    {
      "type": "Action.Submit",
      "title": "📅 Calendário",
      "data": {
        "action": "ver_calendario"
      }
    }
  ]
}
```

### Card: Solicitação com Conflito (para Aprovação)

```json
{
  "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
  "type": "AdaptiveCard",
  "version": "1.4",
  "body": [
    {
      "type": "Container",
      "style": "warning",
      "items": [
        {
          "type": "TextBlock",
          "text": "⚠️ Solicitação com Conflito",
          "weight": "Bolder",
          "size": "Medium"
        }
      ]
    },
    {
      "type": "FactSet",
      "facts": [
        { "title": "Colaborador", "value": "${nome_colaborador}" },
        { "title": "Período", "value": "${data_inicio} a ${data_fim}" },
        { "title": "Total", "value": "${total_dias} dias" },
        { "title": "Solicitado em", "value": "${data_solicitacao}" }
      ]
    },
    {
      "type": "TextBlock",
      "text": "🔴 CONFLITA COM:",
      "weight": "Bolder",
      "color": "Attention",
      "separator": true
    },
    {
      "type": "Container",
      "style": "attention",
      "items": [
        {
          "type": "TextBlock",
          "text": "${lista_conflitos}",
          "wrap": true
        }
      ]
    },
    {
      "type": "TextBlock",
      "text": "📝 Observação do colaborador:",
      "weight": "Bolder",
      "separator": true
    },
    {
      "type": "TextBlock",
      "text": "${observacao}",
      "wrap": true,
      "isSubtle": true
    },
    {
      "type": "TextBlock",
      "text": "📊 Impacto no Time:",
      "weight": "Bolder",
      "separator": true
    },
    {
      "type": "TextBlock",
      "text": "Se aprovado, haverá **${total_ausentes}** pessoas ausentes entre ${data_conflito_inicio} e ${data_conflito_fim}.",
      "wrap": true
    }
  ],
  "actions": [
    {
      "type": "Action.Submit",
      "title": "✅ Aprovar Mesmo Assim",
      "style": "positive",
      "data": {
        "action": "aprovar",
        "id_solicitacao": "${id}",
        "conflito_aceito": true
      }
    },
    {
      "type": "Action.ShowCard",
      "title": "↩️ Devolver para Ajuste",
      "card": {
        "type": "AdaptiveCard",
        "body": [
          {
            "type": "TextBlock",
            "text": "Motivo da devolução:"
          },
          {
            "type": "Input.ChoiceSet",
            "id": "motivo_padrao",
            "style": "expanded",
            "choices": [
              {
                "title": "Conflito de datas com outro colaborador",
                "value": "conflito"
              },
              {
                "title": "Período crítico para o projeto",
                "value": "projeto"
              },
              {
                "title": "Sugiro outras datas",
                "value": "outras_datas"
              }
            ]
          },
          {
            "type": "Input.Text",
            "id": "mensagem_adicional",
            "placeholder": "Mensagem adicional (opcional)...",
            "isMultiline": true
          },
          {
            "type": "Input.Text",
            "id": "datas_sugeridas",
            "placeholder": "Datas alternativas sugeridas (opcional)..."
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
    },
    {
      "type": "Action.Submit",
      "title": "📅 Ver Calendário",
      "data": {
        "action": "ver_calendario_periodo",
        "data_inicio": "${data_inicio}",
        "data_fim": "${data_fim}"
      }
    }
  ]
}
```

---

## 6. Relatórios e Exportações

### 📤 Tópico: Exportar Relatórios

```
Nome: Exportar Relatório
Gatilho: Gestor quer exportar dados
Frases de gatilho:
- "Exportar relatório"
- "Baixar planilha"
- "Gerar Excel"
- "Relatório de férias"
- "Exportar calendário"

Mensagem:
---
📤 **Exportar Relatório de Férias**

Qual relatório você deseja gerar?

1️⃣ **Calendário do Time** (próximos 90 dias)
   - Férias aprovadas e pendentes
   - Formato: Excel ou PDF

2️⃣ **Saldo de Férias do Time**
   - Todos os colaboradores com saldos
   - Ordenado por vencimento
   - Formato: Excel

3️⃣ **Histórico Completo**
   - Todas as férias dos últimos 2 anos
   - Formato: Excel

4️⃣ **Alertas e Pendências**
   - Colaboradores com férias vencendo
   - Solicitações aguardando aprovação
   - Formato: PDF

5️⃣ **Relatório Executivo**
   - Resumo consolidado para diretoria
   - Gráficos e indicadores
   - Formato: PowerPoint ou PDF
---

Após seleção:
---
⏳ Gerando relatório...

✅ **Relatório Gerado com Sucesso!**

📎 Arquivo: {nome_arquivo}
📊 Tipo: {formato}
📅 Data de geração: {data_hora}

O arquivo foi enviado para seu email ({email_gestor}) e também está disponível nos links abaixo:

[📥 Baixar Arquivo] [📧 Enviar para outro email] [📅 Agendar relatório recorrente]
---
```

### Estrutura do Relatório Excel (Exemplo)

```
┌─────────────────────────────────────────────────────────────────────┐
│ RELATÓRIO DE FÉRIAS - {NOME_TIME}                                   │
│ Gerado em: {DATA_HORA}                                              │
├─────────────────────────────────────────────────────────────────────┤

ABA 1: RESUMO EXECUTIVO
├── Total de colaboradores: XX
├── Em férias atualmente: XX
├── Solicitações pendentes: XX
├── Colaboradores com saldo crítico: XX
└── Total de dias a vencer (90 dias): XX

ABA 2: CALENDÁRIO
│ Colaborador │ Jan │ Fev │ Mar │ ... │
│ João Silva  │ ███ │     │ ██  │     │
│ Maria...    │     │ █████████ │     │

ABA 3: SALDO POR COLABORADOR
│ Nome │ Saldo 1 │ Venc 1 │ Saldo 2 │ Venc 2 │ Total │ Status │

ABA 4: SOLICITAÇÕES PENDENTES
│ ID │ Colaborador │ Período │ Dias │ Conflito │ Data Solic │

ABA 5: ALERTAS
│ Tipo │ Colaborador │ Descrição │ Urgência │ Ação Sugerida │

└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. Fallback Revisado (Sem RH)

### 🔄 Fallback de Autoatendimento

Como não há handoff para RH, o fallback deve guiar o usuário para resolver sozinho:

```
Nome: Fallback Inteligente
Gatilho: Sistema Fallback (quando não entende)

Nível 1 - Desambiguação:
---
🤔 Não consegui entender completamente sua solicitação.

Você quis dizer alguma destas opções?

**Para Colaboradores:**
1️⃣ Consultar meu saldo de férias
2️⃣ Solicitar férias
3️⃣ Ver status da minha solicitação
4️⃣ Política de férias

**Para Gestores:**
5️⃣ Ver dashboard do time
6️⃣ Aprovar solicitações pendentes
7️⃣ Calendário do time

Ou reformule sua pergunta para eu poder ajudar melhor.
---

Nível 2 - Segunda tentativa falha:
---
😅 Ainda estou com dificuldade para entender.

Vou te mostrar um guia rápido do que posso fazer:

📌 **CONSULTAS**
• "Qual meu saldo?" → Seus dias de férias disponíveis
• "Status do meu pedido" → Situação das suas solicitações

📌 **AÇÕES**
• "Quero tirar férias" → Iniciar uma nova solicitação
• "Cancelar férias" → Cancelar uma solicitação existente

📌 **GESTOR**
• "Dashboard" → Painel completo do time
• "Pendências" → Solicitações aguardando aprovação

Escolha uma opção ou digite "menu" para ver todas as opções.
---

Nível 3 - Terceira tentativa:
---
📋 Vamos tentar de outra forma.

Por favor, escolha exatamente o que precisa:

[Saldo de Férias]
[Solicitar Férias]
[Ver Meu Pedido]
[Sou Gestor - Dashboard]
[Recomeçar Conversa]

Se nenhuma opção atende, por favor descreva em detalhes o que você precisa fazer.
---
```

---

## 📋 Ferramentas Adicionais para Gestores

Adicione estas ferramentas Power Automate para suportar a visão gerencial:

| Nº | Nome | Descrição | Parâmetros |
|----|------|-----------|------------|
| 10 | `ObterDashboardGestor` | Retorna dados consolidados do time | `email_gestor` |
| 11 | `ObterAlertasCriticos` | Lista colaboradores com férias vencendo | `id_time, dias_limite` |
| 12 | `ObterCalendarioVisual` | Retorna dados para calendário visual | `id_time, data_inicio, data_fim` |
| 13 | `GerarRelatorio` | Gera relatório em Excel/PDF | `tipo, formato, email_destino` |
| 14 | `AprovarEmLote` | Aprova múltiplas solicitações | `ids_solicitacoes[]` |
| 15 | `EnviarLembreteColaborador` | Envia lembrete sobre férias vencendo | `email_colaborador, mensagem` |

---

> **Documento atualizado em:** 24/01/2026
> **Versão:** 1.1 - Foco em Visão Gerencial
