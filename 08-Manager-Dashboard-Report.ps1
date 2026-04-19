<#
.SYNOPSIS
    Manager Dashboard Report - Team Vacation Status
.DESCRIPTION
    Queries SharePoint lists and generates a beautiful HTML report showing:
    - Pending approvals requiring action
    - Approved/Scheduled vacations (upcoming)
    - Team balance overview
    - Monthly calendar heatmap
.EXAMPLE
    .\08-Manager-Dashboard-Report.ps1
    .\08-Manager-Dashboard-Report.ps1 -ManagerEmail "mbenicios@minsait.com"
    .\08-Manager-Dashboard-Report.ps1 -OpenInBrowser
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$SiteUrl = "https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA",

    [Parameter(Mandatory = $false)]
    [string]$ManagerEmail = "mbenicios@minsait.com",

    [Parameter(Mandatory = $false)]
    [switch]$OpenInBrowser
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
Write-Host "  GESTAO FERIAS - MANAGER DASHBOARD REPORT" -ForegroundColor Cyan
Write-Host "  Team Vacation Status Overview" -ForegroundColor Cyan
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Manager: $ManagerEmail" -ForegroundColor Gray
Write-Host ""

# ── CONNECT ──
Write-Host "[1/4] Connecting to SharePoint..." -ForegroundColor Yellow
Connect-PnPOnline -Url $SiteUrl -UseWebLogin
Write-Host "  [OK] Connected!" -ForegroundColor Green
Write-Host ""

# ── FETCH DATA ──
Write-Host "[2/4] Fetching team data..." -ForegroundColor Yellow

# Get team members (employees where this manager is the approver)
$allColabs = Get-PnPListItem -List "Colaboradores_Aprovadores" -PageSize 200
$teamMembers = $allColabs | Where-Object {
    $_.FieldValues["AprovadorEmail"] -eq $ManagerEmail -and $_.FieldValues["Ativo"] -eq $true
}
Write-Host "  Team members: $(@($teamMembers).Count)" -ForegroundColor Green

# Get all vacation requests
$allRequests = Get-PnPListItem -List "Solicitacoes_Ferias" -PageSize 500
# Filter to team members
$teamEmails = @($teamMembers | ForEach-Object { $_.FieldValues["Email"] })
$teamRequests = $allRequests | Where-Object {
    $_.FieldValues["ColaboradorEmail"] -in $teamEmails
}
Write-Host "  Team requests: $(@($teamRequests).Count)" -ForegroundColor Green

# Get balances
$allBalances = Get-PnPListItem -List "Saldo_Ferias" -PageSize 200
$teamBalances = $allBalances | Where-Object {
    $_.FieldValues["ColaboradorEmail"] -in $teamEmails
}
Write-Host "  Balance records: $(@($teamBalances).Count)" -ForegroundColor Green

# Get holidays
$holidays = Get-PnPListItem -List "Feriados" -PageSize 100
Write-Host "  Holidays: $(@($holidays).Count)" -ForegroundColor Green
Write-Host ""

# ── PROCESS DATA ──
Write-Host "[3/4] Processing report data..." -ForegroundColor Yellow

$today = Get-Date
$reportDate = Get-Date -Format "dd/MM/yyyy HH:mm"

# Categorize requests
$pendingRequests = @($teamRequests | Where-Object { $_.FieldValues["Status"] -eq "PENDING" })
$approvedRequests = @($teamRequests | Where-Object { $_.FieldValues["Status"] -eq "APPROVED" })
$rejectedRequests = @($teamRequests | Where-Object { $_.FieldValues["Status"] -eq "REJECTED" })
$cancelledRequests = @($teamRequests | Where-Object { $_.FieldValues["Status"] -eq "CANCELLED" })

# Upcoming approved vacations (start date >= today)
$upcomingVacations = @($approvedRequests | Where-Object {
    $startDate = $_.FieldValues["DataInicio"]
    if ($startDate) { [DateTime]$startDate -ge $today.Date } else { $false }
} | Sort-Object { [DateTime]$_.FieldValues["DataInicio"] })

# Currently on vacation
$onVacationNow = @($approvedRequests | Where-Object {
    $startDate = $_.FieldValues["DataInicio"]
    $endDate = $_.FieldValues["DataFim"]
    if ($startDate -and $endDate) {
        [DateTime]$startDate -le $today.Date -and [DateTime]$endDate -ge $today.Date
    } else { $false }
})

Write-Host "  Pending approvals:   $($pendingRequests.Count)" -ForegroundColor $(if ($pendingRequests.Count -gt 0) { "Yellow" } else { "Green" })
Write-Host "  On vacation now:     $($onVacationNow.Count)" -ForegroundColor Cyan
Write-Host "  Upcoming scheduled:  $($upcomingVacations.Count)" -ForegroundColor Green
Write-Host "  Total approved:      $($approvedRequests.Count)" -ForegroundColor Green
Write-Host "  Rejected:            $($rejectedRequests.Count)" -ForegroundColor DarkGray
Write-Host "  Cancelled:           $($cancelledRequests.Count)" -ForegroundColor DarkGray
Write-Host ""

# ── BUILD HTML REPORT ──
Write-Host "[4/4] Generating HTML report..." -ForegroundColor Yellow

# Build pending rows
$pendingRowsHtml = ""
foreach ($req in $pendingRequests) {
    $name = $req.FieldValues["ColaboradorNome"]
    $email = $req.FieldValues["ColaboradorEmail"]
    $start = if ($req.FieldValues["DataInicio"]) { ([DateTime]$req.FieldValues["DataInicio"]).ToString("dd/MM/yyyy") } else { "-" }
    $end = if ($req.FieldValues["DataFim"]) { ([DateTime]$req.FieldValues["DataFim"]).ToString("dd/MM/yyyy") } else { "-" }
    $days = $req.FieldValues["DiasUteis"]
    $created = if ($req.FieldValues["Created"]) { ([DateTime]$req.FieldValues["Created"]).ToString("dd/MM HH:mm") } else { "-" }
    $obs = $req.FieldValues["Observacoes"]
    if (-not $obs) { $obs = "" }
    $pendingRowsHtml += @"
                <tr>
                    <td><strong>$name</strong><br><small style="color:#888">$email</small></td>
                    <td>$start</td>
                    <td>$end</td>
                    <td><span class="badge badge-info">$days dias</span></td>
                    <td>$created</td>
                    <td><span class="badge badge-warning">PENDING</span></td>
                </tr>
"@
}
if ($pendingRequests.Count -eq 0) {
    $pendingRowsHtml = '<tr><td colspan="6" style="text-align:center;color:#666;padding:20px;">Nenhuma solicitação pendente 🎉</td></tr>'
}

# Build upcoming vacations rows
$upcomingRowsHtml = ""
foreach ($req in $upcomingVacations) {
    $name = $req.FieldValues["ColaboradorNome"]
    $email = $req.FieldValues["ColaboradorEmail"]
    $start = if ($req.FieldValues["DataInicio"]) { ([DateTime]$req.FieldValues["DataInicio"]).ToString("dd/MM/yyyy") } else { "-" }
    $end = if ($req.FieldValues["DataFim"]) { ([DateTime]$req.FieldValues["DataFim"]).ToString("dd/MM/yyyy") } else { "-" }
    $days = $req.FieldValues["DiasUteis"]
    $daysUntil = if ($req.FieldValues["DataInicio"]) { ([DateTime]$req.FieldValues["DataInicio"] - $today).Days } else { 0 }
    $urgencyClass = if ($daysUntil -le 7) { "badge-danger" } elseif ($daysUntil -le 30) { "badge-warning" } else { "badge-success" }
    $upcomingRowsHtml += @"
                <tr>
                    <td><strong>$name</strong><br><small style="color:#888">$email</small></td>
                    <td>$start</td>
                    <td>$end</td>
                    <td><span class="badge badge-info">$days dias</span></td>
                    <td><span class="badge $urgencyClass">em $daysUntil dias</span></td>
                </tr>
"@
}
if ($upcomingVacations.Count -eq 0) {
    $upcomingRowsHtml = '<tr><td colspan="5" style="text-align:center;color:#666;padding:20px;">Nenhuma ferias agendada</td></tr>'
}

# Build on vacation now rows
$onVacationHtml = ""
foreach ($req in $onVacationNow) {
    $name = $req.FieldValues["ColaboradorNome"]
    $end = if ($req.FieldValues["DataFim"]) { ([DateTime]$req.FieldValues["DataFim"]).ToString("dd/MM/yyyy") } else { "-" }
    $daysLeft = if ($req.FieldValues["DataFim"]) { ([DateTime]$req.FieldValues["DataFim"] - $today).Days } else { 0 }
    $onVacationHtml += @"
                <div class="vacation-card">
                    <div class="vacation-avatar">🏖️</div>
                    <div>
                        <strong>$name</strong><br>
                        <small>Retorna em $end ($daysLeft dias)</small>
                    </div>
                </div>
"@
}
if ($onVacationNow.Count -eq 0) {
    $onVacationHtml = '<div style="text-align:center;color:#888;padding:20px;">Todo o time presente hoje ✅</div>'
}

# Build balance table rows
$balanceRowsHtml = ""
foreach ($member in $teamMembers) {
    $email = $member.FieldValues["Email"]
    $name = $member.FieldValues["NomeCompleto"]
    $dept = $member.FieldValues["Departamento"]
    
    $bal = $teamBalances | Where-Object { $_.FieldValues["ColaboradorEmail"] -eq $email } | Select-Object -First 1
    $available = if ($bal) { $bal.FieldValues["SaldoDisponivel"] } else { "?" }
    $period = if ($bal) { $bal.FieldValues["PeriodoAquisitivo"] } else { "-" }
    $expiry = if ($bal -and $bal.FieldValues["DataVencimento"]) { ([DateTime]$bal.FieldValues["DataVencimento"]).ToString("dd/MM/yyyy") } else { "-" }
    
    # Balance color
    $balClass = if ($available -eq "?") { "badge-dark" } elseif ([int]$available -le 5) { "badge-danger" } elseif ([int]$available -le 15) { "badge-warning" } else { "badge-success" }
    
    # Check if has pending request
    $hasPending = $pendingRequests | Where-Object { $_.FieldValues["ColaboradorEmail"] -eq $email }
    $statusIcon = if ($hasPending) { "⏳" } elseif ($onVacationNow | Where-Object { $_.FieldValues["ColaboradorEmail"] -eq $email }) { "🏖️" } else { "✅" }
    
    $balanceRowsHtml += @"
                <tr>
                    <td>$statusIcon</td>
                    <td><strong>$name</strong><br><small style="color:#888">$dept</small></td>
                    <td><span class="badge $balClass">$available dias</span></td>
                    <td><small>$period</small></td>
                    <td><small>$expiry</small></td>
                </tr>
"@
}

# Build full history rows (last 20)
$historyRequests = @($teamRequests | Sort-Object { $_.FieldValues["Created"] } -Descending | Select-Object -First 20)
$historyRowsHtml = ""
foreach ($req in $historyRequests) {
    $name = $req.FieldValues["ColaboradorNome"]
    $start = if ($req.FieldValues["DataInicio"]) { ([DateTime]$req.FieldValues["DataInicio"]).ToString("dd/MM/yyyy") } else { "-" }
    $end = if ($req.FieldValues["DataFim"]) { ([DateTime]$req.FieldValues["DataFim"]).ToString("dd/MM/yyyy") } else { "-" }
    $days = $req.FieldValues["DiasUteis"]
    $status = $req.FieldValues["Status"]
    $statusClass = switch ($status) {
        "PENDING"   { "badge-warning" }
        "APPROVED"  { "badge-success" }
        "REJECTED"  { "badge-danger" }
        "CANCELLED" { "badge-dark" }
        default     { "badge-info" }
    }
    $created = if ($req.FieldValues["Created"]) { ([DateTime]$req.FieldValues["Created"]).ToString("dd/MM/yyyy") } else { "-" }
    $historyRowsHtml += @"
                <tr>
                    <td>$name</td>
                    <td>$start → $end</td>
                    <td>$days</td>
                    <td><span class="badge $statusClass">$status</span></td>
                    <td><small>$created</small></td>
                </tr>
"@
}

# Manager name lookup
$managerRecord = $allColabs | Where-Object { $_.FieldValues["Email"] -eq $ManagerEmail } | Select-Object -First 1
$managerName = if ($managerRecord) { $managerRecord.FieldValues["NomeCompleto"] } else { $ManagerEmail }

$html = @"
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gestao Ferias - Dashboard do Gestor</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, sans-serif;
            background: linear-gradient(135deg, #0f0c29, #302b63, #24243e);
            min-height: 100vh;
            color: #e0e0e0;
        }

        .header {
            background: rgba(255,255,255,0.05);
            backdrop-filter: blur(20px);
            border-bottom: 1px solid rgba(255,255,255,0.1);
            padding: 20px 40px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .header h1 {
            font-size: 1.5rem;
            font-weight: 600;
            background: linear-gradient(90deg, #667eea, #764ba2);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .header .meta {
            font-size: 0.85rem;
            color: #888;
        }

        .container { max-width: 1400px; margin: 0 auto; padding: 30px 40px; }

        /* KPI Cards */
        .kpi-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }

        .kpi-card {
            background: rgba(255,255,255,0.06);
            border: 1px solid rgba(255,255,255,0.1);
            border-radius: 16px;
            padding: 24px;
            text-align: center;
            backdrop-filter: blur(10px);
            transition: transform 0.2s, box-shadow 0.2s;
        }

        .kpi-card:hover {
            transform: translateY(-4px);
            box-shadow: 0 8px 30px rgba(102, 126, 234, 0.2);
        }

        .kpi-card .kpi-value {
            font-size: 2.5rem;
            font-weight: 700;
            margin-bottom: 4px;
        }

        .kpi-card .kpi-label {
            font-size: 0.85rem;
            color: #999;
            text-transform: uppercase;
            letter-spacing: 1px;
        }

        .kpi-pending .kpi-value { color: #f0ad4e; }
        .kpi-vacation .kpi-value { color: #5bc0de; }
        .kpi-scheduled .kpi-value { color: #5cb85c; }
        .kpi-team .kpi-value { color: #667eea; }
        .kpi-approved .kpi-value { color: #22c55e; }
        .kpi-rejected .kpi-value { color: #ef4444; }

        /* Sections */
        .section {
            background: rgba(255,255,255,0.04);
            border: 1px solid rgba(255,255,255,0.08);
            border-radius: 16px;
            margin-bottom: 24px;
            overflow: hidden;
        }

        .section-header {
            padding: 16px 24px;
            border-bottom: 1px solid rgba(255,255,255,0.08);
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .section-header h2 {
            font-size: 1.1rem;
            font-weight: 600;
        }

        .section-header .section-count {
            background: rgba(255,255,255,0.1);
            padding: 2px 10px;
            border-radius: 20px;
            font-size: 0.8rem;
        }

        .section-body { padding: 0; }

        /* Tables */
        table { width: 100%; border-collapse: collapse; }
        
        th {
            text-align: left;
            padding: 12px 16px;
            font-size: 0.75rem;
            text-transform: uppercase;
            letter-spacing: 1px;
            color: #888;
            border-bottom: 1px solid rgba(255,255,255,0.06);
            background: rgba(0,0,0,0.2);
        }

        td {
            padding: 12px 16px;
            border-bottom: 1px solid rgba(255,255,255,0.04);
            font-size: 0.9rem;
        }

        tr:hover { background: rgba(255,255,255,0.03); }

        /* Badges */
        .badge {
            display: inline-block;
            padding: 3px 10px;
            border-radius: 20px;
            font-size: 0.75rem;
            font-weight: 600;
            letter-spacing: 0.5px;
        }

        .badge-warning { background: rgba(240,173,78,0.2); color: #f0ad4e; }
        .badge-success { background: rgba(92,184,92,0.2); color: #5cb85c; }
        .badge-danger  { background: rgba(239,68,68,0.2); color: #ef4444; }
        .badge-info    { background: rgba(91,192,222,0.2); color: #5bc0de; }
        .badge-dark    { background: rgba(255,255,255,0.08); color: #888; }

        /* Vacation cards (on vacation now) */
        .vacation-cards { display: flex; flex-wrap: wrap; gap: 12px; padding: 16px 24px; }
        
        .vacation-card {
            display: flex;
            align-items: center;
            gap: 12px;
            background: rgba(91,192,222,0.1);
            border: 1px solid rgba(91,192,222,0.2);
            border-radius: 12px;
            padding: 12px 16px;
            min-width: 250px;
        }

        .vacation-avatar { font-size: 1.5rem; }

        /* Two column layout */
        .two-col { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; }

        @media (max-width: 900px) {
            .two-col { grid-template-columns: 1fr; }
            .container { padding: 20px; }
            .header { padding: 16px 20px; }
        }

        /* Pending section highlight */
        .section-urgent {
            border-color: rgba(240,173,78,0.3);
            box-shadow: 0 0 20px rgba(240,173,78,0.05);
        }

        .section-urgent .section-header {
            background: rgba(240,173,78,0.08);
        }

        /* Footer */
        .footer {
            text-align: center;
            padding: 30px;
            color: #555;
            font-size: 0.8rem;
        }

        /* Print */
        @media print {
            body { background: white; color: #333; }
            .header { background: #f5f5f5; }
            .section { border: 1px solid #ddd; }
            .kpi-card { border: 1px solid #ddd; }
        }
    </style>
</head>
<body>

<div class="header">
    <div>
        <h1>🏖️ Gestao Ferias — Dashboard do Gestor</h1>
        <div class="meta">$managerName • Equipe Completa</div>
    </div>
    <div class="meta" style="text-align:right">
        Gerado em: $reportDate<br>
        <small>Dados: SharePoint Online</small>
    </div>
</div>

<div class="container">

    <!-- KPI Cards -->
    <div class="kpi-grid">
        <div class="kpi-card kpi-team">
            <div class="kpi-value">$(@($teamMembers).Count)</div>
            <div class="kpi-label">Membros do Time</div>
        </div>
        <div class="kpi-card kpi-pending">
            <div class="kpi-value">$($pendingRequests.Count)</div>
            <div class="kpi-label">Aguardando Aprovação</div>
        </div>
        <div class="kpi-card kpi-vacation">
            <div class="kpi-value">$($onVacationNow.Count)</div>
            <div class="kpi-label">De Férias Agora</div>
        </div>
        <div class="kpi-card kpi-scheduled">
            <div class="kpi-value">$($upcomingVacations.Count)</div>
            <div class="kpi-label">Férias Agendadas</div>
        </div>
        <div class="kpi-card kpi-approved">
            <div class="kpi-value">$($approvedRequests.Count)</div>
            <div class="kpi-label">Total Aprovadas</div>
        </div>
        <div class="kpi-card kpi-rejected">
            <div class="kpi-value">$($rejectedRequests.Count)</div>
            <div class="kpi-label">Rejeitadas</div>
        </div>
    </div>

    <!-- On Vacation Now -->
    <div class="section">
        <div class="section-header">
            <h2>🏖️ De Ferias Agora</h2>
            <span class="section-count">$($onVacationNow.Count)</span>
        </div>
        <div class="section-body">
            <div class="vacation-cards">
                $onVacationHtml
            </div>
        </div>
    </div>

    <!-- Pending Approvals -->
    <div class="section section-urgent">
        <div class="section-header">
            <h2>⏳ Aguardando Sua Aprovação</h2>
            <span class="section-count badge badge-warning">$($pendingRequests.Count)</span>
        </div>
        <div class="section-body">
            <table>
                <thead>
                    <tr>
                        <th>Colaborador</th>
                        <th>Inicio</th>
                        <th>Fim</th>
                        <th>Dias</th>
                        <th>Solicitado em</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                $pendingRowsHtml
                </tbody>
            </table>
        </div>
    </div>

    <div class="two-col">
        <!-- Upcoming Vacations -->
        <div class="section">
            <div class="section-header">
                <h2>📅 Férias Agendadas (Aprovadas)</h2>
                <span class="section-count">$($upcomingVacations.Count)</span>
            </div>
            <div class="section-body">
                <table>
                    <thead>
                        <tr>
                            <th>Colaborador</th>
                            <th>Inicio</th>
                            <th>Fim</th>
                            <th>Dias</th>
                            <th>Começa em</th>
                        </tr>
                    </thead>
                    <tbody>
                    $upcomingRowsHtml
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Team Balances -->
        <div class="section">
            <div class="section-header">
                <h2>💰 Saldo de Férias do Time</h2>
                <span class="section-count">$(@($teamMembers).Count)</span>
            </div>
            <div class="section-body">
                <table>
                    <thead>
                        <tr>
                            <th></th>
                            <th>Colaborador</th>
                            <th>Saldo</th>
                            <th>Período Aquisitivo</th>
                            <th>Vencimento</th>
                        </tr>
                    </thead>
                    <tbody>
                    $balanceRowsHtml
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- Full History -->
    <div class="section">
        <div class="section-header">
            <h2>📋 Histórico Recente (últimas 20)</h2>
        </div>
        <div class="section-body">
            <table>
                <thead>
                    <tr>
                        <th>Colaborador</th>
                        <th>Período</th>
                        <th>Dias</th>
                        <th>Status</th>
                        <th>Criado em</th>
                    </tr>
                </thead>
                <tbody>
                $historyRowsHtml
                </tbody>
            </table>
        </div>
    </div>

</div>

<div class="footer">
    Gestão Férias © 2026 — Minsait / Indra — Gerado automaticamente via PowerShell
</div>

</body>
</html>
"@

# Save report
$reportDir = Join-Path $PSScriptRoot "reports"
if (-not (Test-Path $reportDir)) { New-Item -Path $reportDir -ItemType Directory -Force | Out-Null }

$reportFile = Join-Path $reportDir "dashboard_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
$html | Set-Content -Path $reportFile -Encoding UTF8

Write-Host "  [OK] Report saved!" -ForegroundColor Green
Write-Host ""
Write-Host "==============================================================" -ForegroundColor Green
Write-Host "  REPORT GENERATED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "==============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  File: $reportFile" -ForegroundColor Cyan
Write-Host ""

# Also save as "latest"
$latestFile = Join-Path $reportDir "dashboard_latest.html"
$html | Set-Content -Path $latestFile -Encoding UTF8
Write-Host "  Also saved as: $latestFile" -ForegroundColor Gray
Write-Host ""

if ($OpenInBrowser) {
    Start-Process $reportFile
    Write-Host "  [OK] Opened in default browser" -ForegroundColor Green
} else {
    Write-Host "  TIP: Run with -OpenInBrowser to auto-open" -ForegroundColor Gray
    Write-Host "  Or open: $latestFile" -ForegroundColor Gray
}

Write-Host ""
Disconnect-PnPOnline -ErrorAction SilentlyContinue
Write-Host "[DONE] Disconnected." -ForegroundColor Green
