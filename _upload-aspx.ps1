$ErrorActionPreference = 'Stop'
$env:PNPLEGACYMESSAGE = 'false'
$siteUrl = 'https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA'

Write-Host ''
Write-Host '=========================================================' -ForegroundColor Cyan
Write-Host '  Enable Custom Scripts + Deploy ASPX Dashboard          ' -ForegroundColor Cyan
Write-Host '=========================================================' -ForegroundColor Cyan
Write-Host ''

# Step 1: Connect
Write-Host '[1/3] Connecting to SharePoint...' -ForegroundColor Yellow
Connect-PnPOnline -Url $siteUrl -UseWebLogin -WarningAction Ignore
Write-Host '  OK: Connected!' -ForegroundColor Green

# Step 2: Enable custom scripts (DenyAddAndCustomizePages = false)
Write-Host ''
Write-Host '[2/3] Enabling custom scripts on site...' -ForegroundColor Yellow
Write-Host '  Setting DenyAddAndCustomizePages to $false' -ForegroundColor DarkGray
try {
    Set-PnPSite -Identity $siteUrl -DenyAddAndCustomizePages $false
    Write-Host '  OK: Custom scripts enabled!' -ForegroundColor Green
}
catch {
    Write-Host "  WARNING: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host '  (May need tenant admin rights - trying to continue)' -ForegroundColor DarkGray
}

# Step 3: Re-upload ASPX file (force refresh)
Write-Host ''
Write-Host '[3/3] Re-uploading index.aspx...' -ForegroundColor Yellow
$aspxPath = 'c:\VMs\Projects\Copilot_Studio_Config\GestaoFerias-Dashboard\index.aspx'
$file = Add-PnPFile -Path $aspxPath -Folder 'SiteAssets/GestaoFerias-Dashboard' -ErrorAction Stop
Write-Host "  OK: Uploaded $($file.Name)" -ForegroundColor Green

Write-Host ''
Write-Host '=========================================================' -ForegroundColor Green
Write-Host '  DEPLOYMENT COMPLETE                                    ' -ForegroundColor Green
Write-Host '=========================================================' -ForegroundColor Green
Write-Host ''
Write-Host '  Dashboard URL (ASPX):' -ForegroundColor White
Write-Host "  $siteUrl/SiteAssets/GestaoFerias-Dashboard/index.aspx" -ForegroundColor Cyan
Write-Host ''
Write-Host '  NOTE: Changes may take up to 24h to propagate.' -ForegroundColor DarkGray
Write-Host '  If still getting "File Not Found", wait 15 minutes and retry.' -ForegroundColor DarkGray
Write-Host ''
