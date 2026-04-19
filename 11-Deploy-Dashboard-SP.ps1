<#
.SYNOPSIS
    Deploys the GestaoFerias-Dashboard (HTML/CSS/JS) to SharePoint Site Assets.

.DESCRIPTION
    Uploads the complete HTML dashboard to a SharePoint document library so it can be
    embedded as a Teams tab (Website) or SharePoint page (Embed web part).
    
    After upload, the dashboard URL will be:
    https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA/SiteAssets/GestaoFerias-Dashboard/index.html

.EXAMPLE
    .\11-Deploy-Dashboard-SP.ps1
#>

param(
    [string]$SiteUrl = "https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA",
    [string]$DashboardPath = "$PSScriptRoot\GestaoFerias-Dashboard",
    [string]$LibraryName = "SiteAssets",
    [string]$FolderName = "GestaoFerias-Dashboard"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "  DEPLOY: GestaoFerias Dashboard -> SharePoint           " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Validate local files exist
Write-Host "[1/5] Validating local dashboard files..." -ForegroundColor Yellow

$requiredFiles = @(
    "index.html",
    "css\styles.css",
    "js\data.js",
    "js\sp-connector.js",
    "js\components.js",
    "js\charts.js",
    "js\app.js"
)

foreach ($file in $requiredFiles) {
    $fullPath = Join-Path $DashboardPath $file
    if (-not (Test-Path $fullPath)) {
        Write-Host "  X MISSING: $file" -ForegroundColor Red
        throw "Required file not found: $fullPath"
    }
    Write-Host "  OK: $file" -ForegroundColor Green
}

# Step 2: Connect to SharePoint
Write-Host ""
Write-Host "[2/5] Connecting to SharePoint..." -ForegroundColor Yellow
Write-Host "  Site: $SiteUrl" -ForegroundColor DarkGray

$env:PNPLEGACYMESSAGE = 'false'
Connect-PnPOnline -Url $SiteUrl -UseWebLogin -WarningAction Ignore
Write-Host "  OK: Connected!" -ForegroundColor Green

# Step 3: Create folder structure in SiteAssets
Write-Host ""
Write-Host "[3/5] Creating folder structure in $LibraryName..." -ForegroundColor Yellow

# Ensure root folder exists
try {
    $rootFolder = Get-PnPFolder -Url "$LibraryName/$FolderName" -ErrorAction SilentlyContinue
    if ($rootFolder) {
        Write-Host "  - Folder exists: $LibraryName/$FolderName" -ForegroundColor DarkGray
    }
}
catch {
    Add-PnPFolder -Name $FolderName -Folder $LibraryName | Out-Null
    Write-Host "  OK: Created $LibraryName/$FolderName" -ForegroundColor Green
}

# Ensure css subfolder exists
try {
    $cssFolder = Get-PnPFolder -Url "$LibraryName/$FolderName/css" -ErrorAction SilentlyContinue
    if ($cssFolder) {
        Write-Host "  - Folder exists: $LibraryName/$FolderName/css" -ForegroundColor DarkGray
    }
}
catch {
    Add-PnPFolder -Name "css" -Folder "$LibraryName/$FolderName" | Out-Null
    Write-Host "  OK: Created $LibraryName/$FolderName/css" -ForegroundColor Green
}

# Ensure js subfolder exists
try {
    $jsFolder = Get-PnPFolder -Url "$LibraryName/$FolderName/js" -ErrorAction SilentlyContinue
    if ($jsFolder) {
        Write-Host "  - Folder exists: $LibraryName/$FolderName/js" -ForegroundColor DarkGray
    }
}
catch {
    Add-PnPFolder -Name "js" -Folder "$LibraryName/$FolderName" | Out-Null
    Write-Host "  OK: Created $LibraryName/$FolderName/js" -ForegroundColor Green
}

# Step 4: Upload all files
Write-Host ""
Write-Host "[4/5] Uploading dashboard files..." -ForegroundColor Yellow

$uploadMap = @(
    @{ Local = "index.html";         Remote = "$LibraryName/$FolderName" },
    @{ Local = "css\styles.css";     Remote = "$LibraryName/$FolderName/css" },
    @{ Local = "js\data.js";         Remote = "$LibraryName/$FolderName/js" },
    @{ Local = "js\sp-connector.js"; Remote = "$LibraryName/$FolderName/js" },
    @{ Local = "js\components.js";   Remote = "$LibraryName/$FolderName/js" },
    @{ Local = "js\charts.js";       Remote = "$LibraryName/$FolderName/js" },
    @{ Local = "js\app.js";          Remote = "$LibraryName/$FolderName/js" }
)

$uploadCount = 0
foreach ($item in $uploadMap) {
    $localPath = Join-Path $DashboardPath $item.Local
    $fileName = Split-Path $localPath -Leaf
    $remoteFolder = $item.Remote

    Add-PnPFile -Path $localPath -Folder $remoteFolder -ErrorAction Stop | Out-Null
    $uploadCount++
    Write-Host "  OK: $fileName -> $remoteFolder/" -ForegroundColor Green
}

# Step 5: Summary
Write-Host ""
Write-Host "[5/5] Deployment complete!" -ForegroundColor Yellow
Write-Host ""

$dashboardUrl = "$SiteUrl/$LibraryName/$FolderName/index.html"

Write-Host "=========================================================" -ForegroundColor Green
Write-Host "  DASHBOARD DEPLOYED SUCCESSFULLY                        " -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Files uploaded: $uploadCount / $($uploadMap.Count)" -ForegroundColor White
Write-Host ""
Write-Host "  DASHBOARD URL:" -ForegroundColor White
Write-Host "  $dashboardUrl" -ForegroundColor Cyan
Write-Host ""
Write-Host "---------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  NEXT STEPS:" -ForegroundColor White
Write-Host "  1. Open the URL above in your browser to verify" -ForegroundColor DarkGray
Write-Host "  2. In Teams -> Channel -> '+' -> Website -> paste URL" -ForegroundColor DarkGray
Write-Host "  3. Name the tab: 'Dashboard Ferias'" -ForegroundColor DarkGray
Write-Host "---------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

# Return URL for programmatic use
return $dashboardUrl
