$ErrorActionPreference = 'Stop'
$env:PNPLEGACYMESSAGE = 'false'
$siteUrl = 'https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA'

Write-Host 'Connecting...'
Connect-PnPOnline -Url $siteUrl -UseWebLogin -WarningAction Ignore
Write-Host 'Connected!'

Write-Host 'Attempting to disable NoScript on site...'
try {
    Set-PnPSite -NoScriptSite $false
    Write-Host 'SUCCESS: NoScript disabled!' -ForegroundColor Green
}
catch {
    Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ''
Write-Host 'Verifying site properties...'
$site = Get-PnPSite -Includes DenyAddAndCustomizePages
Write-Host "DenyAddAndCustomizePages = $($site.DenyAddAndCustomizePages)"
