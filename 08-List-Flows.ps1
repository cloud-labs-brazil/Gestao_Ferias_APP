<#
.SYNOPSIS
    List existing flows in the environment and export one definition for reference
#>

param(
    [string]$EnvironmentFilter = "ColOfertasBrasilPro"
)

$ErrorActionPreference = "Stop"

# ── Auth ──
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

$form = New-Object System.Windows.Forms.Form
$form.Text = "Sign in"; $form.Width = 600; $form.Height = 700; $form.StartPosition = "CenterScreen"; $form.TopMost = $true
$wb = New-Object System.Windows.Forms.WebBrowser
$wb.Dock = "Fill"; $wb.ScriptErrorsSuppressed = $true

$authCode = $null; $needsRetry = $false
$wb.Add_Navigated({
    $navUrl = $wb.Url.AbsoluteUri
    if ($navUrl -match "code=([^&]+)") { $script:authCode = $matches[1]; $form.Close() }
    if ($navUrl -match "error=") {
        if ($navUrl -match "login_required|interaction_required") { $script:needsRetry = $true }
        $form.Close()
    }
})
$form.Controls.Add($wb); $wb.Navigate($authUrl)
[System.Windows.Forms.Application]::Run($form)

if (-not $authCode -and $needsRetry) {
    $authUrl2 = $authUrl.Replace("prompt=none","prompt=select_account")
    $form2 = New-Object System.Windows.Forms.Form
    $form2.Text = "Sign in"; $form2.Width = 600; $form2.Height = 700; $form2.StartPosition = "CenterScreen"; $form2.TopMost = $true
    $wb2 = New-Object System.Windows.Forms.WebBrowser
    $wb2.Dock = "Fill"; $wb2.ScriptErrorsSuppressed = $true
    $wb2.Add_Navigated({
        $navUrl2 = $wb2.Url.AbsoluteUri
        if ($navUrl2 -match "code=([^&]+)") { $script:authCode = $matches[1]; $form2.Close() }
        if ($navUrl2 -match "error=") { $form2.Close() }
    })
    $form2.Controls.Add($wb2); $wb2.Navigate($authUrl2)
    [System.Windows.Forms.Application]::Run($form2)
}

if (-not $authCode) { Write-Host "AUTH FAILED" -ForegroundColor Red; exit 1 }

$tokenBody = @{ grant_type="authorization_code"; client_id=$clientId; code=$authCode; redirect_uri=$redirectUri; resource=$resource }
$tokenResp = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/common/oauth2/token" -Body $tokenBody
$flowToken = $tokenResp.access_token
$headers = @{ "Authorization" = "Bearer $flowToken" }
Write-Host "[OK] Authenticated" -ForegroundColor Green

# ── Find env ──
$envResp = Invoke-RestMethod -Method Get -Uri "https://api.flow.microsoft.com/providers/Microsoft.ProcessSimple/environments?api-version=2016-11-01" -Headers $headers
$targetEnv = $envResp.value | Where-Object { $_.properties.displayName -like "*$EnvironmentFilter*" } | Select-Object -First 1
$envId = $targetEnv.name
Write-Host "Env: $($targetEnv.properties.displayName)" -ForegroundColor Green

# ── List flows ──
Write-Host ""
Write-Host "=== Flows in environment ===" -ForegroundColor Cyan

$flowsUri = "https://api.flow.microsoft.com/providers/Microsoft.ProcessSimple/environments/$envId/flows?api-version=2016-11-01"
try {
    $flowsResp = Invoke-RestMethod -Method Get -Uri $flowsUri -Headers $headers
    Write-Host "Total flows: $($flowsResp.value.Count)" -ForegroundColor White
    
    foreach ($f in $flowsResp.value) {
        $state = $f.properties.state
        $displayName = $f.properties.displayName
        $stateColor = if ($state -eq "Started") { "Green" } else { "Yellow" }
        Write-Host "  [$state] $displayName (ID: $($f.name))" -ForegroundColor $stateColor
    }
    
    # Export first flow's full definition as reference
    if ($flowsResp.value.Count -gt 0) {
        $firstFlow = $flowsResp.value[0]
        $flowDetailUri = "https://api.flow.microsoft.com/providers/Microsoft.ProcessSimple/environments/$envId/flows/$($firstFlow.name)?api-version=2016-11-01"
        $flowDetail = Invoke-RestMethod -Method Get -Uri $flowDetailUri -Headers $headers
        
        $outputPath = Join-Path $PSScriptRoot "flows\ReferenceFlow_Export.json"
        $flowDetail | ConvertTo-Json -Depth 100 | Set-Content $outputPath -Encoding UTF8
        Write-Host ""
        Write-Host "Exported reference flow to: flows/ReferenceFlow_Export.json" -ForegroundColor Green
        Write-Host "  Name: $($firstFlow.properties.displayName)" -ForegroundColor Gray
    }
}
catch {
    Write-Host "Error listing flows: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
}
