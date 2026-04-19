<#
.SYNOPSIS
    List connections available in the Power Automate environment
.DESCRIPTION
    Uses the Flow API to list connections for the current user
#>

param(
    [string]$SiteUrl = "https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA",
    [string]$EnvironmentFilter = "ColOfertasBrasilPro"
)

$ErrorActionPreference = "Stop"

# ── AUTH ──
Write-Host "Authenticating via PnP PowerShell..." -ForegroundColor Cyan
Connect-PnPOnline -Url $SiteUrl -UseWebLogin

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
$form.Text = "Sign in - Power Automate API"
$form.Width = 600; $form.Height = 700
$form.StartPosition = "CenterScreen"; $form.TopMost = $true

$browser = New-Object System.Windows.Forms.WebBrowser
$browser.Dock = "Fill"; $browser.ScriptErrorsSuppressed = $true

$authCode = $null; $needsRetry = $false

$browser.Add_Navigated({
    $url = $browser.Url.AbsoluteUri
    if ($url -match "code=([^&]+)") { $script:authCode = $matches[1]; $form.Close() }
    if ($url -match "error=") {
        if ($url -match "login_required" -or $url -match "interaction_required") { $script:needsRetry = $true }
        $form.Close()
    }
})

$form.Controls.Add($browser)
$browser.Navigate($authUrl)
[System.Windows.Forms.Application]::Run($form)

if (-not $authCode -and $needsRetry) {
    $authUrl2 = "https://login.microsoftonline.com/$tenantId/oauth2/authorize" +
                "?client_id=$clientId" +
                "&response_type=code" +
                "&redirect_uri=$([uri]::EscapeDataString($redirectUri))" +
                "&resource=$([uri]::EscapeDataString($resource))" +
                "&prompt=select_account"
    $form2 = New-Object System.Windows.Forms.Form
    $form2.Text = "Sign in"; $form2.Width = 600; $form2.Height = 700
    $form2.StartPosition = "CenterScreen"; $form2.TopMost = $true
    $browser2 = New-Object System.Windows.Forms.WebBrowser
    $browser2.Dock = "Fill"; $browser2.ScriptErrorsSuppressed = $true
    $browser2.Add_Navigated({
        $url2 = $browser2.Url.AbsoluteUri
        if ($url2 -match "code=([^&]+)") { $script:authCode = $matches[1]; $form2.Close() }
        if ($url2 -match "error=") { $form2.Close() }
    })
    $form2.Controls.Add($browser2)
    $browser2.Navigate($authUrl2)
    [System.Windows.Forms.Application]::Run($form2)
}

if (-not $authCode) { Write-Host "Auth failed" -ForegroundColor Red; exit 1 }

$tokenBody = @{
    grant_type   = "authorization_code"
    client_id    = $clientId
    code         = $authCode
    redirect_uri = $redirectUri
    resource     = $resource
}
$tokenResp = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenantId/oauth2/token" -Body $tokenBody
$flowToken = $tokenResp.access_token
$headers = @{ "Authorization" = "Bearer $flowToken"; "Content-Type" = "application/json" }

Write-Host "[OK] Authenticated" -ForegroundColor Green

# ── FIND ENV ──
$envUri = "https://api.flow.microsoft.com/providers/Microsoft.ProcessSimple/environments?api-version=2016-11-01"
$envResp = Invoke-RestMethod -Method Get -Uri $envUri -Headers $headers
$targetEnv = $envResp.value | Where-Object { $_.properties.displayName -like "*$EnvironmentFilter*" } | Select-Object -First 1
$envId = $targetEnv.name
Write-Host "Environment: $($targetEnv.properties.displayName) ($envId)" -ForegroundColor Green

# ── LIST CONNECTIONS ──
Write-Host ""
Write-Host "Listing connections in environment..." -ForegroundColor Cyan

# PowerApps connections API
$connUri = "https://api.powerapps.com/providers/Microsoft.PowerApps/connections?api-version=2016-11-01&`$filter=environment eq '$envId'"
try {
    $connResp = Invoke-RestMethod -Method Get -Uri $connUri -Headers $headers
    Write-Host "Found $($connResp.value.Count) connections:" -ForegroundColor Green
    foreach ($conn in $connResp.value) {
        $apiName = $conn.properties.apiId -replace ".*/", ""
        $status = $conn.properties.statuses | ForEach-Object { $_.status } | Select-Object -First 1
        Write-Host "  [$status] $apiName -> $($conn.name)" -ForegroundColor White
    }
} catch {
    Write-Host "PowerApps API failed, trying Flow API..." -ForegroundColor Yellow

    # Also try the standard Flow connections endpoint
    $connUri2 = "https://api.flow.microsoft.com/providers/Microsoft.ProcessSimple/environments/$envId/connections?api-version=2016-11-01"
    try {
        $connResp2 = Invoke-RestMethod -Method Get -Uri $connUri2 -Headers $headers
        Write-Host "Found $($connResp2.value.Count) connections:" -ForegroundColor Green
        foreach ($conn in $connResp2.value) {
            $apiName = $conn.properties.apiId -replace ".*/", ""
            $status = $conn.properties.statuses | ForEach-Object { $_.status } | Select-Object -First 1
            Write-Host "  [$status] $apiName -> $($conn.name)" -ForegroundColor White
        }
    } catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Also list existing flows
Write-Host ""
Write-Host "Listing flows with 'Gestao' or 'Vacation' in name..." -ForegroundColor Cyan
$flowsUri = "https://api.flow.microsoft.com/providers/Microsoft.ProcessSimple/environments/$envId/flows?api-version=2016-11-01"
$flowsResp = Invoke-RestMethod -Method Get -Uri $flowsUri -Headers $headers
$matching = $flowsResp.value | Where-Object { $_.properties.displayName -match "Gestao|Vacation|Ferias" }
foreach ($f in $matching) {
    Write-Host "  [$($f.properties.state)] $($f.properties.displayName) -> $($f.name)" -ForegroundColor White
}
if (-not $matching) {
    Write-Host "  (no matching flows found)" -ForegroundColor Gray
}

Disconnect-PnPOnline -ErrorAction SilentlyContinue
