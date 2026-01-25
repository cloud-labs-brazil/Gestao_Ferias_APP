# 🚀 Deploy Automatizado - Agente Gestão Férias

> **Scripts PowerShell (PnP)** para automação completa do deploy das listas e estruturas SharePoint.

---

## Pré-requisitos

```powershell
# Instalar PnP PowerShell (se não tiver)
Install-Module -Name PnP.PowerShell -Scope CurrentUser -Force

# Verificar versão
Get-Module PnP.PowerShell -ListAvailable
```

---

## 1. Script Principal: Deploy Completo

### Arquivo: `Deploy-GestaoFerias.ps1`

```powershell
<#
.SYNOPSIS
    Deploy automatizado das listas SharePoint para o Agente Gestão Férias.
.DESCRIPTION
    Cria todas as listas, colunas, views e importa dados iniciais.
.PARAMETER SiteUrl
    URL do site SharePoint onde as listas serão criadas.
.PARAMETER ExcelPath
    Caminho do arquivo Excel com colaboradores/aprovadores.
.EXAMPLE
    .\Deploy-GestaoFerias.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/RH" -ExcelPath "D:\VMs\Projetos\Copilot_Studio_Config\Users_Approvers.xlsx"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SiteUrl,
    
    [Parameter(Mandatory=$true)]
    [string]$ExcelPath,
    
    [switch]$Force
)

# Cores para output
$SuccessColor = "Green"
$ErrorColor = "Red"
$WarningColor = "Yellow"
$InfoColor = "Cyan"

function Write-Step {
    param([string]$Message, [string]$Status = "INFO")
    $color = switch($Status) {
        "SUCCESS" { $SuccessColor }
        "ERROR" { $ErrorColor }
        "WARNING" { $WarningColor }
        default { $InfoColor }
    }
    Write-Host "[$Status] $Message" -ForegroundColor $color
}

# ═══════════════════════════════════════════════════════════════════
# CONEXÃO
# ═══════════════════════════════════════════════════════════════════

Write-Step "Conectando ao SharePoint: $SiteUrl"
try {
    Connect-PnPOnline -Url $SiteUrl -Interactive
    Write-Step "Conexão estabelecida com sucesso!" "SUCCESS"
}
catch {
    Write-Step "Erro ao conectar: $_" "ERROR"
    exit 1
}

# ═══════════════════════════════════════════════════════════════════
# LISTA 1: Colaboradores_Aprovadores
# ═══════════════════════════════════════════════════════════════════

Write-Step "Criando lista: Colaboradores_Aprovadores..."

$listName = "Colaboradores_Aprovadores"

# Verificar se lista existe
$existingList = Get-PnPList -Identity $listName -ErrorAction SilentlyContinue

if ($existingList -and -not $Force) {
    Write-Step "Lista '$listName' já existe. Use -Force para recriar." "WARNING"
}
else {
    if ($existingList -and $Force) {
        Write-Step "Removendo lista existente..." "WARNING"
        Remove-PnPList -Identity $listName -Force
    }
    
    # Criar lista
    New-PnPList -Title $listName -Template GenericList -EnableVersioning
    
    # Adicionar colunas
    Add-PnPField -List $listName -DisplayName "Email" -InternalName "Email" -Type Text -Required
    Add-PnPField -List $listName -DisplayName "Departamento" -InternalName "Departamento" -Type Text
    Add-PnPField -List $listName -DisplayName "Cargo" -InternalName "Cargo" -Type Text
    Add-PnPField -List $listName -DisplayName "Gestor_Nome" -InternalName "Gestor_Nome" -Type Text
    Add-PnPField -List $listName -DisplayName "Gestor_Email" -InternalName "Gestor_Email" -Type Text
    Add-PnPField -List $listName -DisplayName "Diretor_Nome" -InternalName "Diretor_Nome" -Type Text
    Add-PnPField -List $listName -DisplayName "Diretor_Email" -InternalName "Diretor_Email" -Type Text
    Add-PnPField -List $listName -DisplayName "Ativo" -InternalName "Ativo" -Type Boolean
    Add-PnPField -List $listName -DisplayName "EhGestor" -InternalName "EhGestor" -Type Boolean
    
    Write-Step "Lista '$listName' criada com sucesso!" "SUCCESS"
}

# ═══════════════════════════════════════════════════════════════════
# LISTA 2: Solicitacoes_Ferias
# ═══════════════════════════════════════════════════════════════════

Write-Step "Criando lista: Solicitacoes_Ferias..."

$listName = "Solicitacoes_Ferias"
$existingList = Get-PnPList -Identity $listName -ErrorAction SilentlyContinue

if ($existingList -and -not $Force) {
    Write-Step "Lista '$listName' já existe. Use -Force para recriar." "WARNING"
}
else {
    if ($existingList -and $Force) {
        Remove-PnPList -Identity $listName -Force
    }
    
    New-PnPList -Title $listName -Template GenericList -EnableVersioning
    
    # Colunas principais
    Add-PnPField -List $listName -DisplayName "Colaborador_Email" -InternalName "Colaborador_Email" -Type Text -Required
    Add-PnPField -List $listName -DisplayName "Colaborador_Nome" -InternalName "Colaborador_Nome" -Type Text
    Add-PnPField -List $listName -DisplayName "DataInicio" -InternalName "DataInicio" -Type DateTime -Required
    Add-PnPField -List $listName -DisplayName "DataFim" -InternalName "DataFim" -Type DateTime -Required
    Add-PnPField -List $listName -DisplayName "TotalDias" -InternalName "TotalDias" -Type Number
    
    # Status com choices
    $statusXml = @"
<Field Type="Choice" DisplayName="Status" Required="TRUE" Format="Dropdown" FillInChoice="FALSE">
    <Default>Pendente</Default>
    <CHOICES>
        <CHOICE>Pendente</CHOICE>
        <CHOICE>Aprovado</CHOICE>
        <CHOICE>Rejeitado</CHOICE>
        <CHOICE>Devolvido</CHOICE>
        <CHOICE>Cancelado</CHOICE>
    </CHOICES>
</Field>
"@
    Add-PnPFieldFromXml -List $listName -FieldXml $statusXml
    
    # Colunas de aprovação
    Add-PnPField -List $listName -DisplayName "Aprovador_Email" -InternalName "Aprovador_Email" -Type Text
    Add-PnPField -List $listName -DisplayName "Aprovador_Nome" -InternalName "Aprovador_Nome" -Type Text
    Add-PnPField -List $listName -DisplayName "DataAprovacao" -InternalName "DataAprovacao" -Type DateTime
    Add-PnPField -List $listName -DisplayName "Observacao_Colaborador" -InternalName "Observacao_Colaborador" -Type Note
    Add-PnPField -List $listName -DisplayName "Observacao_Aprovador" -InternalName "Observacao_Aprovador" -Type Note
    
    # Colunas de conflito
    Add-PnPField -List $listName -DisplayName "TemConflito" -InternalName "TemConflito" -Type Boolean
    Add-PnPField -List $listName -DisplayName "ColaboradoresConflito" -InternalName "ColaboradoresConflito" -Type Note
    
    # Timestamps
    Add-PnPField -List $listName -DisplayName "DataSolicitacao" -InternalName "DataSolicitacao" -Type DateTime
    
    Write-Step "Lista '$listName' criada com sucesso!" "SUCCESS"
}

# ═══════════════════════════════════════════════════════════════════
# LISTA 3: Historico_Ferias
# ═══════════════════════════════════════════════════════════════════

Write-Step "Criando lista: Historico_Ferias..."

$listName = "Historico_Ferias"
$existingList = Get-PnPList -Identity $listName -ErrorAction SilentlyContinue

if ($existingList -and -not $Force) {
    Write-Step "Lista '$listName' já existe. Use -Force para recriar." "WARNING"
}
else {
    if ($existingList -and $Force) {
        Remove-PnPList -Identity $listName -Force
    }
    
    New-PnPList -Title $listName -Template GenericList -EnableVersioning
    
    Add-PnPField -List $listName -DisplayName "Colaborador_Email" -InternalName "Colaborador_Email" -Type Text -Required
    Add-PnPField -List $listName -DisplayName "Colaborador_Nome" -InternalName "Colaborador_Nome" -Type Text
    Add-PnPField -List $listName -DisplayName "Departamento" -InternalName "Departamento" -Type Text
    Add-PnPField -List $listName -DisplayName "DataInicio" -InternalName "DataInicio" -Type DateTime -Required
    Add-PnPField -List $listName -DisplayName "DataFim" -InternalName "DataFim" -Type DateTime -Required
    Add-PnPField -List $listName -DisplayName "TotalDias" -InternalName "TotalDias" -Type Number
    Add-PnPField -List $listName -DisplayName "Ano" -InternalName "Ano" -Type Number
    Add-PnPField -List $listName -DisplayName "PeriodoAquisitivo" -InternalName "PeriodoAquisitivo" -Type Text
    
    $statusXml = @"
<Field Type="Choice" DisplayName="Status" Required="TRUE" Format="Dropdown">
    <Default>Aprovado</Default>
    <CHOICES>
        <CHOICE>Aprovado</CHOICE>
        <CHOICE>Cancelado</CHOICE>
        <CHOICE>Gozado</CHOICE>
    </CHOICES>
</Field>
"@
    Add-PnPFieldFromXml -List $listName -FieldXml $statusXml
    
    Write-Step "Lista '$listName' criada com sucesso!" "SUCCESS"
}

# ═══════════════════════════════════════════════════════════════════
# LISTA 4: Saldo_Ferias
# ═══════════════════════════════════════════════════════════════════

Write-Step "Criando lista: Saldo_Ferias..."

$listName = "Saldo_Ferias"
$existingList = Get-PnPList -Identity $listName -ErrorAction SilentlyContinue

if ($existingList -and -not $Force) {
    Write-Step "Lista '$listName' já existe. Use -Force para recriar." "WARNING"
}
else {
    if ($existingList -and $Force) {
        Remove-PnPList -Identity $listName -Force
    }
    
    New-PnPList -Title $listName -Template GenericList -EnableVersioning
    
    Add-PnPField -List $listName -DisplayName "Colaborador_Email" -InternalName "Colaborador_Email" -Type Text -Required
    Add-PnPField -List $listName -DisplayName "Colaborador_Nome" -InternalName "Colaborador_Nome" -Type Text
    Add-PnPField -List $listName -DisplayName "PeriodoAquisitivo" -InternalName "PeriodoAquisitivo" -Type Text
    Add-PnPField -List $listName -DisplayName "DataInicioAquisicao" -InternalName "DataInicioAquisicao" -Type DateTime
    Add-PnPField -List $listName -DisplayName "DataFimAquisicao" -InternalName "DataFimAquisicao" -Type DateTime
    Add-PnPField -List $listName -DisplayName "DataVencimento" -InternalName "DataVencimento" -Type DateTime -Required
    Add-PnPField -List $listName -DisplayName "DiasTotal" -InternalName "DiasTotal" -Type Number
    Add-PnPField -List $listName -DisplayName "DiasGozados" -InternalName "DiasGozados" -Type Number
    Add-PnPField -List $listName -DisplayName "DiasVendidos" -InternalName "DiasVendidos" -Type Number
    Add-PnPField -List $listName -DisplayName "SaldoDisponivel" -InternalName "SaldoDisponivel" -Type Number
    
    Write-Step "Lista '$listName' criada com sucesso!" "SUCCESS"
}

# ═══════════════════════════════════════════════════════════════════
# LISTA 5: Feriados
# ═══════════════════════════════════════════════════════════════════

Write-Step "Criando lista: Feriados..."

$listName = "Feriados"
$existingList = Get-PnPList -Identity $listName -ErrorAction SilentlyContinue

if ($existingList -and -not $Force) {
    Write-Step "Lista '$listName' já existe. Use -Force para recriar." "WARNING"
}
else {
    if ($existingList -and $Force) {
        Remove-PnPList -Identity $listName -Force
    }
    
    New-PnPList -Title $listName -Template GenericList
    
    Add-PnPField -List $listName -DisplayName "Data" -InternalName "Data" -Type DateTime -Required
    Add-PnPField -List $listName -DisplayName "Ano" -InternalName "Ano" -Type Number
    
    $tipoXml = @"
<Field Type="Choice" DisplayName="Tipo" Format="Dropdown">
    <CHOICES>
        <CHOICE>Nacional</CHOICE>
        <CHOICE>Estadual</CHOICE>
        <CHOICE>Municipal</CHOICE>
        <CHOICE>Ponte</CHOICE>
    </CHOICES>
</Field>
"@
    Add-PnPFieldFromXml -List $listName -FieldXml $tipoXml
    
    Write-Step "Lista '$listName' criada com sucesso!" "SUCCESS"
}

# ═══════════════════════════════════════════════════════════════════
# LISTA 6: Alertas_Ferias (para notificações proativas)
# ═══════════════════════════════════════════════════════════════════

Write-Step "Criando lista: Alertas_Ferias..."

$listName = "Alertas_Ferias"
$existingList = Get-PnPList -Identity $listName -ErrorAction SilentlyContinue

if ($existingList -and -not $Force) {
    Write-Step "Lista '$listName' já existe. Use -Force para recriar." "WARNING"
}
else {
    if ($existingList -and $Force) {
        Remove-PnPList -Identity $listName -Force
    }
    
    New-PnPList -Title $listName -Template GenericList
    
    $tipoAlertaXml = @"
<Field Type="Choice" DisplayName="TipoAlerta" Required="TRUE" Format="Dropdown">
    <CHOICES>
        <CHOICE>FeriasVencendo</CHOICE>
        <CHOICE>DuasFeriasVencendo</CHOICE>
        <CHOICE>SolicitacaoPendente</CHOICE>
        <CHOICE>ConflitoDatas</CHOICE>
        <CHOICE>LembreteFerias</CHOICE>
    </CHOICES>
</Field>
"@
    Add-PnPFieldFromXml -List $listName -FieldXml $tipoAlertaXml
    
    Add-PnPField -List $listName -DisplayName "Destinatario_Email" -InternalName "Destinatario_Email" -Type Text -Required
    Add-PnPField -List $listName -DisplayName "Colaborador_Referencia" -InternalName "Colaborador_Referencia" -Type Text
    Add-PnPField -List $listName -DisplayName "Mensagem" -InternalName "Mensagem" -Type Note
    Add-PnPField -List $listName -DisplayName "DataAlerta" -InternalName "DataAlerta" -Type DateTime
    Add-PnPField -List $listName -DisplayName "Enviado" -InternalName "Enviado" -Type Boolean
    Add-PnPField -List $listName -DisplayName "DataEnvio" -InternalName "DataEnvio" -Type DateTime
    
    Write-Step "Lista '$listName' criada com sucesso!" "SUCCESS"
}

# ═══════════════════════════════════════════════════════════════════
# IMPORTAR DADOS DO EXCEL
# ═══════════════════════════════════════════════════════════════════

if (Test-Path $ExcelPath) {
    Write-Step "Importando dados do Excel: $ExcelPath"
    
    # Importar módulo ImportExcel se disponível
    if (Get-Module -ListAvailable -Name ImportExcel) {
        $excelData = Import-Excel -Path $ExcelPath
        
        foreach ($row in $excelData) {
            $itemValues = @{
                "Title" = $row.Nome
                "Email" = $row.Email
                "Departamento" = $row.Departamento
                "Cargo" = $row.Cargo
                "Gestor_Nome" = $row.Gestor_Nome
                "Gestor_Email" = $row.Gestor_Email
                "Diretor_Nome" = $row.Diretor_Nome
                "Diretor_Email" = $row.Diretor_Email
                "Ativo" = $true
                "EhGestor" = ($row.EhGestor -eq "Sim" -or $row.EhGestor -eq $true)
            }
            
            Add-PnPListItem -List "Colaboradores_Aprovadores" -Values $itemValues
        }
        
        Write-Step "Dados importados com sucesso! Total: $($excelData.Count) registros" "SUCCESS"
    }
    else {
        Write-Step "Módulo ImportExcel não encontrado. Instale com: Install-Module ImportExcel" "WARNING"
        Write-Step "Dados não foram importados automaticamente." "WARNING"
    }
}
else {
    Write-Step "Arquivo Excel não encontrado: $ExcelPath" "WARNING"
}

# ═══════════════════════════════════════════════════════════════════
# CRIAR VIEWS
# ═══════════════════════════════════════════════════════════════════

Write-Step "Criando views personalizadas..."

# View: Solicitações Pendentes
Add-PnPView -List "Solicitacoes_Ferias" -Title "Pendentes de Aprovação" -Fields "Colaborador_Nome","DataInicio","DataFim","TotalDias","TemConflito","DataSolicitacao" -Query "<Where><Eq><FieldRef Name='Status'/><Value Type='Choice'>Pendente</Value></Eq></Where><OrderBy><FieldRef Name='DataSolicitacao' Ascending='TRUE'/></OrderBy>"

# View: Férias Aprovadas (próximos 90 dias)
Add-PnPView -List "Solicitacoes_Ferias" -Title "Aprovadas - Próximos 90 dias" -Fields "Colaborador_Nome","DataInicio","DataFim","TotalDias" -Query "<Where><And><Eq><FieldRef Name='Status'/><Value Type='Choice'>Aprovado</Value></Eq><Geq><FieldRef Name='DataInicio'/><Value Type='DateTime'><Today/></Value></Geq></And></Where><OrderBy><FieldRef Name='DataInicio' Ascending='TRUE'/></OrderBy>"

# View: Saldos Críticos (vencendo em 60 dias)
Add-PnPView -List "Saldo_Ferias" -Title "Vencendo em 60 dias" -Fields "Colaborador_Nome","SaldoDisponivel","DataVencimento","PeriodoAquisitivo" -Query "<Where><And><Gt><FieldRef Name='SaldoDisponivel'/><Value Type='Number'>0</Value></Gt><Leq><FieldRef Name='DataVencimento'/><Value Type='DateTime'><Today OffsetDays='60'/></Value></Leq></And></Where><OrderBy><FieldRef Name='DataVencimento' Ascending='TRUE'/></OrderBy>"

Write-Step "Views criadas com sucesso!" "SUCCESS"

# ═══════════════════════════════════════════════════════════════════
# POPULAR FERIADOS 2026
# ═══════════════════════════════════════════════════════════════════

Write-Step "Adicionando feriados de 2026..."

$feriados2026 = @(
    @{ Title = "Confraternização Universal"; Data = "2026-01-01"; Tipo = "Nacional" },
    @{ Title = "Carnaval"; Data = "2026-02-16"; Tipo = "Nacional" },
    @{ Title = "Carnaval"; Data = "2026-02-17"; Tipo = "Nacional" },
    @{ Title = "Quarta-feira de Cinzas"; Data = "2026-02-18"; Tipo = "Nacional" },
    @{ Title = "Sexta-feira Santa"; Data = "2026-04-03"; Tipo = "Nacional" },
    @{ Title = "Tiradentes"; Data = "2026-04-21"; Tipo = "Nacional" },
    @{ Title = "Dia do Trabalho"; Data = "2026-05-01"; Tipo = "Nacional" },
    @{ Title = "Corpus Christi"; Data = "2026-06-04"; Tipo = "Nacional" },
    @{ Title = "Independência do Brasil"; Data = "2026-09-07"; Tipo = "Nacional" },
    @{ Title = "Nossa Senhora Aparecida"; Data = "2026-10-12"; Tipo = "Nacional" },
    @{ Title = "Finados"; Data = "2026-11-02"; Tipo = "Nacional" },
    @{ Title = "Proclamação da República"; Data = "2026-11-15"; Tipo = "Nacional" },
    @{ Title = "Natal"; Data = "2026-12-25"; Tipo = "Nacional" }
)

foreach ($feriado in $feriados2026) {
    Add-PnPListItem -List "Feriados" -Values @{
        Title = $feriado.Title
        Data = $feriado.Data
        Ano = 2026
        Tipo = $feriado.Tipo
    }
}

Write-Step "Feriados adicionados com sucesso!" "SUCCESS"

# ═══════════════════════════════════════════════════════════════════
# RESUMO FINAL
# ═══════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "           DEPLOY CONCLUÍDO COM SUCESSO!                    " -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Listas criadas:" -ForegroundColor Cyan
Write-Host "  ✅ Colaboradores_Aprovadores"
Write-Host "  ✅ Solicitacoes_Ferias"
Write-Host "  ✅ Historico_Ferias"
Write-Host "  ✅ Saldo_Ferias"
Write-Host "  ✅ Feriados"
Write-Host "  ✅ Alertas_Ferias"
Write-Host ""
Write-Host "Próximos passos:" -ForegroundColor Yellow
Write-Host "  1. Verifique as listas no SharePoint"
Write-Host "  2. Configure os fluxos Power Automate"
Write-Host "  3. Conecte as ferramentas no Copilot Studio"
Write-Host "  4. Teste o fluxo completo"
Write-Host ""

# Desconectar
Disconnect-PnPOnline
```

---

## 2. Script: Verificar Estrutura Existente

### Arquivo: `Verify-GestaoFerias.ps1`

```powershell
<#
.SYNOPSIS
    Verifica se todas as listas e colunas estão criadas corretamente.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SiteUrl
)

Connect-PnPOnline -Url $SiteUrl -Interactive

$requiredLists = @(
    "Colaboradores_Aprovadores",
    "Solicitacoes_Ferias",
    "Historico_Ferias",
    "Saldo_Ferias",
    "Feriados",
    "Alertas_Ferias"
)

Write-Host "Verificando estrutura..." -ForegroundColor Cyan
Write-Host ""

foreach ($listName in $requiredLists) {
    $list = Get-PnPList -Identity $listName -ErrorAction SilentlyContinue
    
    if ($list) {
        $itemCount = $list.ItemCount
        $fields = Get-PnPField -List $listName | Where-Object { -not $_.Hidden }
        
        Write-Host "✅ $listName" -ForegroundColor Green
        Write-Host "   Itens: $itemCount | Colunas: $($fields.Count)" -ForegroundColor Gray
    }
    else {
        Write-Host "❌ $listName - NÃO ENCONTRADA" -ForegroundColor Red
    }
}

Disconnect-PnPOnline
```

---

## 3. Script: Importar Colaboradores do Excel

### Arquivo: `Import-Colaboradores.ps1`

```powershell
<#
.SYNOPSIS
    Importa colaboradores do Excel para a lista SharePoint.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SiteUrl,
    
    [Parameter(Mandatory=$true)]
    [string]$ExcelPath
)

# Verificar se ImportExcel está instalado
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Write-Host "Instalando módulo ImportExcel..." -ForegroundColor Yellow
    Install-Module -Name ImportExcel -Scope CurrentUser -Force
}

Import-Module ImportExcel

Connect-PnPOnline -Url $SiteUrl -Interactive

$excelData = Import-Excel -Path $ExcelPath

Write-Host "Importando $($excelData.Count) colaboradores..." -ForegroundColor Cyan

$count = 0
foreach ($row in $excelData) {
    $itemValues = @{
        "Title" = $row.Nome
        "Email" = $row.Email
        "Departamento" = $row.Departamento
        "Cargo" = $row.Cargo
        "Gestor_Nome" = $row.'Gestor Nome'
        "Gestor_Email" = $row.'Gestor Email'
        "Diretor_Nome" = $row.'Diretor Nome'
        "Diretor_Email" = $row.'Diretor Email'
        "Ativo" = $true
        "EhGestor" = ($row.EhGestor -eq "Sim" -or $row.EhGestor -eq $true)
    }
    
    try {
        Add-PnPListItem -List "Colaboradores_Aprovadores" -Values $itemValues | Out-Null
        $count++
        Write-Host "." -NoNewline -ForegroundColor Green
    }
    catch {
        Write-Host "x" -NoNewline -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Importação concluída! $count de $($excelData.Count) registros importados." -ForegroundColor Green

Disconnect-PnPOnline
```

---

## 4. Script: Limpar Ambiente (Reset)

### Arquivo: `Reset-GestaoFerias.ps1`

```powershell
<#
.SYNOPSIS
    Remove todas as listas do projeto para recomeçar do zero.
.WARNING
    Este script DELETA dados! Use com cuidado.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SiteUrl,
    
    [switch]$Confirm
)

if (-not $Confirm) {
    Write-Host "⚠️  ATENÇÃO: Este script irá DELETAR todas as listas do projeto!" -ForegroundColor Red
    Write-Host "Use -Confirm para executar." -ForegroundColor Yellow
    exit
}

Connect-PnPOnline -Url $SiteUrl -Interactive

$listsToRemove = @(
    "Colaboradores_Aprovadores",
    "Solicitacoes_Ferias",
    "Historico_Ferias",
    "Saldo_Ferias",
    "Feriados",
    "Alertas_Ferias"
)

foreach ($listName in $listsToRemove) {
    $list = Get-PnPList -Identity $listName -ErrorAction SilentlyContinue
    if ($list) {
        Remove-PnPList -Identity $listName -Force
        Write-Host "🗑️  Removida: $listName" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Reset concluído! Execute Deploy-GestaoFerias.ps1 para recriar." -ForegroundColor Green

Disconnect-PnPOnline
```

---

## 5. Comandos Rápidos

### Execução Completa

```powershell
# 1. Conectar e fazer deploy completo
.\Deploy-GestaoFerias.ps1 -SiteUrl "https://[tenant].sharepoint.com/sites/[site]" -ExcelPath "D:\VMs\Projetos\Copilot_Studio_Config\Users_Approvers.xlsx"

# 2. Verificar se tudo foi criado
.\Verify-GestaoFerias.ps1 -SiteUrl "https://[tenant].sharepoint.com/sites/[site]"

# 3. (Opcional) Importar mais colaboradores
.\Import-Colaboradores.ps1 -SiteUrl "https://[tenant].sharepoint.com/sites/[site]" -ExcelPath "novos_colaboradores.xlsx"

# 4. (Opcional) Reset completo
.\Reset-GestaoFerias.ps1 -SiteUrl "https://[tenant].sharepoint.com/sites/[site]" -Confirm
```

---

## Estrutura de Arquivos

```
D:\VMs\Projetos\Copilot_Studio_Config\
├── Users_Approvers.xlsx           # Dados de entrada
├── Scripts\
│   ├── Deploy-GestaoFerias.ps1    # Deploy principal
│   ├── Verify-GestaoFerias.ps1    # Verificação
│   ├── Import-Colaboradores.ps1   # Importar Excel
│   └── Reset-GestaoFerias.ps1     # Limpar ambiente
└── Docs\
    ├── Configuracao_Agente.md
    └── Visao_Gerencial.md
```

---

> **Próximo passo**: Após executar o deploy CLI, configure os **Power Automate Flows** e conecte ao **Copilot Studio**.
