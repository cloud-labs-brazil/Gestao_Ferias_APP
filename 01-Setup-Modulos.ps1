<#
.SYNOPSIS
    Setup inicial - Instala módulos necessários
#>

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " SETUP - Agente Gestão Férias" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar e instalar ImportExcel
Write-Host "[1/2] Verificando ImportExcel..." -ForegroundColor Yellow
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Write-Host "      Instalando ImportExcel..." -ForegroundColor Gray
    Install-Module -Name ImportExcel -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck
    Write-Host "      ImportExcel instalado!" -ForegroundColor Green
} else {
    Write-Host "      ImportExcel já instalado!" -ForegroundColor Green
}

# Verificar e instalar PnP.PowerShell
Write-Host "[2/2] Verificando PnP.PowerShell..." -ForegroundColor Yellow
if (-not (Get-Module -ListAvailable -Name PnP.PowerShell)) {
    Write-Host "      Instalando PnP.PowerShell (pode demorar alguns minutos)..." -ForegroundColor Gray
    Install-Module -Name PnP.PowerShell -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck
    Write-Host "      PnP.PowerShell instalado!" -ForegroundColor Green
} else {
    Write-Host "      PnP.PowerShell já instalado!" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " SETUP CONCLUÍDO!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Próximo passo: Execute .\02-Deploy-Listas.ps1" -ForegroundColor Cyan
