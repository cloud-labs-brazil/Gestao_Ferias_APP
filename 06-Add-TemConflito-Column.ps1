# ============================================
# SCRIPT: Add Tem_Conflito column to Solicitacoes_Ferias
# Purpose: Missing column needed for conflict flag in VacationApproval flow
# ============================================

param(
    [string]$SiteUrl = "https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " ADD COLUMN: Tem_Conflito" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[CONEXÃO] Conectando ao SharePoint..." -ForegroundColor Yellow
try {
    Connect-PnPOnline -Url $SiteUrl -UseWebLogin
    Write-Host "[CONEXÃO] Conectado com sucesso!" -ForegroundColor Green
}
catch {
    Write-Host "[ERRO] Falha na conexão: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Add Tem_Conflito column
$listName = "Solicitacoes_Ferias"
$colName = "TemConflito"

$existing = Get-PnPField -List $listName -Identity $colName -ErrorAction SilentlyContinue

if (-not $existing) {
    try {
        Add-PnPField -List $listName `
            -DisplayName "TemConflito" `
            -InternalName "TemConflito" `
            -Type Boolean `
            -AddToDefaultView
        Write-Host "[OK] Coluna 'TemConflito' criada em $listName" -ForegroundColor Green
    }
    catch {
        Write-Host "[ERRO] Falha ao criar coluna: $($_.Exception.Message)" -ForegroundColor Red
    }
}
else {
    Write-Host "[SKIP] Coluna 'TemConflito' já existe" -ForegroundColor Gray
}

# Disconnect
Write-Host ""
Write-Host "[CONEXÃO] Desconectando..." -ForegroundColor Yellow
Disconnect-PnPOnline
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " CONCLUÍDO!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
