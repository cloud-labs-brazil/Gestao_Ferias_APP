<#
.SYNOPSIS
    Diagnostic: List available Power Automate connections in the environment
.DESCRIPTION
    Discovers actual connection GUIDs for SharePoint, Approvals, Teams, Outlook.
    These GUIDs are needed for the VacationApproval flow deployment.
#>

param(
    [string]$EnvironmentFilter = "ColOfertasBrasilPro"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=== Connection Discovery Diagnostic ===" -ForegroundColor Cyan
Write-Host ""

# ── Auth: Same pattern as 06-Deploy script ──

$clientId    = "1950a258-227b-4e31-a9cf-717495945fc2"
$resource    = "https://service.flow.microsoft.com/"
$redirectUri = "urn:ietf:wg:oauth:2.0:oob"
$tenantId    = "common"

$authUrl = "https://login.microsoftonline.com/$tenantId/oauth2/authorize" +
           "?client_id=$clientId" +
           "&response_type=code" +
           "&redirect_uri=$([uri]::EscapeDataString($redirectUri))" +
           "&resource=$([uri]::EscapeDataString($resource))" +
           "&prompt=none"

Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
Add-Type -AssemblyName System.Web -ErrorAction SilentlyContinue

$form = New-Object System.Windows.Forms.Form
$form.Text = "Sign in - Diagnostic"
$form.Width = 600
$form.Height = 700
$form.StartPosition = "CenterScreen"
$form.TopMost = $true

$wb = New-Object System.Windows.Forms.WebBrowser
$wb.Dock = "Fill"
$wb.ScriptErrorsSuppressed = $true

$authCode = $null
$needsRetry = $false

$wb.Add_Navigated({
    $navUrl = $wb.Url.AbsoluteUri
    if ($navUrl -match "code=([^&]+)") {
        $script:authCode = $matches[1]
        $form.Close()
    }
    if ($navUrl -match "error=") {
        if ($navUrl -match "login_required" -or $navUrl -match "interaction_required") {
            $script:needsRetry = $true
        }
        $form.Close()
    }
})

$form.Controls.Add($wb)
$wb.Navigate($authUrl)
[System.Windows.Forms.Application]::Run($form)

# Retry with interactive prompt if silent failed
if (-not $authCode -and $needsRetry) {
    Write-Host "  Silent auth failed, opening interactive login..." -ForegroundColor Yellow
    $authUrl2 = "https://login.microsoftonline.com/$tenantId/oauth2/authorize" +
                "?client_id=$clientId" +
                "&response_type=code" +
                "&redirect_uri=$([uri]::EscapeDataString($redirectUri))" +
                "&resource=$([uri]::EscapeDataString($resource))" +
                "&prompt=select_account"

    $form2 = New-Object System.Windows.Forms.Form
    $form2.Text = "Sign in - Diagnostic"
    $form2.Width = 600; $form2.Height = 700
    $form2.StartPosition = "CenterScreen"; $form2.TopMost = $true

    $wb2 = New-Object System.Windows.Forms.WebBrowser
    $wb2.Dock = "Fill"; $wb2.ScriptErrorsSuppressed = $true

    $wb2.Add_Navigated({
        $navUrl2 = $wb2.Url.AbsoluteUri
        if ($navUrl2 -match "code=([^&]+)") {
            $script:authCode = $matches[1]
            $form2.Close()
        }
        if ($navUrl2 -match "error=") { $form2.Close() }
    })

    $form2.Controls.Add($wb2)
    $wb2.Navigate($authUrl2)
    [System.Windows.Forms.Application]::Run($form2)
}

if (-not $authCode) {
    Write-Host "  AUTH FAILED" -ForegroundColor Red
    exit 1
}

$tokenBody = @{
    grant_type   = "authorization_code"
    client_id    = $clientId
    code         = $authCode
    redirect_uri = $redirectUri
    resource     = $resource
}

$tokenResp = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/common/oauth2/token" -Body $tokenBody
$flowToken = $tokenResp.access_token
Write-Host "[OK] Authenticated" -ForegroundColor Green

$headers = @{ "Authorization" = "Bearer $flowToken" }

# ── Find environment ──

Write-Host ""
Write-Host "=== Environment ===" -ForegroundColor Cyan
$envResp = Invoke-RestMethod -Method Get -Uri "https://api.flow.microsoft.com/providers/Microsoft.ProcessSimple/environments?api-version=2016-11-01" -Headers $headers
$targetEnv = $envResp.value | Where-Object { $_.properties.displayName -like "*$EnvironmentFilter*" } | Select-Object -First 1
$envId = $targetEnv.name
Write-Host "  $($targetEnv.properties.displayName) -> $envId" -ForegroundColor Green

# ── List connections using ProcessSimple API ──

Write-Host ""
Write-Host "=== All Connections in Environment ===" -ForegroundColor Cyan

$allConnUri = "https://api.flow.microsoft.com/providers/Microsoft.ProcessSimple/environments/$envId/connections?api-version=2016-11-01"
try {
    $allConns = Invoke-RestMethod -Method Get -Uri $allConnUri -Headers $headers
    Write-Host "  Total connections found: $($allConns.value.Count)" -ForegroundColor White
    Write-Host ""
    
    foreach ($conn in $allConns.value) {
        $apiName = ""
        if ($conn.properties.apiId) {
            $apiName = ($conn.properties.apiId -split "/")[-1]
        }
        $status = "Unknown"
        if ($conn.properties.statuses -and $conn.properties.statuses.Count -gt 0) {
            $status = $conn.properties.statuses[0].status
        }
        $displayName = $conn.properties.displayName
        if (-not $displayName) { $displayName = "(none)" }
        
        Write-Host "  Connector: $apiName" -ForegroundColor Yellow -NoNewline
        Write-Host "  ID: $($conn.name)" -ForegroundColor Gray -NoNewline
        Write-Host "  Status: $status" -ForegroundColor $(if ($status -eq "Connected") { "Green" } else { "Red" }) -NoNewline
        Write-Host "  DisplayName: $displayName" -ForegroundColor White
    }
}
catch {
    Write-Host "  Error listing connections: $($_.Exception.Message)" -ForegroundColor Red
    
    # Fallback: try per-connector
    Write-Host ""
    Write-Host "  Trying per-connector API..." -ForegroundColor Yellow
    
    $connectors = @("shared_sharepointonline","shared_approvals","shared_teams","shared_office365")
    foreach ($c in $connectors) {
        Write-Host ""
        Write-Host "  --- $c ---" -ForegroundColor Yellow
        
        $perConnUri = "https://api.flow.microsoft.com/providers/Microsoft.PowerApps/apis/$c/connections?api-version=2016-11-01&`$filter=environment eq '$envId'"
        try {
            $perResp = Invoke-RestMethod -Method Get -Uri $perConnUri -Headers $headers
            Write-Host "    Found: $($perResp.value.Count) connection(s)" -ForegroundColor Green
            foreach ($conn in $perResp.value) {
                $status = "Unknown"
                if ($conn.properties.statuses -and $conn.properties.statuses.Count -gt 0) {
                    $status = $conn.properties.statuses[0].status
                }
                Write-Host "    ID: $($conn.name)  Status: $status" -ForegroundColor Gray
            }
        }
        catch {
            Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# ── Save results for deployment script ──
Write-Host ""
Write-Host "=== Summary for Deployment ===" -ForegroundColor Cyan

$outputMap = @{}
$connectors = @("shared_sharepointonline","shared_approvals","shared_teams","shared_office365")

foreach ($c in $connectors) {
    $match = $allConns.value | Where-Object {
        $_.properties.apiId -like "*/$c"
    } | Where-Object {
        $_.properties.statuses -and $_.properties.statuses[0].status -eq "Connected"
    } | Select-Object -First 1
    
    if ($match) {
        $outputMap[$c] = $match.name
        Write-Host "  $c -> $($match.name) [Connected]" -ForegroundColor Green
    } else {
        Write-Host "  $c -> NOT FOUND (you need to create this connection)" -ForegroundColor Red
    }
}

# Save to JSON for the deploy script to consume
$outputPath = Join-Path $PSScriptRoot "flows\ConnectionMap.json"
$outputMap | ConvertTo-Json | Set-Content $outputPath -Encoding UTF8
Write-Host ""
Write-Host "  Saved to: flows/ConnectionMap.json" -ForegroundColor Gray
Write-Host ""
Write-Host "Done!" -ForegroundColor Green
