<#
.SYNOPSIS
    End-to-End test for the VacationApproval flow.
.DESCRIPTION
    Creates a PENDING vacation request to trigger the flow and validates the pipeline.
.EXAMPLE
    .\07-E2E-Test-VacationApproval.ps1
    .\07-E2E-Test-VacationApproval.ps1 -TestEmployeeEmail "user@minsait.com" -VacationDays 10
    .\07-E2E-Test-VacationApproval.ps1 -CleanupOnly
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$SiteUrl = "https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA",

    [Parameter(Mandatory = $false)]
    [string]$TestEmployeeEmail = "",

    [Parameter(Mandatory = $false)]
    [int]$DaysFromNow = 60,

    [Parameter(Mandatory = $false)]
    [int]$VacationDays = 10,

    [Parameter(Mandatory = $false)]
    [switch]$SkipPreFlight,

    [Parameter(Mandatory = $false)]
    [switch]$CleanupOnly
)

# Try modern module first, fallback to legacy
try {
    Import-Module PnP.PowerShell -ErrorAction Stop
}
catch {
    Import-Module SharePointPnPPowerShellOnline -ErrorAction Stop
}

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "  GESTAO FERIAS - E2E TEST SUITE" -ForegroundColor Cyan
Write-Host "  VacationApproval Flow Validation" -ForegroundColor Cyan
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Test Config:" -ForegroundColor Gray

$autoLabel = "(auto-detect first active)"
if ($TestEmployeeEmail) { $autoLabel = $TestEmployeeEmail }
Write-Host "    Employee:       $autoLabel" -ForegroundColor Gray

$futureDate = (Get-Date).AddDays($DaysFromNow)
Write-Host "    Start date:     $(Get-Date $futureDate -Format 'dd/MM/yyyy') ($DaysFromNow days from now)" -ForegroundColor Gray
Write-Host "    Duration:       $VacationDays dias" -ForegroundColor Gray
Write-Host "    Cleanup only:   $CleanupOnly" -ForegroundColor Gray
Write-Host ""

# ==================================================================
# CONNECT
# ==================================================================

Write-Host "[CONEXAO] Conectando ao SharePoint..." -ForegroundColor Yellow
Connect-PnPOnline -Url $SiteUrl -UseWebLogin
Write-Host "[CONEXAO] Conectado!" -ForegroundColor Green
Write-Host ""

# ==================================================================
# CLEANUP MODE: Remove previous test items
# ==================================================================

Write-Host "[CLEANUP] Removendo itens de teste anteriores..." -ForegroundColor Yellow

$allItems = Get-PnPListItem -List "Solicitacoes_Ferias" -PageSize 100
$existingTestItems = $allItems | Where-Object {
    $obs = $_.FieldValues["Observacoes"]
    $obs -and $obs -like "*E2E_TEST*"
}

if ($existingTestItems -and @($existingTestItems).Count -gt 0) {
    foreach ($item in $existingTestItems) {
        $itemId = $item.Id
        $itemTitle = $item.FieldValues["Title"]
        try {
            Remove-PnPListItem -List "Solicitacoes_Ferias" -Identity $itemId -Force
            Write-Host "  [DEL] Item ID $itemId ($itemTitle)" -ForegroundColor DarkGray
        }
        catch {
            Write-Host "  [WARN] Could not delete ID ${itemId}: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    Write-Host "  [OK] Test items removed" -ForegroundColor Green
} else {
    Write-Host "  [OK] No test items found" -ForegroundColor Green
}

if ($CleanupOnly) {
    Write-Host ""
    Write-Host "[DONE] Cleanup completo." -ForegroundColor Green
    Disconnect-PnPOnline
    exit 0
}

Write-Host ""

# ==================================================================
# PRE-FLIGHT CHECKS
# ==================================================================

if (-not $SkipPreFlight) {
    Write-Host "==============================================================" -ForegroundColor Cyan
    Write-Host "  PRE-FLIGHT CHECKS" -ForegroundColor Cyan
    Write-Host "==============================================================" -ForegroundColor Cyan
    Write-Host ""

    $allPassed = $true

    # --- Check 1: Colaboradores_Aprovadores has data ---
    Write-Host "  [1/5] Colaboradores_Aprovadores..." -NoNewline
    $colaboradores = Get-PnPListItem -List "Colaboradores_Aprovadores" -PageSize 100
    if ($colaboradores -and $colaboradores.Count -gt 0) {
        Write-Host " OK ($($colaboradores.Count) registros)" -ForegroundColor Green
    } else {
        Write-Host " FAIL (empty)" -ForegroundColor Red
        $allPassed = $false
    }

    # --- Check 2: Saldo_Ferias has data ---
    Write-Host "  [2/5] Saldo_Ferias..." -NoNewline
    $saldos = Get-PnPListItem -List "Saldo_Ferias" -PageSize 100
    if ($saldos -and $saldos.Count -gt 0) {
        Write-Host " OK ($($saldos.Count) registros)" -ForegroundColor Green
    } else {
        Write-Host " FAIL (empty - run 05-Seed-Saldo-Ferias.ps1)" -ForegroundColor Red
        $allPassed = $false
    }

    # --- Check 3: Feriados has data ---
    Write-Host "  [3/5] Feriados..." -NoNewline
    $feriados = Get-PnPListItem -List "Feriados" -PageSize 100
    if ($feriados -and $feriados.Count -gt 0) {
        Write-Host " OK ($($feriados.Count) registros)" -ForegroundColor Green
    } else {
        Write-Host " WARN (empty - not critical)" -ForegroundColor Yellow
    }

    # --- Check 4: Find test employee ---
    Write-Host "  [4/5] Test employee..." -NoNewline

    if (-not $TestEmployeeEmail) {
        # Auto-detect: pick first active employee with an approver
        $testEmployee = $colaboradores | Where-Object {
            $_.FieldValues["Ativo"] -eq $true -and $_.FieldValues["AprovadorEmail"]
        } | Select-Object -First 1

        if ($testEmployee) {
            $TestEmployeeEmail = $testEmployee.FieldValues["Email"]
            $testEmployeeName = $testEmployee.FieldValues["NomeCompleto"]
            $testApproverEmail = $testEmployee.FieldValues["AprovadorEmail"]
            $testApproverName = $testEmployee.FieldValues["AprovadorNome"]
            Write-Host " OK (auto: $testEmployeeName)" -ForegroundColor Green
        } else {
            Write-Host " FAIL (no active employee with approver)" -ForegroundColor Red
            $allPassed = $false
        }
    } else {
        $testEmployee = $colaboradores | Where-Object { $_.FieldValues["Email"] -eq $TestEmployeeEmail } | Select-Object -First 1
        if ($testEmployee) {
            $testEmployeeName = $testEmployee.FieldValues["NomeCompleto"]
            $testApproverEmail = $testEmployee.FieldValues["AprovadorEmail"]
            $testApproverName = $testEmployee.FieldValues["AprovadorNome"]
            Write-Host " OK ($testEmployeeName)" -ForegroundColor Green
        } else {
            Write-Host " FAIL (not found: $TestEmployeeEmail)" -ForegroundColor Red
            $allPassed = $false
        }
    }

    # --- Check 5: Employee has balance ---
    Write-Host "  [5/5] Employee balance..." -NoNewline
    if ($TestEmployeeEmail) {
        $balance = $saldos | Where-Object { $_.FieldValues["ColaboradorEmail"] -eq $TestEmployeeEmail } | Select-Object -First 1
        if ($balance) {
            $availableDays = $balance.FieldValues["SaldoDisponivel"]
            if ($availableDays -ge $VacationDays) {
                Write-Host " OK ($availableDays dias disponiveis)" -ForegroundColor Green
            } else {
                Write-Host " FAIL (only $availableDays dias, need $VacationDays)" -ForegroundColor Red
                $allPassed = $false
            }
        } else {
            Write-Host " FAIL (no balance record)" -ForegroundColor Red
            $allPassed = $false
        }
    } else {
        Write-Host " SKIP (no employee)" -ForegroundColor DarkGray
    }

    Write-Host ""

    if (-not $allPassed) {
        Write-Host "[ABORT] Pre-flight checks FAILED. Fix issues above before testing." -ForegroundColor Red
        Write-Host ""
        Disconnect-PnPOnline
        exit 1
    }

    Write-Host "[PRE-FLIGHT] All checks PASSED" -ForegroundColor Green
    Write-Host ""
}

# ==================================================================
# BUSINESS RULES VALIDATION
# ==================================================================

Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "  BUSINESS RULES VALIDATION" -ForegroundColor Cyan
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host ""

$startDate = (Get-Date).AddDays($DaysFromNow)
$endDate = $startDate.AddDays($VacationDays - 1)
$daysAdvance = ($startDate - (Get-Date)).Days

Write-Host "  BR-001: Min 45 days advance... " -NoNewline
if ($daysAdvance -ge 45) {
    Write-Host "PASS ($daysAdvance dias)" -ForegroundColor Green
} else {
    Write-Host "FAIL ($daysAdvance < 45 dias)" -ForegroundColor Red
    Disconnect-PnPOnline
    exit 1
}

Write-Host "  BR-002: Min 5 days request... " -NoNewline
if ($VacationDays -ge 5) {
    Write-Host "PASS ($VacationDays dias)" -ForegroundColor Green
} else {
    Write-Host "FAIL ($VacationDays < 5 dias)" -ForegroundColor Red
    Disconnect-PnPOnline
    exit 1
}

Write-Host "  BR-003: Max 30 days request... " -NoNewline
if ($VacationDays -le 30) {
    Write-Host "PASS ($VacationDays dias)" -ForegroundColor Green
} else {
    Write-Host "FAIL ($VacationDays > 30 dias)" -ForegroundColor Red
    Disconnect-PnPOnline
    exit 1
}

Write-Host ""

# ==================================================================
# CREATE TEST VACATION REQUEST
# ==================================================================

Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "  CREATING TEST VACATION REQUEST" -ForegroundColor Cyan
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host ""

$testTitle = "E2E_TEST_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$startDateStr = $startDate.ToString("yyyy-MM-ddT00:00:00Z")
$endDateStr = $endDate.ToString("yyyy-MM-ddT00:00:00Z")
$startFmt = Get-Date $startDate -Format "dd/MM/yyyy"
$endFmt = Get-Date $endDate -Format "dd/MM/yyyy"

Write-Host "  Creating request:" -ForegroundColor Gray
Write-Host "    Title:      $testTitle" -ForegroundColor Gray
Write-Host "    Employee:   $testEmployeeName ($TestEmployeeEmail)" -ForegroundColor Gray
Write-Host "    Approver:   $testApproverName ($testApproverEmail)" -ForegroundColor Gray
Write-Host "    Period:     $startFmt a $endFmt" -ForegroundColor Gray
Write-Host "    Days:       $VacationDays" -ForegroundColor Gray
Write-Host "    Status:     PENDING" -ForegroundColor Gray
Write-Host ""

$obsText = "[E2E_TEST] Teste automatizado criado em $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss'). Pode ser excluido com -CleanupOnly."

try {
    $newItem = Add-PnPListItem -List "Solicitacoes_Ferias" -Values @{
        "Title"             = $testTitle
        "ColaboradorEmail"  = $TestEmployeeEmail
        "ColaboradorNome"   = $testEmployeeName
        "DataInicio"        = $startDateStr
        "DataFim"           = $endDateStr
        "DiasUteis"         = $VacationDays
        "Status"            = "PENDING"
        "AprovadorEmail"    = $testApproverEmail
        "AprovadorNome"     = $testApproverName
        "Observacoes"       = $obsText
        "Tipo"              = "NEW"
    }

    $newItemId = $newItem.Id
    Write-Host "[OK] Item criado com sucesso!" -ForegroundColor Green
    Write-Host "  Item ID: $newItemId" -ForegroundColor Green
    Write-Host "  SP URL:  $SiteUrl/Lists/Solicitacoes_Ferias/DispForm.aspx?ID=$newItemId" -ForegroundColor Cyan
    Write-Host ""
}
catch {
    Write-Host "[ERRO] Falha ao criar item de teste:" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Disconnect-PnPOnline
    exit 1
}

# ==================================================================
# POST-CREATE VERIFICATION
# ==================================================================

Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "  POST-CREATE VERIFICATION" -ForegroundColor Cyan
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host ""

$verifyItem = Get-PnPListItem -List "Solicitacoes_Ferias" -Id $newItemId
$verifyStatus = $verifyItem.FieldValues["Status"]
$verifyEmail = $verifyItem.FieldValues["ColaboradorEmail"]
$verifyApprover = $verifyItem.FieldValues["AprovadorEmail"]

$s1 = if ($verifyStatus -eq "PENDING") { "Green" } else { "Red" }
$s2 = if ($verifyEmail -eq $TestEmployeeEmail) { "Green" } else { "Red" }
$s3 = if ($verifyApprover -eq $testApproverEmail) { "Green" } else { "Red" }

Write-Host "  [VERIFY] Status:   $verifyStatus" -ForegroundColor $s1
Write-Host "  [VERIFY] Email:    $verifyEmail" -ForegroundColor $s2
Write-Host "  [VERIFY] Approver: $verifyApprover" -ForegroundColor $s3
Write-Host ""

# ==================================================================
# EXPECTED FLOW BEHAVIOR
# ==================================================================

Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "  EXPECTED FLOW BEHAVIOR (within 3 minutes)" -ForegroundColor Cyan
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  The VacationApproval flow polls every 3 minutes." -ForegroundColor Gray
Write-Host "  Within ~3 minutes, you should see:" -ForegroundColor Gray
Write-Host ""
Write-Host "  1. Flow triggers on the new PENDING item" -ForegroundColor White
Write-Host "  2. GetEmployeeDetails looks up employee in Colaboradores_Aprovadores" -ForegroundColor White
Write-Host "  3. Status guard: item has Status=PENDING -> proceeds" -ForegroundColor White
Write-Host "  4. Approval request sent to: $testApproverEmail" -ForegroundColor White
Write-Host "     Check Teams Approvals Center for the request" -ForegroundColor Gray
Write-Host "  5. After approval/rejection:" -ForegroundColor White
Write-Host "     APPROVE: Status->APPROVED, balance deducted, notifications sent" -ForegroundColor Green
Write-Host "     REJECT: Status->REJECTED, reason included in notification" -ForegroundColor Red
Write-Host ""

# ==================================================================
# MONITORING INSTRUCTIONS
# ==================================================================

Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "  HOW TO MONITOR" -ForegroundColor Cyan
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Flow run history:" -ForegroundColor White
Write-Host "     https://make.powerautomate.com/environments/e2d10003-4d8e-e007-9d63-76d5fe89ef56/flows/66b1bad4-5c97-47ef-955a-9f44cf174aa7/details" -ForegroundColor Gray
Write-Host ""
Write-Host "  SharePoint list (check Status change):" -ForegroundColor White
Write-Host "     $SiteUrl/Lists/Solicitacoes_Ferias" -ForegroundColor Gray
Write-Host ""
Write-Host "  Approvals Center (check for pending approval):" -ForegroundColor White
Write-Host "     Open Teams > Approvals app > look for Solicitacao de Ferias" -ForegroundColor Gray
Write-Host ""
Write-Host "  To clean up test items later:" -ForegroundColor White
Write-Host "     .\07-E2E-Test-VacationApproval.ps1 -CleanupOnly" -ForegroundColor Gray
Write-Host ""

# ==================================================================
# WAIT AND RE-CHECK STATUS
# ==================================================================

Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "  WAITING FOR FLOW TRIGGER (polling every 30s, max 5 min)" -ForegroundColor Cyan
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host ""

$maxWait = 300
$pollInterval = 30
$elapsed = 0
$currentStatus = "PENDING"

while ($elapsed -lt $maxWait) {
    Start-Sleep -Seconds $pollInterval
    $elapsed += $pollInterval

    $checkItem = Get-PnPListItem -List "Solicitacoes_Ferias" -Id $newItemId
    $currentStatus = $checkItem.FieldValues["Status"]

    $timestamp = Get-Date -Format "HH:mm:ss"

    if ($currentStatus -ne "PENDING") {
        Write-Host "  [$timestamp] Status changed: PENDING -> $currentStatus" -ForegroundColor Green
        Write-Host ""

        if ($currentStatus -eq "APPROVED") {
            Write-Host "  APPROVAL PATH TRIGGERED!" -ForegroundColor Green

            # Check if balance was deducted
            $postBalanceItems = Get-PnPListItem -List "Saldo_Ferias" -PageSize 100
            $postBalance = $postBalanceItems | Where-Object {
                $_.FieldValues["ColaboradorEmail"] -eq $TestEmployeeEmail
            } | Select-Object -First 1

            if ($postBalance) {
                $postAvailable = $postBalance.FieldValues["SaldoDisponivel"]
                $expectedBalance = $availableDays - $VacationDays
                $bColor = if ($postAvailable -eq $expectedBalance) { "Green" } else { "Yellow" }
                Write-Host "  Balance check: $availableDays -> $postAvailable (expected: $expectedBalance)" -ForegroundColor $bColor
            }
        }
        elseif ($currentStatus -eq "REJECTED") {
            Write-Host "  REJECTION PATH TRIGGERED!" -ForegroundColor Yellow
        }

        break
    }

    Write-Host "  [$timestamp] Status: $currentStatus (waiting... ${elapsed}/${maxWait} s)" -ForegroundColor DarkGray
}

if ($elapsed -ge $maxWait -and $currentStatus -eq "PENDING") {
    Write-Host ""
    Write-Host "  Timeout reached (5 min). Status still PENDING." -ForegroundColor Yellow
    Write-Host "  This is normal - the flow may need more time or the approval is pending." -ForegroundColor Yellow
    Write-Host "  Check the flow run history manually:" -ForegroundColor Yellow
    Write-Host "  https://make.powerautomate.com/environments/e2d10003-4d8e-e007-9d63-76d5fe89ef56/flows/66b1bad4-5c97-47ef-955a-9f44cf174aa7/details" -ForegroundColor Gray
}

# ==================================================================
# FINAL SUMMARY
# ==================================================================

Write-Host ""
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "  E2E TEST SUMMARY" -ForegroundColor Cyan
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Test Item ID:     $newItemId" -ForegroundColor White
Write-Host "  Employee:         $testEmployeeName ($TestEmployeeEmail)" -ForegroundColor White
Write-Host "  Approver:         $testApproverName ($testApproverEmail)" -ForegroundColor White
Write-Host "  Period:           $startFmt a $endFmt" -ForegroundColor White
Write-Host "  Days:             $VacationDays" -ForegroundColor White

$finalColor = if ($currentStatus -ne "PENDING") { "Green" } else { "Yellow" }
Write-Host "  Final Status:     $currentStatus" -ForegroundColor $finalColor
Write-Host ""
Write-Host "  Cleanup: .\07-E2E-Test-VacationApproval.ps1 -CleanupOnly" -ForegroundColor DarkGray
Write-Host ""

Disconnect-PnPOnline
Write-Host "[DONE] Test complete." -ForegroundColor Green
