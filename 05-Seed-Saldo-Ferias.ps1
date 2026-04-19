<#
.SYNOPSIS
    Seeds initial vacation balance (Saldo_Ferias) for all active employees.
    Reads from Colaboradores_Aprovadores and creates one balance record per employee.
.DESCRIPTION
    Resolves R-002: Saldo_Ferias list has no initial data.
    Each employee gets a default of 30 vacation days for the current reference year.
.PARAMETER SiteUrl
    URL do site SharePoint
.PARAMETER AnoReferencia
    Reference year for vacation balance (default: current year)
.PARAMETER SaldoInicial
    Initial vacation balance in days (default: 30)
.EXAMPLE
    .\05-Seed-Saldo-Ferias.ps1
    .\05-Seed-Saldo-Ferias.ps1 -AnoReferencia 2026 -SaldoInicial 30
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$SiteUrl = "https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA",
    
    [Parameter(Mandatory = $false)]
    [int]$AnoReferencia = (Get-Date).Year,

    [Parameter(Mandatory = $false)]
    [int]$SaldoInicial = 30
)

# Try modern module first, fallback to legacy
try {
    Import-Module PnP.PowerShell -ErrorAction Stop
}
catch {
    Import-Module SharePointPnPPowerShellOnline -ErrorAction Stop
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " SEED SALDO DE FÉRIAS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[CONFIG] Ano Referência: $AnoReferencia" -ForegroundColor Gray
Write-Host "[CONFIG] Saldo Inicial: $SaldoInicial dias" -ForegroundColor Gray
Write-Host ""

# Conectar
Write-Host "[CONEXÃO] Conectando ao SharePoint..." -ForegroundColor Yellow
Connect-PnPOnline -Url $SiteUrl -UseWebLogin
Write-Host "[CONEXÃO] Conectado!" -ForegroundColor Green
Write-Host ""

# ═══════════════════════════════════════════════════════════════════
# CHECK: Verify Saldo_Ferias is empty (avoid duplicates)
# ═══════════════════════════════════════════════════════════════════

Write-Host "[CHECK] Verificando registros existentes em Saldo_Ferias..." -ForegroundColor Yellow
$existingItems = Get-PnPListItem -List "Saldo_Ferias" -PageSize 100
$existingEmails = @()

if ($existingItems -and $existingItems.Count -gt 0) {
    $existingEmails = $existingItems | ForEach-Object { $_.FieldValues["ColaboradorEmail"] }
    Write-Host "[CHECK] Encontrados $($existingItems.Count) registros existentes" -ForegroundColor Yellow
    Write-Host "[CHECK] Modo: SKIP para emails já existentes" -ForegroundColor Yellow
} else {
    Write-Host "[CHECK] Nenhum registro existente. Modo: inserção total" -ForegroundColor Green
}
Write-Host ""

# ═══════════════════════════════════════════════════════════════════
# READ: Get all active employees from Colaboradores_Aprovadores
# ═══════════════════════════════════════════════════════════════════

Write-Host "[LEITURA] Buscando colaboradores ativos..." -ForegroundColor Yellow
$colaboradores = Get-PnPListItem -List "Colaboradores_Aprovadores" -PageSize 100

if (-not $colaboradores -or $colaboradores.Count -eq 0) {
    Write-Host "[ERRO] Nenhum colaborador encontrado em Colaboradores_Aprovadores!" -ForegroundColor Red
    Write-Host "[ERRO] Execute 03-Importar-Dados.ps1 primeiro." -ForegroundColor Red
    Disconnect-PnPOnline
    exit 1
}

Write-Host "[LEITURA] $($colaboradores.Count) colaboradores encontrados" -ForegroundColor Green
Write-Host ""

# ═══════════════════════════════════════════════════════════════════
# SEED: Create balance records
# ═══════════════════════════════════════════════════════════════════

Write-Host "[SEED] Criando registros de saldo..." -ForegroundColor Yellow

$created = 0
$skipped = 0
$errors = 0

foreach ($colab in $colaboradores) {
    $email = $colab.FieldValues["Email"]
    $nome = $colab.FieldValues["NomeCompleto"]
    $ativo = $colab.FieldValues["Ativo"]
    $dataAdmissao = $colab.FieldValues["DataAdmissao"]

    # Skip inactive employees
    if ($ativo -eq $false) {
        Write-Host "  [SKIP] $nome (inativo)" -ForegroundColor DarkGray
        $skipped++
        continue
    }

    # Skip if balance already exists for this email
    if ($existingEmails -contains $email) {
        Write-Host "  [SKIP] $nome (saldo já existe)" -ForegroundColor DarkGray
        $skipped++
        continue
    }

    # Calculate acquisition period based on hire date
    # Default: Jan 1 - Dec 31 of reference year
    $periodoInicio = "$AnoReferencia-01-01"
    $periodoFim = "$AnoReferencia-12-31"

    # If hire date is available, use it for acquisition period display
    if ($dataAdmissao) {
        $hireDate = [DateTime]$dataAdmissao
        $periodoInicio = "$($hireDate.Year)-$($hireDate.Month.ToString('00'))-$($hireDate.Day.ToString('00'))"
    }

    try {
        $itemValues = @{
            "Title"              = "$nome - $AnoReferencia"
            "ColaboradorEmail"   = $email
            "AnoReferencia"      = $AnoReferencia
            "SaldoTotal"         = $SaldoInicial
            "DiasUsados"         = 0
            "DiasAgendados"      = 0
            "SaldoDisponivel"    = $SaldoInicial
            "DataAtualizacao"    = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        }

        Add-PnPListItem -List "Saldo_Ferias" -Values $itemValues | Out-Null
        $created++
        Write-Host "  [OK] $nome ($email) → $SaldoInicial dias" -ForegroundColor Green
    }
    catch {
        $errors++
        Write-Host "  [ERRO] $nome ($email): $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ═══════════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "========================================" -ForegroundColor $(if ($errors -eq 0) { "Green" } else { "Yellow" })
Write-Host " SEED CONCLUÍDO!" -ForegroundColor $(if ($errors -eq 0) { "Green" } else { "Yellow" })
Write-Host "========================================" -ForegroundColor $(if ($errors -eq 0) { "Green" } else { "Yellow" })
Write-Host ""
Write-Host "Resumo:" -ForegroundColor Cyan
Write-Host "  - Criados:  $created" -ForegroundColor Green
Write-Host "  - Pulados:  $skipped" -ForegroundColor DarkGray
Write-Host "  - Erros:    $errors" -ForegroundColor $(if ($errors -eq 0) { "Green" } else { "Red" })
Write-Host ""

if ($created -gt 0) {
    Write-Host "[NEXT] Verifique os registros em:" -ForegroundColor Cyan
    Write-Host "  $SiteUrl/Lists/Saldo_Ferias" -ForegroundColor Gray
}

Disconnect-PnPOnline
