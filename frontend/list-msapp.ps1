Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead("C:\VMs\Projects\Copilot_Studio_Config\frontend\Aplicativo.msapp")
$zip.Entries | ForEach-Object { Write-Host $_.FullName }
$zip.Dispose()
