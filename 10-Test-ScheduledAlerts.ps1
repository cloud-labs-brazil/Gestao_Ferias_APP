<#
.SYNOPSIS
    Creates test data to verify the ScheduledAlerts flow works correctly.
.DESCRIPTION
    1. Creates an APPROVED vacation request starting in 3 days (triggers Section A: 7-day reminder)
    2. Optionally adjusts a Saldo_Ferias record's DataVencimento to within 60 days (triggers Section B)
    3. After manual flow test, checks Alertas_Ferias for created records
    4. Cleans up test data
.PARAMETER SiteUrl
    URL do site SharePoint
.PARAMETER Action
    "setup" = create test data | "verify" = check results | "cleanup" = remove test data
.EXAMPLE
    .\10-Test-ScheduledAlerts.ps1 -Action setup
    # Then manually test the flow in PA designer
    .\10-Test-ScheduledAlerts.ps1 -Action verify
    .\10-Test-ScheduledAlerts.ps1 -Action cleanup
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("setup", "verify", "cleanup")]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$SiteUrl = "https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA",

    [Parameter(Mandatory = $false)]
    [string]$TestEmail = "mbenicios@minsait.com"
)

# Try modern module first, fallback to legacy
try {
    Import-Module PnP.PowerShell -ErrorAction Stop
}
catch {
    Import-Module SharePointPnPPowerShellOnline -ErrorAction Stop
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " TEST SCHEDULED ALERTS - $($Action.ToUpper())" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Connect-PnPOnline -Url $SiteUrl -UseWebLogin
Write-Host "[CONEXÃO] Conectado!" -ForegroundColor Green
Write-Host ""

# Test data marker — used for cleanup
$testMarker = "TEST_SCHEDULED_ALERTS"

switch ($Action) {

    "setup" {
        # ═══════════════════════════════════════════════════════════════
        # CREATE TEST VACATION REQUEST (starts in 3 days = within 7-day window)
        # ═══════════════════════════════════════════════════════════════

        $startDate = (Get-Date).AddDays(3).ToString("yyyy-MM-ddT00:00:00Z")
        $endDate = (Get-Date).AddDays(8).ToString("yyyy-MM-ddT00:00:00Z")

        Write-Host "[SETUP] Criando solicitação de teste (APPROVED, início em 3 dias)..." -ForegroundColor Yellow

        # Get the employee's approver
        $empInfo = Get-PnPListItem -List "Colaboradores_Aprovadores" -PageSize 100 |
            Where-Object { $_.FieldValues["Email"] -eq $TestEmail } |
            Select-Object -First 1

        if (-not $empInfo) {
            Write-Host "[ERRO] Colaborador '$TestEmail' não encontrado!" -ForegroundColor Red
            Disconnect-PnPOnline
            exit 1
        }

        $aprovadorEmail = $empInfo.FieldValues["AprovadorEmail"]
        $nomeCompleto = $empInfo.FieldValues["NomeCompleto"]

        $testRequest = @{
            "Title"             = $testMarker
            "ColaboradorEmail"  = $TestEmail
            "ColaboradorNome"   = $nomeCompleto
            "DataInicio"        = $startDate
            "DataFim"           = $endDate
            "DiasUteis"         = 5
            "Tipo"              = "REGULAR"
            "Status"            = "APPROVED"
            "AprovadorEmail"    = $aprovadorEmail
            "DataAprovacao"     = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            "Observacoes"       = "TEST DATA - will be cleaned up"
            "CriadoPorBot"      = $false
        }

        $newItem = Add-PnPListItem -List "Solicitacoes_Ferias" -Values $testRequest
        Write-Host "  [OK] Solicitação criada — ID: $($newItem.Id)" -ForegroundColor Green
        Write-Host "       DataInicio: $startDate" -ForegroundColor Gray
        Write-Host "       Status: APPROVED" -ForegroundColor Gray

        # ═══════════════════════════════════════════════════════════════
        # ADJUST BALANCE TO EXPIRE WITHIN 60 DAYS (triggers Section B)
        # ═══════════════════════════════════════════════════════════════

        Write-Host ""
        Write-Host "[SETUP] Ajustando DataVencimento do saldo para testar Section B..." -ForegroundColor Yellow

        $balanceItem = Get-PnPListItem -List "Saldo_Ferias" -PageSize 100 |
            Where-Object { $_.FieldValues["ColaboradorEmail"] -eq $TestEmail } |
            Select-Object -First 1

        if ($balanceItem) {
            # Save original value for cleanup
            $originalVencimento = $balanceItem.FieldValues["DataVencimento"]
            
            # Set to expire in 30 days (within 60-day alert window)
            $testVencimento = (Get-Date).AddDays(30).ToString("yyyy-MM-ddT00:00:00Z")
            
            Set-PnPListItem -List "Saldo_Ferias" -Identity $balanceItem.Id -Values @{
                "DataVencimento" = $testVencimento
            } | Out-Null

            Write-Host "  [OK] DataVencimento ajustado → $(Get-Date $testVencimento -Format 'dd/MM/yyyy')" -ForegroundColor Green
            Write-Host "  [INFO] Valor original: $originalVencimento (será restaurado no cleanup)" -ForegroundColor DarkGray
        }
        else {
            Write-Host "  [WARN] Nenhum saldo encontrado para '$TestEmail' — Section B não será testada" -ForegroundColor Yellow
        }

        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host " PRÓXIMO PASSO:" -ForegroundColor Cyan
        Write-Host " 1. Abra o flow ScheduledAlerts no Power Automate" -ForegroundColor White
        Write-Host " 2. Clique 'Testar' → 'Manualmente'" -ForegroundColor White
        Write-Host " 3. Aguarde a execução completar" -ForegroundColor White
        Write-Host " 4. Execute: .\10-Test-ScheduledAlerts.ps1 -Action verify" -ForegroundColor White
        Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    }

    "verify" {
        # ═══════════════════════════════════════════════════════════════
        # CHECK RESULTS
        # ═══════════════════════════════════════════════════════════════

        Write-Host "[VERIFY] Verificando registros em Alertas_Ferias..." -ForegroundColor Yellow

        $alerts = Get-PnPListItem -List "Alertas_Ferias" -PageSize 100

        if (-not $alerts -or $alerts.Count -eq 0) {
            Write-Host "  [FAIL] Nenhum alerta encontrado!" -ForegroundColor Red
            Write-Host "  [HINT] Verifique se o flow executou sem erros" -ForegroundColor Yellow
        }
        else {
            Write-Host "  [OK] $($alerts.Count) alerta(s) encontrado(s):" -ForegroundColor Green
            Write-Host ""

            foreach ($alert in $alerts) {
                $tipo = $alert.FieldValues["TipoAlerta"]
                $email = $alert.FieldValues["ColaboradorEmail"]
                $msg = $alert.FieldValues["Mensagem"]
                $dataEnvio = $alert.FieldValues["DataEnvio"]
                $enviado = $alert.FieldValues["Enviado"]

                Write-Host "  ┌─ Tipo: $tipo" -ForegroundColor Cyan
                Write-Host "  │  Email: $email" -ForegroundColor Gray
                Write-Host "  │  Mensagem: $msg" -ForegroundColor Gray
                Write-Host "  │  DataEnvio: $dataEnvio" -ForegroundColor Gray
                Write-Host "  └─ Enviado: $enviado" -ForegroundColor Gray
                Write-Host ""
            }
        }

        # Also check the test vacation request
        Write-Host "[VERIFY] Verificando solicitação de teste..." -ForegroundColor Yellow
        $testItems = Get-PnPListItem -List "Solicitacoes_Ferias" -PageSize 100 |
            Where-Object { $_.FieldValues["Title"] -eq $testMarker }

        if ($testItems) {
            Write-Host "  [OK] Dados de teste encontrados (ID: $($testItems[0].Id))" -ForegroundColor Green
        }
        else {
            Write-Host "  [WARN] Dados de teste não encontrados — talvez já foram limpos?" -ForegroundColor Yellow
        }
    }

    "cleanup" {
        # ═══════════════════════════════════════════════════════════════
        # REMOVE TEST DATA
        # ═══════════════════════════════════════════════════════════════

        Write-Host "[CLEANUP] Removendo dados de teste..." -ForegroundColor Yellow

        # Remove test vacation requests
        $testItems = Get-PnPListItem -List "Solicitacoes_Ferias" -PageSize 100 |
            Where-Object { $_.FieldValues["Title"] -eq $testMarker }

        foreach ($item in $testItems) {
            Remove-PnPListItem -List "Solicitacoes_Ferias" -Identity $item.Id -Force
            Write-Host "  [OK] Solicitação removida — ID: $($item.Id)" -ForegroundColor Green
        }

        # Restore original DataVencimento on balance
        $balanceItem = Get-PnPListItem -List "Saldo_Ferias" -PageSize 100 |
            Where-Object { $_.FieldValues["ColaboradorEmail"] -eq $TestEmail } |
            Select-Object -First 1

        if ($balanceItem) {
            # Restore DataVencimento based on hiring date anniversary
            $empInfo2 = Get-PnPListItem -List "Colaboradores_Aprovadores" -PageSize 100 |
                Where-Object { $_.FieldValues["Email"] -eq $TestEmail } |
                Select-Object -First 1
            
            $anoRef = $balanceItem.FieldValues["AnoReferencia"]
            $hireDate = if ($empInfo2) { $empInfo2.FieldValues["DataAdmissao"] } else { $null }
            
            if ($hireDate -and $anoRef) {
                $hd = [DateTime]$hireDate
                $deadlineYear = [int]$anoRef + 1
                $hireMonth = $hd.Month
                $hireDay = $hd.Day
                if ($hireMonth -eq 2 -and $hireDay -eq 29 -and -not [DateTime]::IsLeapYear($deadlineYear)) {
                    $hireDay = 28
                }
                $originalVencimento = (Get-Date -Year $deadlineYear -Month $hireMonth -Day $hireDay -Hour 0 -Minute 0 -Second 0).ToString("yyyy-MM-ddT00:00:00Z")
            }
            else {
                $originalVencimento = "$((Get-Date).Year + 1)-06-15T00:00:00Z"
            }

            Set-PnPListItem -List "Saldo_Ferias" -Identity $balanceItem.Id -Values @{
                "DataVencimento" = $originalVencimento
            } | Out-Null
            Write-Host "  [OK] DataVencimento restaurado → $originalVencimento" -ForegroundColor Green
        }

        # Remove test alerts (created today)
        $todayAlerts = Get-PnPListItem -List "Alertas_Ferias" -PageSize 100 |
            Where-Object { 
                $dataEnvio = $_.FieldValues["DataEnvio"]
                if ($dataEnvio) {
                    ([DateTime]$dataEnvio).Date -eq (Get-Date).Date
                }
            }

        foreach ($alert in $todayAlerts) {
            Remove-PnPListItem -List "Alertas_Ferias" -Identity $alert.Id -Force
            Write-Host "  [OK] Alerta removido — ID: $($alert.Id)" -ForegroundColor Green
        }

        Write-Host ""
        Write-Host "[CLEANUP] Concluído!" -ForegroundColor Green
    }
}

Write-Host ""
Disconnect-PnPOnline
