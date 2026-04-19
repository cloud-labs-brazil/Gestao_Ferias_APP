Add-Type -AssemblyName System.IO.Compression.FileSystem
$msappPath = "C:\VMs\Projects\Copilot_Studio_Config\frontend\Aplicativo.msapp"
$extractPath = "C:\VMs\Projects\Copilot_Studio_Config\frontend\extracted"

if (Test-Path $extractPath) { Remove-Item -Path $extractPath -Recurse -Force }
[System.IO.Compression.ZipFile]::ExtractToDirectory($msappPath, $extractPath)
Write-Host "Extracted to: $extractPath"
Get-ChildItem -Path $extractPath -Recurse | ForEach-Object { Write-Host $_.FullName }
