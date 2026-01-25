# Guia Completo: Configuração PnP CLI e Power Platform APIs

> **Data:** 2026-01-25  
> **Ambiente:** Windows 11  
> **Autor:** Configuração automatizada via Gemini Assistant

---

## Sumário

1. [Pré-requisitos e Versões](#1-pré-requisitos-e-versões)
2. [Instalação de Módulos](#2-instalação-de-módulos)
3. [Autenticação Azure CLI](#3-autenticação-azure-cli)
4. [Criação do App Registration](#4-criação-do-app-registration)
5. [Configuração de Permissões](#5-configuração-de-permissões)
6. [Admin Consent](#6-admin-consent)
7. [Autenticação PAC CLI](#7-autenticação-pac-cli)
8. [Uso do PnP PowerShell](#8-uso-do-pnp-powershell)
9. [Troubleshooting](#9-troubleshooting)
10. [Referência Rápida](#10-referência-rápida)

---wh

## 1. Pré-requisitos e Versões

### Versões Exatas Utilizadas

| Ferramenta | Versão | Comando de Verificação |
|------------|--------|------------------------|
| Azure CLI | **2.81.0** | `az --version` |
| PAC CLI (Power Platform CLI) | **1.51.1** | `pac --version` |
| Microsoft.Graph PowerShell | **2.34.0** | `Get-Module -ListAvailable Microsoft.Graph` |
| PnP.PowerShell | **2.x** | `Get-Module -ListAvailable PnP.PowerShell` |
| PowerShell | **7.x** ou **5.1** | `$PSVersionTable.PSVersion` |
| .NET Framework | **4.8.9310.0** | Verificado via PAC CLI |

### Contas Necessárias

| Conta | Uso | Tenant |
|-------|-----|--------|
| `dataops.cloud.mbf@outlook.com` | Admin do Azure/M365 | `dataopscloudmbfoutlook.onmicrosoft.com` |

### IDs Importantes (Fixos da Microsoft)

| API | App ID |
|-----|--------|
| Power Platform API | `8578e004-a5c6-46e7-913e-12f58912df43` |
| Microsoft Graph | `00000003-0000-0000-c000-000000000000` |
| SharePoint Online | `00000003-0000-0ff1-ce00-000000000000` |

---

## 2. Instalação de Módulos

### 2.1 Instalar Azure CLI

```powershell
# Via winget (recomendado)
winget install -e --id Microsoft.AzureCLI

# Verificar instalação
az --version
```

**Output esperado:**

```
azure-cli                         2.81.0
```

### 2.2 Instalar PAC CLI (Power Platform CLI)

```powershell
# Via winget
winget install -e --id Microsoft.PowerAppsCLI

# OU via dotnet tool
dotnet tool install --global Microsoft.PowerApps.CLI.Tool

# Verificar instalação
pac --version
```

**Output esperado:**

```
Microsoft PowerPlatform CLI
Version: 1.51.1+gbfaffaa (.NET Framework 4.8.9310.0)
```

### 2.3 Instalar Módulos PowerShell

```powershell
# Instalar Microsoft.Graph (necessário para gerenciar App Registrations)
Install-Module -Name Microsoft.Graph -Scope CurrentUser -Force -AllowClobber

# Instalar PnP.PowerShell
Install-Module -Name PnP.PowerShell -Scope CurrentUser -Force -AllowClobber

# Verificar instalação
Get-Module -ListAvailable Microsoft.Graph, PnP.PowerShell | Select-Object Name, Version
```

> **NOTA:** O módulo Microsoft.Graph é grande (~200MB) e pode demorar alguns minutos para instalar.

---

## 3. Autenticação Azure CLI

### 3.1 Login com Device Code (Recomendado)

```powershell
az login --use-device-code
```

**Processo:**

1. O comando exibirá uma URL e um código
2. Abra o navegador em: `https://microsoft.com/devicelogin`
3. Digite o código exibido (ex: `E7TGTEECB`)
4. Faça login com a conta: `dataops.cloud.mbf@outlook.com`
5. Aceite as permissões solicitadas

**Output de sucesso:**

```json
[
  {
    "cloudName": "AzureCloud",
    "homeTenantId": "65270d54-9cdc-40bb-8267-dfd14caf3eaf",
    "id": "20966809-c217-4777-aed9-c37309a1566a",
    "isDefault": true,
    "tenantDefaultDomain": "dataopscloudmbfoutlook.onmicrosoft.com",
    "tenantDisplayName": "Default Directory",
    "tenantId": "65270d54-9cdc-40bb-8267-dfd14caf3eaf",
    "user": {
      "name": "dataops.cloud.mbf@outlook.com",
      "type": "user"
    }
  }
]
```

### 3.2 Verificar Conexão

```powershell
az account show
```

---

## 4. Criação do App Registration

### 4.1 Criar o App Registration

```powershell
az ad app create `
  --display-name "PnP-PowerShell-PowerPlatform" `
  --public-client-redirect-uris "http://localhost" `
  --sign-in-audience "AzureADMyOrg"
```

**Output de sucesso (valores importantes):**

```json
{
  "appId": "92279e53-58df-45d5-b4b7-1808d53ddfaa",
  "id": "a57acb7b-ccce-49c5-8ff6-a6a52ec8769e",
  "displayName": "PnP-PowerShell-PowerPlatform",
  "publisherDomain": "dataopscloudmbfoutlook.onmicrosoft.com",
  "signInAudience": "AzureADMyOrg"
}
```

> **IMPORTANTE:** Anote o `appId` (Client ID): `92279e53-58df-45d5-b4b7-1808d53ddfaa`

### 4.2 Criar Service Principal para o App

```powershell
az ad sp create --id 92279e53-58df-45d5-b4b7-1808d53ddfaa
```

**Output de sucesso:**

```json
{
  "appId": "92279e53-58df-45d5-b4b7-1808d53ddfaa",
  "displayName": "PnP-PowerShell-PowerPlatform",
  "id": "dc3e03c5-a6d5-4e33-b763-1035abc0242f",
  "servicePrincipalType": "Application"
}
```

---

## 5. Configuração de Permissões

### 5.1 Adicionar Permissão Power Platform API

```powershell
# Adicionar permissão user_impersonation da Power Platform API
az ad app permission add `
  --id 92279e53-58df-45d5-b4b7-1808d53ddfaa `
  --api 8578e004-a5c6-46e7-913e-12f58912df43 `
  --api-permissions 4ae1bf56-f562-4747-b7bc-2fa0f9f3505e=Scope
```

**Explicação dos IDs:**

- `--id`: Client ID do seu App Registration
- `--api`: App ID fixo da Power Platform API
- `--api-permissions`: ID da permissão `user_impersonation` + `=Scope` (delegated)

### 5.2 Adicionar Permissões Microsoft Graph

```powershell
# Adicionar permissões do Microsoft Graph
az ad app permission add `
  --id 92279e53-58df-45d5-b4b7-1808d53ddfaa `
  --api 00000003-0000-0000-c000-000000000000 `
  --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope 14dad69e-099b-42c9-810b-d002981feec1=Scope 7ab1d382-f21e-4acd-a863-ba3e13f7da61=Scope
```

**IDs das Permissões Graph:**

| Permissão | ID |
|-----------|-----|
| User.Read | `e1fe6dd8-ba31-4d61-89e7-88639da4683d` |
| profile | `14dad69e-099b-42c9-810b-d002981feec1` |
| Directory.Read.All | `7ab1d382-f21e-4acd-a863-ba3e13f7da61` |

### 5.3 Verificar Permissões Adicionadas

```powershell
az ad app permission list --id 92279e53-58df-45d5-b4b7-1808d53ddfaa -o table
```

**Output esperado:**

```
ResourceAppId
------------------------------------
00000003-0000-0000-c000-000000000000
8578e004-a5c6-46e7-913e-12f58912df43
```

---

## 6. Admin Consent

### 6.1 Conceder Admin Consent - Power Platform API

```powershell
az ad app permission grant `
  --id 92279e53-58df-45d5-b4b7-1808d53ddfaa `
  --api 8578e004-a5c6-46e7-913e-12f58912df43 `
  --scope user_impersonation
```

**Output de sucesso:**

```json
{
  "clientId": "dc3e03c5-a6d5-4e33-b763-1035abc0242f",
  "consentType": "AllPrincipals",
  "scope": "user_impersonation"
}
```

### 6.2 Conceder Admin Consent - Microsoft Graph

```powershell
az ad app permission grant `
  --id 92279e53-58df-45d5-b4b7-1808d53ddfaa `
  --api 00000003-0000-0000-c000-000000000000 `
  --scope "User.Read profile Directory.Read.All"
```

**Output de sucesso:**

```json
{
  "clientId": "dc3e03c5-a6d5-4e33-b763-1035abc0242f",
  "consentType": "AllPrincipals",
  "scope": "User.Read profile Directory.Read.All"
}
```

---

## 7. Autenticação PAC CLI

### 7.1 Limpar Autenticações Anteriores (Opcional)

```powershell
pac auth clear
```

### 7.2 Criar Profile de Autenticação

```powershell
pac auth create --name "DataOps-PowerPlatform" --deviceCode
```

**Processo:**

1. O comando exibirá URL e código
2. Abra: `https://microsoft.com/devicelogin`
3. Digite o código exibido
4. Faça login com: `dataops.cloud.mbf@outlook.com`

**Output de sucesso:**

```
'dataops.cloud.mbf@outlook.com' authenticated successfully.
Validating connection...
Connected to... Default
Authentication profile created
```

### 7.3 Listar Profiles de Autenticação

```powershell
pac auth list
```

### 7.4 Listar Ambientes Disponíveis

```powershell
pac env list
```

**Output exemplo:**

```
Active Display Name            Environment ID                       Environment URL
       ColOfertasBrasilPro    e2d10003-4d8e-e007-9d63-76d5fe89ef56 https://colofertasbrasilpro.crm4.dynamics.com/
*      Default                7808e005-1489-4374-954b-d3b08f193920 https://orgd32f66fd.crm4.dynamics.com/
```

### 7.5 Selecionar Ambiente

```powershell
pac env select --environment "ColOfertasBrasilPro"
```

---

## 8. Uso do PnP PowerShell

### 8.1 Conectar ao SharePoint com o App Registration

```powershell
# Conexão interativa usando o App Registration criado
Connect-PnPOnline `
  -Url "https://seudominio.sharepoint.com/sites/seusite" `
  -ClientId "92279e53-58df-45d5-b4b7-1808d53ddfaa" `
  -Interactive
```

### 8.2 Verificar Conexão

```powershell
Get-PnPContext
Get-PnPWeb
```

### 8.3 Desconectar

```powershell
Disconnect-PnPOnline
```

---

## 9. Troubleshooting

### Problema: "Register-PnPEntraIDApp não reconhecido"

**Causa:** O módulo PnP.PowerShell não está carregado ou não possui este cmdlet.

**Solução:** Use Azure CLI para criar o App Registration (método documentado acima).

### Problema: "New-MgServicePrincipal - Null Reference Exception"

**Causa:** Parâmetros incorretos ou Service Principal já existe.

**Solução:**

```powershell
# Verificar se já existe
az ad sp list --filter "appId eq '8578e004-a5c6-46e7-913e-12f58912df43'" --query "[].appId"

# Usar formato body parameter
$params = @{ appId = "8578e004-a5c6-46e7-913e-12f58912df43" }
New-MgServicePrincipal -BodyParameter $params
```

### Problema: PAC CLI autentica com conta errada

**Causa:** Windows Web Account Manager (WAM) usa cached credentials.

**Solução:**

```powershell
# Limpar cache
pac auth clear

# Criar novo profile especificando tenant
pac auth create --name "MeuProfile" --tenant "65270d54-9cdc-40bb-8267-dfd14caf3eaf" --deviceCode
```

### Problema: "Specified resourceId was not found"

**Causa:** O Service Principal da API não existe no tenant.

**Solução:**

```powershell
# Criar Service Principal da Power Platform API
az ad sp create --id 8578e004-a5c6-46e7-913e-12f58912df43
```

---

## 10. Referência Rápida

### IDs Criados nesta Configuração

| Item | Valor |
|------|-------|
| **App Name** | `PnP-PowerShell-PowerPlatform` |
| **Client ID (appId)** | `92279e53-58df-45d5-b4b7-1808d53ddfaa` |
| **Object ID** | `a57acb7b-ccce-49c5-8ff6-a6a52ec8769e` |
| **Service Principal ID** | `dc3e03c5-a6d5-4e33-b763-1035abc0242f` |
| **Tenant ID** | `65270d54-9cdc-40bb-8267-dfd14caf3eaf` |
| **Tenant Domain** | `dataopscloudmbfoutlook.onmicrosoft.com` |

### Comandos Essenciais

```powershell
# Verificar versões
az --version
pac --version

# Login Azure
az login --use-device-code

# Login PAC CLI
pac auth create --deviceCode

# Listar ambientes Power Platform
pac env list

# Conectar PnP
Connect-PnPOnline -Url "URL" -ClientId "CLIENT_ID" -Interactive
```

### Arquivo de Configuração

Todas as informações estão salvas em: `config/pnp-app-config.json`

```json
{
  "appName": "PnP-PowerShell-PowerPlatform",
  "clientId": "92279e53-58df-45d5-b4b7-1808d53ddfaa",
  "tenantId": "65270d54-9cdc-40bb-8267-dfd14caf3eaf",
  "permissions": {
    "powerPlatformApi": ["user_impersonation"],
    "microsoftGraph": ["User.Read", "profile", "Directory.Read.All"]
  }
}
```

---

## Histórico de Alterações

| Data | Alteração |
|------|-----------|
| 2026-01-25 | Documento criado com configuração inicial |

---

> **Nota:** Este documento foi gerado automaticamente durante a configuração do ambiente. Mantenha-o atualizado conforme novas configurações forem realizadas.
