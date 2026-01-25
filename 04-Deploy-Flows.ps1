# 04-Deploy-Flows.ps1 - Guia de Implantação dos Fluxos Power Automate
# Projeto: Gestão Férias - Copilot Studio
# Data: 2026-01-25

<#
.SYNOPSIS
    Guia para implantação dos fluxos Power Automate para o Agente Gestão Férias

.DESCRIPTION
    Este script contém instruções para criar os fluxos no Power Automate.
    Os fluxos estão definidos em JSON na pasta /flows.

.NOTES
    - Requer licença Power Automate Premium para conectores HTTP
    - Fluxos devem ser criados como "Cloud Flows" tipo "Instant"
    - Escolher trigger "When HTTP request is received"
#>

param(
    [string]$SiteUrl = "https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA"
)

Write-Host "========================================"  -ForegroundColor Cyan
Write-Host " GUIA DE IMPLANTAÇÃO - POWER AUTOMATE" -ForegroundColor Cyan
Write-Host "========================================"  -ForegroundColor Cyan
Write-Host ""

$flows = @(
    @{ Number = 1; Name = "ConsultarSaldoFerias"; Priority = "P1"; Trigger = "HTTP Request" },
    @{ Number = 2; Name = "VerificarConflitos"; Priority = "P1"; Trigger = "HTTP Request" },
    @{ Number = 3; Name = "CriarSolicitacao"; Priority = "P1"; Trigger = "HTTP Request" },
    @{ Number = 4; Name = "AprovarSolicitacao"; Priority = "P2"; Trigger = "HTTP Request" },
    @{ Number = 5; Name = "RejeitarSolicitacao"; Priority = "P2"; Trigger = "HTTP Request" },
    @{ Number = 6; Name = "ConsultarStatusSolicitacao"; Priority = "P2"; Trigger = "HTTP Request" },
    @{ Number = 7; Name = "CancelarSolicitacao"; Priority = "P3"; Trigger = "HTTP Request" },
    @{ Number = 8; Name = "ObterDashboardGestor"; Priority = "P3"; Trigger = "HTTP Request" },
    @{ Number = 9; Name = "ObterAlertasCriticos"; Priority = "P3"; Trigger = "HTTP Request" },
    @{ Number = 10; Name = "EnviarNotificacaoTeams"; Priority = "P2"; Trigger = "HTTP Request" }
)

Write-Host "[FLUXOS A CRIAR]" -ForegroundColor Yellow
Write-Host ""

foreach ($flow in $flows) {
    $file = "flows\Flow_{0:D2}_{1}.json" -f $flow.Number, $flow.Name
    $exists = Test-Path $file
    $status = if ($exists) { "[OK]" } else { "[MISSING]" }
    Write-Host ("  {0,-3} {1,-30} {2,-4} {3}" -f $flow.Number, $flow.Name, $flow.Priority, $status)
}

Write-Host ""
Write-Host "========================================"  -ForegroundColor Green
Write-Host " INSTRUÇÕES DE IMPLANTAÇÃO" -ForegroundColor Green
Write-Host "========================================"  -ForegroundColor Green
Write-Host ""

$instructions = @"
PASSO A PASSO PARA CADA FLUXO:

1. Acesse: https://make.powerautomate.com
2. Selecione ambiente correto (indra365)
3. Clique em "+ Create" > "Instant cloud flow"
4. Nome: [Nome do fluxo conforme lista]
5. Trigger: "When HTTP request is received"

6. Configure o Schema JSON:
   - Copie o "schema" do arquivo JSON correspondente
   - Cole no campo "Request Body JSON Schema"

7. Adicione as ações:
   - Siga a sequência de "actions" do arquivo JSON
   - Use os conectores:
     * SharePoint (shared_sharepointonline)
     * Teams (shared_teams)
     * Office 365 (shared_office365)

8. Configure conexões:
   - Site URL: $SiteUrl
   - Listas: Conforme definido em cada ação

9. Adicione Response no final:
   - Copie o "body" do Response do JSON

10. Salve e publique o fluxo

11. Copie a URL HTTP gerada para usar no Copilot Studio

CONEXÕES NECESSÁRIAS:
- SharePoint (para acessar listas)
- Microsoft Teams (para notificações)
- Office 365 Outlook (para emails)

APÓS CRIAR TODOS OS FLUXOS:
- Registre as URLs HTTP no documento de configuração
- Configure as ferramentas no Copilot Studio
- Teste cada fluxo individualmente
"@

Write-Host $instructions

Write-Host ""
Write-Host "========================================"  -ForegroundColor Cyan
Write-Host " ARQUIVOS DE DEFINIÇÃO" -ForegroundColor Cyan
Write-Host "========================================"  -ForegroundColor Cyan
Write-Host ""

Get-ChildItem -Path ".\flows" -Filter "*.json" | ForEach-Object {
    Write-Host ("  📄 {0}" -f $_.Name)
}

Write-Host ""
Write-Host "[PRÓXIMO PASSO] Crie os fluxos no Power Automate seguindo as instruções acima." -ForegroundColor Yellow
Write-Host ""
