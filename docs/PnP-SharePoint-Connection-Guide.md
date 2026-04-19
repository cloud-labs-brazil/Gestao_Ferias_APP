# PnP PowerShell — SharePoint Connection Guide

> **Target Site:** `https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA`  
> **PnP Version:** `SharePointPnPPowerShellOnline 3.29.2101.0` (Legacy v3)  
> **Last Updated:** 2026-04-18

---

## ⚠️ CRITICAL RULES — READ FIRST

### Rule #1: Connection Does NOT Persist Between Commands
The legacy PnP module **drops the connection** between separate `run_command` calls. You **MUST** connect AND execute your SharePoint commands **in the same single command string**.

```powershell
# ❌ WRONG — This WILL FAIL
run_command("Connect-PnPOnline -Url ... -UseWebLogin")
run_command("Get-PnPListItem -List 'MyList'")  # ERROR: no connection

# ✅ CORRECT — Everything in ONE command
run_command("Connect-PnPOnline -Url ... -UseWebLogin; Get-PnPListItem -List 'MyList'")
```

### Rule #2: Use `-UseWebLogin`, NOT `-Interactive`
This is the **legacy** module. The `-Interactive` parameter does NOT exist.

```powershell
# ❌ WRONG — parameter does not exist in this version
Connect-PnPOnline -Url "..." -Interactive

# ✅ CORRECT
Connect-PnPOnline -Url "..." -UseWebLogin
```

### Rule #3: Suppress the Legacy Warning
Add this at the start to avoid noisy output:

```powershell
$env:PNPLEGACYMESSAGE='false'
```

---

## 🔌 Connection Template (Copy-Paste Ready)

Use this as your **starting boilerplate** for every SharePoint command:

```powershell
$env:PNPLEGACYMESSAGE='false'; Connect-PnPOnline -Url "https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA" -UseWebLogin -WarningAction Ignore; <YOUR COMMANDS HERE>
```

**Example — Read items from a list:**
```powershell
$env:PNPLEGACYMESSAGE='false'; Connect-PnPOnline -Url "https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA" -UseWebLogin -WarningAction Ignore; Get-PnPListItem -List "Colaboradores_Aprovadores" | ForEach-Object { Write-Host "ID=$($_.Id) | $($_.FieldValues.NomeCompleto) | $($_.FieldValues.Email)" }
```

---

## 📋 SharePoint Lists Available

| # | List Name | Purpose |
|---|-----------|---------|
| 1 | `Colaboradores_Aprovadores` | Employee/Manager mapping |
| 2 | `Solicitacoes_Ferias` | Vacation requests |
| 3 | `Historico_Ferias` | Historical vacations |
| 4 | `Saldo_Ferias` | Balance per employee per year |
| 5 | `Feriados` | Company holidays |
| 6 | `Alertas_Ferias` | Proactive alerts |

---

## 🔍 Common Operations

### 1. List All Items in a List
```powershell
$env:PNPLEGACYMESSAGE='false'; Connect-PnPOnline -Url "https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA" -UseWebLogin -WarningAction Ignore; Get-PnPListItem -List "Colaboradores_Aprovadores" | ForEach-Object { $_.FieldValues | Format-List }
```

### 2. Get Field Names of a List (IMPORTANT — do this first!)
Column internal names in SharePoint often differ from display names. **Always check field names before reading/writing data.**

```powershell
$env:PNPLEGACYMESSAGE='false'; Connect-PnPOnline -Url "https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA" -UseWebLogin -WarningAction Ignore; Get-PnPField -List "Colaboradores_Aprovadores" | Select-Object InternalName, Title, TypeAsString | Format-Table -AutoSize
```

### 3. Read Items with Specific Fields
```powershell
$env:PNPLEGACYMESSAGE='false'; Connect-PnPOnline -Url "https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA" -UseWebLogin -WarningAction Ignore; Get-PnPListItem -List "Saldo_Ferias" | ForEach-Object { Write-Host "ID=$($_.Id) | $($_.FieldValues.ColaboradorEmail) | Saldo=$($_.FieldValues.SaldoTotal) | Disponivel=$($_.FieldValues.SaldoDisponivel)" }
```

### 4. Filter Items
```powershell
$env:PNPLEGACYMESSAGE='false'; Connect-PnPOnline -Url "https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA" -UseWebLogin -WarningAction Ignore; Get-PnPListItem -List "Colaboradores_Aprovadores" | Where-Object { $_.FieldValues.Email -eq "htorresg@minsait.com" } | ForEach-Object { $_.FieldValues | Format-List }
```

### 5. Create a New Item

> ⚠️ **IMPORTANT:** Always include the `Title` field! The Power Automate trigger **will fail** without it. Use format: `"Ferias - <Employee Name>"`.

```powershell
$env:PNPLEGACYMESSAGE='false'; Connect-PnPOnline -Url "https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA" -UseWebLogin -WarningAction Ignore; Add-PnPListItem -List "Solicitacoes_Ferias" -Values @{ "Title" = "Ferias - Hercilio Torres Goncalves"; "ColaboradorEmail" = "htorresg@minsait.com"; "ColaboradorNome" = "Hercilio Torres Goncalves"; "DataInicio" = "2026-06-17"; "DataFim" = "2026-06-27"; "DiasUteis" = 10; "Status" = "PENDING"; "AprovadorEmail" = "mbenicios@minsait.com"; "AprovadorNome" = "Manoel Benicio De Souza Neto"; "Observacoes" = "Test item"; "Tipo" = "NEW" }
```

### 6. Update an Existing Item
```powershell
$env:PNPLEGACYMESSAGE='false'; Connect-PnPOnline -Url "https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA" -UseWebLogin -WarningAction Ignore; Set-PnPListItem -List "Solicitacoes_Ferias" -Identity 11 -Values @{ "Status" = "APPROVED" }
```

### 7. Delete an Item
```powershell
$env:PNPLEGACYMESSAGE='false'; Connect-PnPOnline -Url "https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA" -UseWebLogin -WarningAction Ignore; Remove-PnPListItem -List "Solicitacoes_Ferias" -Identity 11 -Force
```

### 8. Get a Single Item by ID
```powershell
$env:PNPLEGACYMESSAGE='false'; Connect-PnPOnline -Url "https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA" -UseWebLogin -WarningAction Ignore; $item = Get-PnPListItem -List "Solicitacoes_Ferias" -Id 9; $item.FieldValues | Format-List
```

---

## 📊 Actual Field Names per List

> ⚠️ These are the **InternalName** values you must use in code. Display names may differ.

### Colaboradores_Aprovadores
| InternalName | Type | Description |
|---|---|---|
| `Email` | Text | Employee email |
| `NomeCompleto` | Text | Full name |
| `Departamento` | Text | Department |
| `Cargo` | Text | Job title |
| `AprovadorEmail` | Text | Approver email |
| `AprovadorNome` | Text | Approver name |
| `DataAdmissao` | DateTime | Hire date |
| `Ativo` | Boolean | Is active |
| `Gestor_Nome` | Text | Manager name |
| `Gestor_Email` | Text | Manager email |
| `Diretor_Nome` | Text | Director name |
| `Diretor_Email` | Text | Director email |
| `EhGestor` | Boolean | Is manager |

### Solicitacoes_Ferias
| InternalName | Type | Description |
|---|---|---|
| `ColaboradorEmail` | Text | Employee email |
| `ColaboradorNome` | Text | Employee name |
| `DataInicio` | DateTime | Start date |
| `DataFim` | DateTime | End date |
| `DiasUteis` | Number | Business days |
| `Status` | Text | PENDING/APPROVED/REJECTED/CANCELLED |
| `AprovadorEmail` | Text | Approver email |
| `AprovadorNome` | Text | Approver name |
| `DataAprovacao` | DateTime | Approval date |
| `Observacoes` | Note | Notes |
| `CriadoPorBot` | Boolean | Created by bot |
| `Tipo` | Text | NEW/CHANGE/CANCEL |
| `DataEscalacao` | DateTime | Escalation date |

### Saldo_Ferias
| InternalName | Type | Description |
|---|---|---|
| `ColaboradorEmail` | Text | Employee email |
| `AnoReferencia` | Number | Reference year |
| `SaldoTotal` | Number | Total days entitled |
| `DiasUsados` | Number | Days already used |
| `DiasAgendados` | Number | Days scheduled/pending |
| `SaldoDisponivel` | Number | Available balance |
| `DataAtualizacao` | DateTime | Last update timestamp |

### Feriados
| InternalName | Type | Description |
|---|---|---|
| `Data` | DateTime | Holiday date |
| `Nome` | Text | Holiday name |
| `Tipo` | Text | NATIONAL/STATE/COMPANY |

---

## 🚨 Troubleshooting

### Error: "parameter name 'Interactive'"
**Cause:** Using `-Interactive` which doesn't exist in the legacy module.  
**Fix:** Use `-UseWebLogin` instead.

### Error: "There is currently no connection yet"
**Cause:** Connection was in a previous command that already finished.  
**Fix:** Put `Connect-PnPOnline` and your command in the **same command string**, separated by `;`.

### Error: "Field XYZ not present in list"
**Cause:** Using wrong field name (display name vs internal name).  
**Fix:** Run `Get-PnPField -List "ListName"` first to get the correct `InternalName`.

### Warning: "You are running the legacy version of PnP PowerShell"
**Cause:** Normal — we use legacy v3.  
**Fix:** Add `$env:PNPLEGACYMESSAGE='false'` at the start, or add `-WarningAction Ignore` to the connect call.

### Error: Boolean field fails
**Cause:** Boolean fields in SharePoint can be tricky with PowerShell.  
**Fix:** Use string `"true"` or `"false"` instead of `$true`/`$false`, or use `1`/`0`.

---

## 📝 Quick Reference Card

```
MODULE:     SharePointPnPPowerShellOnline v3.29.2101.0 (Legacy)
SITE URL:   https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA
AUTH:       -UseWebLogin (browser-based SSO)
PATTERN:    $env:PNPLEGACYMESSAGE='false'; Connect-PnPOnline -Url "<URL>" -UseWebLogin -WarningAction Ignore; <COMMANDS>
KEY RULE:   EVERYTHING must be in ONE run_command call — connection dies between calls!
```
