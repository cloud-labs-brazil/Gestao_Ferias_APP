# 🚀 GUIA DE IMPLANTAÇÃO - POWER AUTOMATE FLOWS
> **Projeto:** Agente Gestão Férias  
> **Versão:** 1.0  
> **Data:** 2026-01-25

---

## 📋 Pré-requisitos

- [x] Power Automate Premium ou Per User license
- [x] Acesso ao ambiente indra365
- [x] SharePoint lists criadas (6/6)
- [x] Dados importados (32 registros)

---

## 🔧 Flows a Criar

| # | Nome | Arquivo | Prioridade |
|---|------|---------|------------|
| 1 | ConsultarSaldoFerias | `flows/Flow_01_*.json` | P1 |
| 2 | VerificarConflitos | `flows/Flow_02_*.json` | P1 |
| 3 | CriarSolicitacao | `flows/Flow_03_*.json` | P1 |
| 4 | AprovarSolicitacao | `flows/Flow_04_*.json` | P2 |
| 5 | RejeitarSolicitacao | `flows/Flow_05_*.json` | P2 |
| 6 | ConsultarStatusSolicitacao | `flows/Flow_06_*.json` | P2 |
| 7 | CancelarSolicitacao | `flows/Flow_07_*.json` | P3 |
| 8 | ObterDashboardGestor | `flows/Flow_08_*.json` | P3 |
| 9 | ObterAlertasCriticos | `flows/Flow_09_*.json` | P3 |
| 10 | EnviarNotificacaoTeams | `flows/Flow_10_*.json` | P2 |

---

## 📝 Instruções Passo a Passo

### PASSO 1: Acessar Power Automate

1. Acesse: https://make.powerautomate.com
2. Faça login com sua conta indra365
3. Verifique que está no ambiente correto

### PASSO 2: Criar Flow

1. Clique em **+ Create** no menu lateral
2. Selecione **Instant cloud flow**
3. Nome: `ConsultarSaldoFerias` (ou conforme tabela)
4. Trigger: **When a HTTP request is received**
5. Clique **Create**

### PASSO 3: Configurar Trigger HTTP

No painel do trigger, cole o schema JSON da propriedade `schema` do arquivo `.json`:

```json
{
  "type": "object",
  "required": ["email_colaborador"],
  "properties": {
    "email_colaborador": {
      "type": "string",
      "description": "Email corporativo do colaborador"
    }
  }
}
```

### PASSO 4: Adicionar Ações

Siga a sequência de `actions` do arquivo JSON:

**Ação 1: Parse JSON**
- Adicione ação "Parse JSON"
- Content: `@triggerBody()`
- Schema: copie do arquivo

**Ação 2: Get Items (SharePoint)**
- Adicione "Get items" (SharePoint)
- Site: `https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA`
- List: `Saldo_Ferias`
- Filter Query: baseie-se no `$filter` do JSON

**Ação 3: Response**
- Adicione "Response"
- Status Code: 200
- Body: copie do JSON do arquivo

### PASSO 5: Salvar e Publicar

1. Clique **Save** no canto superior direito
2. Copie a **HTTP POST URL** gerada
3. Registre a URL abaixo

---

## 📋 URLs dos Flows (Preencher após deploy)

| Flow | URL HTTP |
|------|----------|
| ConsultarSaldoFerias | `_________` |
| VerificarConflitos | `_________` |
| CriarSolicitacao | `_________` |
| AprovarSolicitacao | `_________` |
| RejeitarSolicitacao | `_________` |
| ConsultarStatusSolicitacao | `_________` |
| CancelarSolicitacao | `_________` |
| ObterDashboardGestor | `_________` |
| ObterAlertasCriticos | `_________` |
| EnviarNotificacaoTeams | `_________` |

---

## 🔗 Conexões Necessárias

Configure estas conexões no Power Automate:

| Conector | Nome Interno | Uso |
|----------|--------------|-----|
| SharePoint | `shared_sharepointonline` | Acessar listas |
| Microsoft Teams | `shared_teams` | Notificações chat |
| Office 365 Outlook | `shared_office365` | Enviar emails |

---

## ✅ Checklist de Validação

Para cada flow criado:

- [ ] Nome correto
- [ ] Trigger HTTP configurado com schema
- [ ] Ações na sequência correta
- [ ] Conexões autenticadas
- [ ] Response com status 200
- [ ] Flow salvo e publicado
- [ ] URL copiada e registrada
- [ ] Teste manual OK

---

## 🧪 Teste Manual

Para testar cada flow, use Postman ou PowerShell:

```powershell
# Exemplo: Testar ConsultarSaldoFerias
$url = "URL_DO_FLOW_AQUI"
$body = @{
    email_colaborador = "colaborador@indra365.com"
} | ConvertTo-Json

Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json"
```

---

## 📌 Próximo Passo

Após criar todos os flows:
1. Configure as **Ferramentas** no Copilot Studio
2. Associe cada ferramenta ao flow correspondente
3. Configure os **Tópicos** do agente

---

> 💡 Consulte os arquivos em `/flows/*.json` para detalhes completos de cada flow
