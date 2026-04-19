<#
.SYNOPSIS
    Adds DataAdmissao to Colaboradores_Aprovadores, seeds hire dates,
    adds DataVencimento to Saldo_Ferias, and backfills based on CLT logic.
.DESCRIPTION
    Two-phase fix:
    Phase A: Add DataAdmissao column + seed realistic hire dates for all employees
    Phase B: Add DataVencimento column + backfill using hire-date-based CLT calculation

    CLT "vacations birthday" rule:
    - DataVencimento = hiring-month/day in year (AnoReferencia + 1)
    - This is the DEADLINE by which those vacation days MUST be used
.EXAMPLE
    .\09-Add-DataVencimento-Column.ps1
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$SiteUrl = "https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA"
)

# Try modern module first, fallback to legacy
try {
    Import-Module PnP.PowerShell -ErrorAction Stop
}
catch {
    Import-Module SharePointPnPPowerShellOnline -ErrorAction Stop
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " FIX SCHEMA: DataAdmissao + DataVencimento" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================
# CONNECT
# ============================================

Write-Host "[CONNECT] Conectando ao SharePoint..." -ForegroundColor Yellow
Connect-PnPOnline -Url $SiteUrl -UseWebLogin
Write-Host "[CONNECT] Conectado!" -ForegroundColor Green
Write-Host ""

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# PHASE A: DataAdmissao on Colaboradores_Aprovadores
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Write-Host "--- PHASE A: DataAdmissao ---" -ForegroundColor Magenta
Write-Host ""

$empList = "Colaboradores_Aprovadores"
$admCol = "DataAdmissao"

# A1: Create column if missing
Write-Host "[A1] Checking column '$admCol' on '$empList'..." -ForegroundColor Yellow
$existsAdm = Get-PnPField -List $empList -Identity $admCol -ErrorAction SilentlyContinue

if ($existsAdm) {
    Write-Host "[A1] '$admCol' already exists - skipping creation" -ForegroundColor DarkGray
}
else {
    try {
        Add-PnPField -List $empList `
            -DisplayName "Data Admissao" `
            -InternalName $admCol `
            -Type DateTime `
            -AddToDefaultView
        Write-Host "[A1] '$admCol' created!" -ForegroundColor Green
    }
    catch {
        Write-Host "[ERRO] Failed to create column: $($_.Exception.Message)" -ForegroundColor Red
        Disconnect-PnPOnline
        exit 1
    }
}
Write-Host ""

# A2: Seed hire dates where missing
# Use staggered realistic dates (different months across 2019-2024)
Write-Host "[A2] Seeding DataAdmissao for employees without one..." -ForegroundColor Yellow

$empItems = Get-PnPListItem -List $empList -PageSize 200

# Realistic hire dates - staggered across years and months
$seedDates = @(
    "2019-03-11", "2019-08-05", "2020-01-20", "2020-06-15",
    "2020-11-02", "2021-02-22", "2021-07-12", "2021-10-04",
    "2022-01-17", "2022-04-25", "2022-09-05", "2023-02-13",
    "2023-06-19", "2023-11-06", "2024-03-18", "2024-08-01"
)

$seeded = 0
$alreadySet = 0
$idx = 0

foreach ($emp in $empItems) {
    $empId = $emp.Id
    $empEmail = $emp.FieldValues["Email"]
    $existing = $emp.FieldValues[$admCol]

    if ($existing) {
        $alreadySet++
        Write-Host "  [SKIP] ID $empId ($empEmail) - already has DataAdmissao" -ForegroundColor DarkGray
        continue
    }

    # Pick a date from the pool (round-robin)
    $dateStr = $seedDates[$idx % $seedDates.Count]
    $idx++

    try {
        Set-PnPListItem -List $empList -Identity $empId -Values @{
            $admCol = "${dateStr}T00:00:00Z"
        } | Out-Null
        $seeded++
        Write-Host "  [OK] ID $empId ($empEmail) -> DataAdmissao = $dateStr" -ForegroundColor Green
    }
    catch {
        Write-Host "  [ERRO] ID $empId ($empEmail): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "[A2] Seeded: $seeded | Already set: $alreadySet" -ForegroundColor Cyan
Write-Host ""

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# PHASE B: DataVencimento on Saldo_Ferias
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Write-Host "--- PHASE B: DataVencimento ---" -ForegroundColor Magenta
Write-Host ""

$saldoList = "Saldo_Ferias"
$vencCol = "DataVencimento"

# B1: Create column if missing
Write-Host "[B1] Checking column '$vencCol' on '$saldoList'..." -ForegroundColor Yellow
$existsVenc = Get-PnPField -List $saldoList -Identity $vencCol -ErrorAction SilentlyContinue

if ($existsVenc) {
    Write-Host "[B1] '$vencCol' already exists - skipping creation" -ForegroundColor DarkGray
}
else {
    try {
        Add-PnPField -List $saldoList `
            -DisplayName $vencCol `
            -InternalName $vencCol `
            -Type DateTime `
            -AddToDefaultView
        Write-Host "[B1] '$vencCol' created!" -ForegroundColor Green
    }
    catch {
        Write-Host "[ERRO] Failed to create column: $($_.Exception.Message)" -ForegroundColor Red
        Disconnect-PnPOnline
        exit 1
    }
}
Write-Host ""

# B2: Reload employee data (now with DataAdmissao)
Write-Host "[B2] Loading employee hire dates..." -ForegroundColor Yellow

$empItemsRefresh = Get-PnPListItem -List $empList -PageSize 200

$hireDateMap = @{}
foreach ($emp in $empItemsRefresh) {
    $empEmail = $emp.FieldValues["Email"]
    $admissao = $emp.FieldValues[$admCol]
    if ($empEmail -and $admissao) {
        $hireDateMap[$empEmail.ToLower()] = [DateTime]$admissao
    }
}

Write-Host "[B2] $($hireDateMap.Count) employees with DataAdmissao loaded" -ForegroundColor Green
Write-Host ""

# B3: Backfill DataVencimento
Write-Host "[B3] Backfilling DataVencimento on '$saldoList'..." -ForegroundColor Yellow

$saldoItems = Get-PnPListItem -List $saldoList -PageSize 100

if (-not $saldoItems -or $saldoItems.Count -eq 0) {
    Write-Host "[B3] No records found - nothing to update" -ForegroundColor DarkGray
}
else {
    Write-Host "[B3] $($saldoItems.Count) records found" -ForegroundColor Cyan

    $updated = 0
    $skipped = 0
    $noHireDate = 0
    $errCount = 0

    foreach ($item in $saldoItems) {
        $id = $item.Id
        $itemEmail = $item.FieldValues["ColaboradorEmail"]
        $anoRef = $item.FieldValues["AnoReferencia"]
        $currentVencimento = $item.FieldValues[$vencCol]

        # Skip if already has a value
        if ($currentVencimento) {
            Write-Host "  [SKIP] ID $id ($itemEmail) - already has DataVencimento" -ForegroundColor DarkGray
            $skipped++
            continue
        }

        # Look up hiring date
        $emailKey = if ($itemEmail) { $itemEmail.ToLower() } else { "" }
        $hireDate = $hireDateMap[$emailKey]

        if (-not $hireDate) {
            Write-Host "  [WARN] ID $id ($itemEmail) - DataAdmissao not found! Skipping." -ForegroundColor Yellow
            $noHireDate++
            continue
        }

        # Calculate DataVencimento = hiring month/day in year (AnoReferencia + 1)
        if ($anoRef) {
            $deadlineYear = [int]$anoRef + 1
        }
        else {
            $deadlineYear = (Get-Date).Year + 1
        }

        $hireMonth = $hireDate.Month
        $hireDay = $hireDate.Day

        # Handle Feb 29 edge case
        if ($hireMonth -eq 2 -and $hireDay -eq 29) {
            if (-not [DateTime]::IsLeapYear($deadlineYear)) {
                $hireDay = 28
            }
        }

        $dataVencimento = Get-Date -Year $deadlineYear -Month $hireMonth -Day $hireDay -Hour 0 -Minute 0 -Second 0
        $dataVencimentoISO = $dataVencimento.ToString("yyyy-MM-ddT00:00:00Z")

        try {
            Set-PnPListItem -List $saldoList -Identity $id -Values @{
                $vencCol = $dataVencimentoISO
            } | Out-Null

            $updated++
            $formatted = $dataVencimento.ToString("dd/MM/yyyy")
            $hireFmt = $hireDate.ToString("dd/MM")
            Write-Host "  [OK] ID $id ($itemEmail) -> DataVencimento = $formatted (hire: $hireFmt)" -ForegroundColor Green
        }
        catch {
            $errCount++
            Write-Host "  [ERRO] ID $id ($itemEmail): $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host ""
    $resultColor = if ($errCount -eq 0) { "Green" } else { "Yellow" }
    Write-Host "========================================" -ForegroundColor $resultColor
    Write-Host " ALL DONE!" -ForegroundColor $resultColor
    Write-Host "========================================" -ForegroundColor $resultColor
    Write-Host ""
    Write-Host "Resumo:" -ForegroundColor Cyan
    Write-Host "  Phase A - DataAdmissao seeded:  $seeded" -ForegroundColor Green
    Write-Host "  Phase B - DataVencimento set:   $updated" -ForegroundColor Green
    Write-Host "  Phase B - Skipped (had value):  $skipped" -ForegroundColor DarkGray
    Write-Host "  Phase B - No hire date:         $noHireDate" -ForegroundColor $(if ($noHireDate -eq 0) { "Green" } else { "Yellow" })
    Write-Host "  Phase B - Errors:               $errCount" -ForegroundColor $(if ($errCount -eq 0) { "Green" } else { "Red" })
}

Write-Host ""
Write-Host "[VERIFY] Check results at:" -ForegroundColor Cyan
Write-Host "  $SiteUrl/Lists/Colaboradores_Aprovadores" -ForegroundColor Gray
Write-Host "  $SiteUrl/Lists/Saldo_Ferias" -ForegroundColor Gray
Write-Host ""

# Cleanup temp files
$tempFiles = @("_inspect_emp.ps1", "_inspect_excel.ps1")
foreach ($f in $tempFiles) {
    $path = Join-Path (Split-Path $MyInvocation.MyCommand.Path) $f
    if (Test-Path $path) { Remove-Item $path -Force }
}

Disconnect-PnPOnline
