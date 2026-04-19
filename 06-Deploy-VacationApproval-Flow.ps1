<#
.SYNOPSIS
    Deploy GestaoFerias_VacationApproval Flow to Power Automate
.DESCRIPTION
    Creates the VacationApproval automated cloud flow using the Power Automate API.
    Authentication follows the established PnP PowerShell pattern:
      - Uses SharePointPnPPowerShellOnline 3.29 (PS 5.1)
      - Connect-PnPOnline -UseWebLogin (browser popup)
      - Browser popup fallback for Flow API token
    Loads flow definition from flows/VacationApproval_Definition.json.
.NOTES
    Project: Gestao Ferias (Vacation Management)
    Blueprint: docs/Flow-Blueprint-VacationApproval.md
    Auth: Browser popup via PnP (same as 02-Deploy-Listas.ps1)
#>

param(
    [string]$SiteUrl = "https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA",
    [string]$EnvironmentFilter = "ColOfertasBrasilPro"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  GestaoFerias - VacationApproval Flow Deployment" -ForegroundColor Cyan
Write-Host "  Standard License - SharePoint + Teams Adaptive Cards" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

# ── STEP 1: PnP Authentication (browser popup) ──────
# Same pattern as 02-Deploy-Listas.ps1 and Deploy_CLI_SharePoint.md

Write-Host "[1/4] Authenticating via PnP PowerShell (browser popup)..." -ForegroundColor Cyan
Write-Host "  Module: SharePointPnPPowerShellOnline 3.29" -ForegroundColor Gray
Write-Host "  Method: -UseWebLogin (browser popup)" -ForegroundColor Gray
Write-Host ""

try {
    Connect-PnPOnline -Url $SiteUrl -UseWebLogin
    Write-Host "  [OK] Connected to SharePoint!" -ForegroundColor Green
}
catch {
    Write-Host "  [ERROR] Connection failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Acquire token for Flow API via browser popup
Write-Host "  Acquiring Flow API token via browser popup..." -ForegroundColor Gray

$clientId    = "1950a258-227b-4e31-a9cf-717495945fc2"  # Azure PowerShell well-known app
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
$form.Width = 600
$form.Height = 700
$form.StartPosition = "CenterScreen"
$form.TopMost = $true

$browser = New-Object System.Windows.Forms.WebBrowser
$browser.Dock = "Fill"
$browser.ScriptErrorsSuppressed = $true

$authCode = $null
$needsRetry = $false

$browser.Add_Navigated({
    $url = $browser.Url.AbsoluteUri
    if ($url -match "code=([^&]+)") {
        $script:authCode = $matches[1]
        $form.Close()
    }
    if ($url -match "error=") {
        if ($url -match "login_required" -or $url -match "interaction_required") {
            $script:needsRetry = $true
        }
        $form.Close()
    }
})

$form.Controls.Add($browser)
$browser.Navigate($authUrl)

[System.Windows.Forms.Application]::Run($form)

# If silent auth failed, retry with interactive prompt
if (-not $authCode -and $needsRetry) {
    $authUrl2 = "https://login.microsoftonline.com/$tenantId/oauth2/authorize" +
                "?client_id=$clientId" +
                "&response_type=code" +
                "&redirect_uri=$([uri]::EscapeDataString($redirectUri))" +
                "&resource=$([uri]::EscapeDataString($resource))" +
                "&prompt=select_account"

    $form2 = New-Object System.Windows.Forms.Form
    $form2.Text = "Sign in - Power Automate API"
    $form2.Width = 600
    $form2.Height = 700
    $form2.StartPosition = "CenterScreen"
    $form2.TopMost = $true

    $browser2 = New-Object System.Windows.Forms.WebBrowser
    $browser2.Dock = "Fill"
    $browser2.ScriptErrorsSuppressed = $true

    $browser2.Add_Navigated({
        $url2 = $browser2.Url.AbsoluteUri
        if ($url2 -match "code=([^&]+)") {
            $script:authCode = $matches[1]
            $form2.Close()
        }
        if ($url2 -match "error=") {
            $form2.Close()
        }
    })

    $form2.Controls.Add($browser2)
    $browser2.Navigate($authUrl2)

    Write-Host "  [AUTH] Sign in with mbenicios@minsait.com..." -ForegroundColor Yellow
    [System.Windows.Forms.Application]::Run($form2)
}

if (-not $authCode) {
    Write-Host "  [ERROR] Flow API authentication failed." -ForegroundColor Red
    exit 1
}

# Exchange auth code for token
$tokenBody = @{
    grant_type   = "authorization_code"
    client_id    = $clientId
    code         = $authCode
    redirect_uri = $redirectUri
    resource     = $resource
}

$tokenResp = Invoke-RestMethod -Method Post `
    -Uri "https://login.microsoftonline.com/$tenantId/oauth2/token" `
    -Body $tokenBody

$flowToken = $tokenResp.access_token
Write-Host "  [OK] Flow API token acquired!" -ForegroundColor Green

$headers = @{
    "Authorization" = "Bearer $flowToken"
    "Content-Type"  = "application/json"
}

# ── STEP 2: Find Environment ────────────────────────

Write-Host ""
Write-Host "[2/4] Finding environment '$EnvironmentFilter'..." -ForegroundColor Cyan

$envUri = "https://api.flow.microsoft.com/providers/Microsoft.ProcessSimple/environments?api-version=2016-11-01"
$envResp = Invoke-RestMethod -Method Get -Uri $envUri -Headers $headers

$targetEnv = $envResp.value | Where-Object { $_.properties.displayName -like "*$EnvironmentFilter*" } | Select-Object -First 1

if (-not $targetEnv) {
    Write-Host "  ERROR: Environment not found. Available:" -ForegroundColor Red
    foreach ($e in $envResp.value) {
        Write-Host "    - $($e.properties.displayName)" -ForegroundColor Yellow
    }
    exit 1
}

$envId = $targetEnv.name
Write-Host "  Found: $($targetEnv.properties.displayName) ($envId)" -ForegroundColor Green

# ── STEP 3: Load + Prepare Flow Definition ───────────

Write-Host ""
Write-Host "[3/4] Loading flow definition from JSON..." -ForegroundColor Cyan

$defPath = Join-Path $PSScriptRoot "flows\VacationApproval_Definition.json"
if (-not (Test-Path $defPath)) {
    Write-Host "  ERROR: Flow definition not found at: $defPath" -ForegroundColor Red
    exit 1
}

$flowJson = Get-Content $defPath -Raw -Encoding UTF8

# Replace SharePoint site placeholder
$flowJson = $flowJson.Replace("__SP_SITE__", $SiteUrl)

# Parse JSON
$flowObj = $flowJson | ConvertFrom-Json

# ── Deploy as "Started" since we use real Embedded connection IDs ──
# Connection IDs from the environment are bound via source=Embedded.
# If deployment fails, fallback to Stopped and configure in designer.
$flowObj.properties.state = "Started"
Write-Host "  Flow will be created as STARTED (real connections embedded)" -ForegroundColor Green

$def = $flowObj.properties.definition

# ── PATCH: Add connectionReferences with REAL connection IDs ──
# These IDs were discovered via Flow Management API (_list_connections.ps1).
# Using source=Embedded with actual connection names avoids ConnectionAuthorizationFailed.
$connRefs = [PSCustomObject]@{
    "shared_sharepointonline" = [PSCustomObject]@{
        connectionName = "44f187cde7f54f208cf22bac4e533816"
        source         = "Embedded"
        id             = "/providers/Microsoft.PowerApps/apis/shared_sharepointonline"
        tier           = "NotSpecified"
    }
    "shared_teams" = [PSCustomObject]@{
        connectionName = "shared-teams-1440d346-f1dd-44ea-912f-3787038ac333"
        source         = "Embedded"
        id             = "/providers/Microsoft.PowerApps/apis/shared_teams"
        tier           = "NotSpecified"
    }
    "shared_office365" = [PSCustomObject]@{
        connectionName = "306d783533364cb6948ab2830fc3b188"
        source         = "Embedded"
        id             = "/providers/Microsoft.PowerApps/apis/shared_office365"
        tier           = "NotSpecified"
    }
}
$flowObj.properties | Add-Member -NotePropertyName "connectionReferences" -NotePropertyValue $connRefs -Force
Write-Host "  Added connectionReferences with real connection IDs" -ForegroundColor Green

# ── Check if flow already exists ──
Write-Host "  Checking for existing VacationApproval flow..." -ForegroundColor Gray
$existingFlowId = $null
try {
    $flowListUri = "https://api.flow.microsoft.com/providers/Microsoft.ProcessSimple/environments/$envId/flows?api-version=2016-11-01&`$filter=search('GestaoFerias_VacationApproval')"
    $flowListResp = Invoke-RestMethod -Method Get -Uri $flowListUri -Headers $headers
    $existingFlow = $flowListResp.value | Where-Object { $_.properties.displayName -eq "GestaoFerias_VacationApproval" } | Select-Object -First 1
    if ($existingFlow) {
        $existingFlowId = $existingFlow.name
        Write-Host "  Found existing flow: $existingFlowId (will UPDATE)" -ForegroundColor Yellow
    } else {
        Write-Host "  No existing flow found (will CREATE)" -ForegroundColor Gray
    }
} catch {
    Write-Host "  Could not check existing flows, will CREATE new" -ForegroundColor Gray
}

# ── VERIFY: $authentication parameter is present in definition ──
# The Flow API requires:
# 1. $authentication declared as SecureObject in definition.parameters
# 2. "authentication": "@parameters('$authentication')" in every OpenApiConnection inputs
# Both are now baked into VacationApproval_Definition.json (matching ReferenceFlow pattern).

if ($def.parameters.'$authentication') {
    Write-Host "  [OK] `$authentication parameter found in definition" -ForegroundColor Green
} else {
    Write-Host "  [WARN] Missing `$authentication parameter - adding it now..." -ForegroundColor Yellow
    $def.parameters | Add-Member -NotePropertyName '$authentication' -NotePropertyValue ([PSCustomObject]@{
        defaultValue = [PSCustomObject]@{}
        type = "SecureObject"
    }) -Force
}

# Count OpenApiConnection nodes with authentication
$authCount = 0
function Count-AuthNodes($node) {
    if ($null -eq $node) { return }
    if ($node.type -eq "OpenApiConnection" -and $node.inputs -and $node.inputs.authentication) {
        $script:authCount++
    }
    if ($node.actions) {
        foreach ($prop in $node.actions.PSObject.Properties) { Count-AuthNodes $prop.Value }
    }
    if ($node.else -and $node.else.actions) {
        foreach ($prop in $node.else.actions.PSObject.Properties) { Count-AuthNodes $prop.Value }
    }
}
$trigger = $def.triggers.When_an_item_is_created
if ($trigger.inputs.authentication) { $authCount++ }
foreach ($actionProp in $def.actions.PSObject.Properties) { Count-AuthNodes $actionProp.Value }
Write-Host "  [OK] Found authentication on $authCount OpenApiConnection nodes" -ForegroundColor Green

# Serialize to JSON
$flowBody = $flowObj | ConvertTo-Json -Depth 100 -Compress

# CRITICAL: PowerShell 5.1 Invoke-RestMethod sends body using system ANSI codepage (Windows-1252).
# Portuguese characters (ç, ã, í, ó, etc.) get corrupted → API error "Unable to translate bytes [E7]".
# Fix: explicitly encode as UTF-8 byte array before sending.
$utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($flowBody)

Write-Host "  Definition loaded (SP site: $SiteUrl)" -ForegroundColor Green
Write-Host "  Body size: $($utf8Bytes.Length) bytes (UTF-8)" -ForegroundColor Gray

# ── STEP 4: Create or Update Flow via API ─────────────────────

Write-Host ""
if ($existingFlowId) {
    Write-Host "[4/4] Updating existing flow 'GestaoFerias_VacationApproval'..." -ForegroundColor Cyan
} else {
    Write-Host "[4/4] Creating flow 'GestaoFerias_VacationApproval'..." -ForegroundColor Cyan
}

try {
    if ($existingFlowId) {
        # UPDATE existing flow via PATCH
        $updateUri = "https://api.flow.microsoft.com/providers/Microsoft.ProcessSimple/environments/$envId/flows/$existingFlowId`?api-version=2016-11-01"
        $result = Invoke-RestMethod -Method Patch -Uri $updateUri -Headers $headers -Body $utf8Bytes -ContentType "application/json; charset=utf-8"
    } else {
        # CREATE new flow via POST
        $createUri = "https://api.flow.microsoft.com/providers/Microsoft.ProcessSimple/environments/$envId/flows?api-version=2016-11-01"
        $result = Invoke-RestMethod -Method Post -Uri $createUri -Headers $headers -Body $utf8Bytes -ContentType "application/json; charset=utf-8"
    }

    $flowId = $result.name
    $flowName = $result.properties.displayName

    Write-Host ""
    Write-Host "======================================================" -ForegroundColor Green
    if ($existingFlowId) {
        Write-Host "  FLOW UPDATED SUCCESSFULLY!" -ForegroundColor Green
    } else {
        Write-Host "  FLOW CREATED SUCCESSFULLY!" -ForegroundColor Green
    }
    Write-Host "======================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Name:    $flowName" -ForegroundColor White
    Write-Host "  ID:      $flowId" -ForegroundColor Gray
    Write-Host "  State:   $($result.properties.state)" -ForegroundColor White
    Write-Host ""
    Write-Host "  Open in designer:" -ForegroundColor Yellow
    Write-Host "  https://make.powerautomate.com/environments/$envId/flows/$flowId/details" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  IMPORTANT - Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Open the link above" -ForegroundColor White
    Write-Host "  2. Click 'Edit' to verify connections" -ForegroundColor White
    Write-Host "  3. Turn on the flow if it was deployed as Stopped" -ForegroundColor White
    Write-Host "  4. Test: create a PENDING item in Solicitacoes_Ferias" -ForegroundColor White

    # Save deployment info
    $info = @{
        flowId      = $flowId
        displayName = $flowName
        envId       = $envId
        created     = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        designerUrl = "https://make.powerautomate.com/environments/$envId/flows/$flowId/details"
    } | ConvertTo-Json
    $info | Set-Content (Join-Path $PSScriptRoot "flows\VacationApproval_deployed.json") -Encoding UTF8
    Write-Host ""
    Write-Host "  Saved to: flows/VacationApproval_deployed.json" -ForegroundColor Gray
}
catch {
    $errMsg = $null
    $rawErr = $null
    try {
        $rawErr = $_.ErrorDetails.Message
        $errMsg = $rawErr | ConvertFrom-Json
    } catch {}

    Write-Host ""
    Write-Host "======================================================" -ForegroundColor Red
    Write-Host "  FLOW CREATION FAILED" -ForegroundColor Red
    Write-Host "======================================================" -ForegroundColor Red

    if ($errMsg -and $errMsg.error) {
        Write-Host "  Code:    $($errMsg.error.code)" -ForegroundColor Red
        Write-Host "  Message: $($errMsg.error.message)" -ForegroundColor Red
    } else {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        if ($rawErr) {
            Write-Host "  Details: $rawErr" -ForegroundColor Red
        }
    }

    # Dump response for debugging
    $debugPath = Join-Path $PSScriptRoot "flows\VacationApproval_error.json"
    if ($rawErr) {
        $rawErr | Set-Content $debugPath -Encoding UTF8 -ErrorAction SilentlyContinue
    } else {
        $_.Exception.Message | Set-Content $debugPath -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    Write-Host "  Debug info saved to: flows/VacationApproval_error.json" -ForegroundColor Gray
    exit 1
}

# Clean disconnect
Write-Host ""
Write-Host "[CLEANUP] Disconnecting PnP session..." -ForegroundColor Gray
Disconnect-PnPOnline -ErrorAction SilentlyContinue
Write-Host "Done!" -ForegroundColor Green
