# Flow 1: VacationApproval — Build Blueprint

> **License:** Standard (No Premium)  
> **Connectors Used:** SharePoint, Approvals, Office 365 Outlook, Microsoft Teams  
> **Trigger:** When an item is created (SharePoint)  
> **Estimated Build Time:** 30-45 minutes

---

## Overview

This flow handles the full approval lifecycle:
1. Employee submits vacation request → Power Apps creates item in `Solicitacoes_Ferias`
2. Flow triggers automatically on item creation
3. Sends approval request to the manager
4. On approval: updates status, deducts balance, notifies employee
5. On rejection: updates status, notifies employee with reason

---

## Step-by-Step Build Instructions

### Step 0: Create the Flow

1. Go to [make.powerautomate.com](https://make.powerautomate.com)
2. Click **+ Create** → **Automated cloud flow**
3. Name: `GestaoFerias_VacationApproval`
4. Trigger: **When an item is created (SharePoint)**
5. Click **Create**

---

### Step 1: Trigger — When an item is created

| Setting | Value |
|---------|-------|
| **Site Address** | `https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA` |
| **List Name** | `Solicitacoes_Ferias` |

---

### Step 2: Initialize Variables

Add **Initialize variable** actions for clarity:

#### Variable: `varApproverEmail`
| Setting | Value |
|---------|-------|
| Name | `varApproverEmail` |
| Type | String |
| Value | `@{triggerOutputs()?['body/AprovadorEmail']}` |

#### Variable: `varEmployeeEmail`
| Setting | Value |
|---------|-------|
| Name | `varEmployeeEmail` |
| Type | String |
| Value | `@{triggerOutputs()?['body/ColaboradorEmail']}` |

#### Variable: `varRequestId`
| Setting | Value |
|---------|-------|
| Name | `varRequestId` |
| Type | Integer |
| Value | `@{triggerOutputs()?['body/ID']}` |

---

### Step 3: Get Employee Details

Add **Get items** (SharePoint):

| Setting | Value |
|---------|-------|
| Site Address | _(same as trigger)_ |
| List Name | `Colaboradores_Aprovadores` |
| Filter Query | `Email eq '@{variables('varEmployeeEmail')}'` |
| Top Count | `1` |

> **Rename** this action to `GetEmployeeDetails`

---

### Step 4: Condition — Check if Status is PENDING

Add **Condition**:

| Setting | Value |
|---------|-------|
| Left | `@{triggerOutputs()?['body/Status']}` |
| Operator | `is equal to` |
| Right | `PENDING` |

> Only proceed if status is PENDING (prevents re-triggering on updates)

**If No → Terminate** (Status: Succeeded, no action needed)

---

### Step 5 (If Yes): Start and Wait for an Approval

Inside the **If Yes** branch, add **Start and wait for an approval**:

| Setting | Value |
|---------|-------|
| **Approval Type** | `Approve/Reject - First to respond` |
| **Title** | `Solicitação de Férias - @{first(outputs('GetEmployeeDetails')?['body/value'])?['NomeCompleto']}` |
| **Assigned To** | `@{variables('varApproverEmail')}` |
| **Details** | _(see below)_ |
| **Item Link** | `https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA/Lists/Solicitacoes_Ferias/DispForm.aspx?ID=@{variables('varRequestId')}` |
| **Item Link Description** | `Ver solicitação no SharePoint` |

#### Details field (HTML):

```html
<b>Colaborador:</b> @{first(outputs('GetEmployeeDetails')?['body/value'])?['NomeCompleto']}<br>
<b>Período:</b> @{formatDateTime(triggerOutputs()?['body/DataInicio'], 'dd/MM/yyyy')} a @{formatDateTime(triggerOutputs()?['body/DataFim'], 'dd/MM/yyyy')}<br>
<b>Total de dias:</b> @{triggerOutputs()?['body/DiasUteis']}<br>
<b>Conflito com equipe:</b> @{if(triggerOutputs()?['body/TemConflito'], 'SIM ⚠️', 'Não')}<br>
<b>Observações:</b> @{triggerOutputs()?['body/Observacoes']}
```

> **Rename** this action to `ApprovalAction`

---

### Step 6: Condition — Approval Outcome

Add **Condition** after the approval:

| Setting | Value |
|---------|-------|
| Left | `@{outputs('ApprovalAction')?['body/outcome']}` |
| Operator | `is equal to` |
| Right | `Approve` |

---

### Step 7A (If Approved): Update SharePoint + Balance + Notify

#### 7A.1 — Update Request Status → APPROVED

Add **Update item** (SharePoint):

| Setting | Value |
|---------|-------|
| Site Address | _(same)_ |
| List Name | `Solicitacoes_Ferias` |
| Id | `@{variables('varRequestId')}` |
| Status Value | `APPROVED` |
| DataAprovacao | `@{utcNow()}` |

#### 7A.2 — Get Current Balance

Add **Get items** (SharePoint):

| Setting | Value |
|---------|-------|
| List Name | `Saldo_Ferias` |
| Filter Query | `ColaboradorEmail eq '@{variables('varEmployeeEmail')}'` |
| Top Count | `1` |

> **Rename** to `GetCurrentBalance`

#### 7A.3 — Update Balance (Deduct Days)

Add **Update item** (SharePoint):

| Setting | Value |
|---------|-------|
| List Name | `Saldo_Ferias` |
| Id | `@{first(outputs('GetCurrentBalance')?['body/value'])?['ID']}` |
| SaldoDisponivel | `@{sub(first(outputs('GetCurrentBalance')?['body/value'])?['SaldoDisponivel'], triggerOutputs()?['body/DiasUteis'])}` |
| DiasAgendados | `@{add(first(outputs('GetCurrentBalance')?['body/value'])?['DiasAgendados'], triggerOutputs()?['body/DiasUteis'])}` |
| DataAtualizacao | `@{utcNow()}` |

#### 7A.4 — Notify Employee (Teams)

Add **Post message in a chat or channel** (Microsoft Teams):

| Setting | Value |
|---------|-------|
| Post As | `Flow bot` |
| Post In | `Chat with Flow bot` |
| Recipient | `@{variables('varEmployeeEmail')}` |
| Message | _(see below)_ |

```
✅ Suas férias foram APROVADAS!

📅 Período: @{formatDateTime(triggerOutputs()?['body/DataInicio'], 'dd/MM/yyyy')} a @{formatDateTime(triggerOutputs()?['body/DataFim'], 'dd/MM/yyyy')}
📊 Total: @{triggerOutputs()?['body/DiasUteis']} dias

Aprovado por: @{variables('varApproverEmail')}
```

#### 7A.5 — Notify Employee (Email)

Add **Send an email (V2)** (Office 365 Outlook):

| Setting | Value |
|---------|-------|
| To | `@{variables('varEmployeeEmail')}` |
| Subject | `✅ Férias Aprovadas - @{formatDateTime(triggerOutputs()?['body/DataInicio'], 'dd/MM/yyyy')} a @{formatDateTime(triggerOutputs()?['body/DataFim'], 'dd/MM/yyyy')}` |
| Body | Same content as Teams message, with HTML formatting |

---

### Step 7B (If Rejected): Update Status + Notify

#### 7B.1 — Update Request Status → REJECTED

Add **Update item** (SharePoint):

| Setting | Value |
|---------|-------|
| List Name | `Solicitacoes_Ferias` |
| Id | `@{variables('varRequestId')}` |
| Status Value | `REJECTED` |
| Data_Aprovacao | `@{utcNow()}` |

#### 7B.2 — Notify Employee (Teams)

```
❌ Sua solicitação de férias foi REJEITADA.

📅 Período solicitado: @{formatDateTime(triggerOutputs()?['body/DataInicio'], 'dd/MM/yyyy')} a @{formatDateTime(triggerOutputs()?['body/DataFim'], 'dd/MM/yyyy')}

💬 Motivo: @{outputs('ApprovalAction')?['body/responses'][0]?['comments']}

Entre em contato com seu gestor para mais informações.
```

#### 7B.3 — Notify Employee (Email)

Same content as Teams, with HTML formatting and subject:
`❌ Férias Rejeitadas - @{formatDateTime(triggerOutputs()?['body/DataInicio'], 'dd/MM/yyyy')} a @{formatDateTime(triggerOutputs()?['body/DataFim'], 'dd/MM/yyyy')}`

---

## Flow Diagram Summary

```
SharePoint: Item Created (Solicitacoes_Ferias)
    │
    ▼
Initialize Variables (Email, RequestID)
    │
    ▼
Get Employee Details (Colaboradores_Aprovadores)
    │
    ▼
Condition: Status == PENDING?
    │
    ├── No → Terminate
    │
    └── Yes → Start Approval
                  │
                  ▼
              Condition: Approved?
                  │
                  ├── Yes → Update SP (APPROVED)
                  │         → Update Saldo_Ferias (deduct)
                  │         → Notify Teams ✅
                  │         → Notify Email ✅
                  │
                  └── No → Update SP (REJECTED)
                           → Notify Teams ❌
                           → Notify Email ❌
```

---

## Testing Checklist

- [ ] Create a test item in Solicitacoes_Ferias with Status=PENDING
- [ ] Verify approval request appears in Teams Approvals center
- [ ] Approve → verify Status changes to APPROVED
- [ ] Verify Saldo_Ferias balance is deducted
- [ ] Verify Teams chat notification received
- [ ] Verify email notification received
- [ ] Create another test → Reject → verify Status changes to REJECTED
- [ ] Verify rejection reason appears in notification

---

## Common Issues & Fixes

| Issue | Fix |
|-------|-----|
| Flow triggers on every update, not just creation | Must use "When an item is **created**" trigger (not "created or modified") |
| Approval shows raw dates | Use `formatDateTime()` with `'dd/MM/yyyy'` format |
| Balance goes negative | Add a condition before deducting to check if balance >= requested days |
| Error on `first()` expression | Ensure GetEmployeeDetails returns at least 1 item; add error handling |
