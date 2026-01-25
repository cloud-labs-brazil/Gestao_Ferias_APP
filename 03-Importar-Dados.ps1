<#
.SYNOPSIS
    Importa dados do Excel para as listas SharePoint
.PARAMETER SiteUrl
    URL do site SharePoint
.PARAMETER ExcelPath
    Caminho do arquivo Excel com colaboradores
.EXAMPLE
    .\03-Importar-Dados.ps1 -ExcelPath "D:\VMs\Projetos\Copilot_Studio_Config\Users_Approvers.xlsx"
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$SiteUrl = "https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA",
    
    [Parameter(Mandatory = $false)]
    [string]$ExcelPath = "C:\VMs\Projects\Copilot_Studio_Config\Users_Approvers.xlsx"
)

Import-Module ImportExcel -ErrorAction Stop

# Try modern module first, fallback to legacy
try {
    Import-Module PnP.PowerShell -ErrorAction Stop
}
catch {
    Import-Module SharePointPnPPowerShellOnline -ErrorAction Stop
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " IMPORTAR DADOS DO EXCEL" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar arquivo
if (-not (Test-Path $ExcelPath)) {
    Write-Host "[ERRO] Arquivo não encontrado: $ExcelPath" -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] Arquivo: $ExcelPath" -ForegroundColor Gray
Write-Host ""

# Conectar
Write-Host "[CONEXÃO] Conectando ao SharePoint..." -ForegroundColor Yellow
Connect-PnPOnline -Url $SiteUrl -UseWebLogin
Write-Host "[CONEXÃO] Conectado!" -ForegroundColor Green
Write-Host ""

# Ler Excel
Write-Host "[EXCEL] Lendo arquivo..." -ForegroundColor Yellow
$excelData = Import-Excel -Path $ExcelPath
Write-Host "[EXCEL] $($excelData.Count) registros encontrados" -ForegroundColor Green
Write-Host ""

# Mostrar colunas detectadas
Write-Host "[COLUNAS] Detectadas:" -ForegroundColor Cyan
$excelData[0].PSObject.Properties.Name | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
Write-Host ""

# Importar para Colaboradores_Aprovadores
Write-Host "[IMPORT] Importando para Colaboradores_Aprovadores..." -ForegroundColor Yellow

$count = 0
$errors = 0

foreach ($row in $excelData) {
    try {
        # Mapear colunas flexivelmente (PS 5.1 compatible)
        $nome = if ($row.Nome) { $row.Nome } elseif ($row.Name) { $row.Name } elseif ($row.Title) { $row.Title } else { "" }
        $email = if ($row.Email) { $row.Email } elseif ($row.'E-mail') { $row.'E-mail' } elseif ($row.Mail) { $row.Mail } else { "" }
        $dept = if ($row.Departamento) { $row.Departamento } elseif ($row.Department) { $row.Department } else { "" }
        $cargo = if ($row.Cargo) { $row.Cargo } elseif ($row.Position) { $row.Position } else { "" }
        $gestorNome = if ($row.Gestor_Nome) { $row.Gestor_Nome } elseif ($row.'Gestor Nome') { $row.'Gestor Nome' } elseif ($row.Manager) { $row.Manager } else { "" }
        $gestorEmail = if ($row.Gestor_Email) { $row.Gestor_Email } elseif ($row.'Gestor Email') { $row.'Gestor Email' } elseif ($row.ManagerEmail) { $row.ManagerEmail } else { "" }
        $diretorNome = if ($row.Diretor_Nome) { $row.Diretor_Nome } elseif ($row.'Diretor Nome') { $row.'Diretor Nome' } else { "" }
        $diretorEmail = if ($row.Diretor_Email) { $row.Diretor_Email } elseif ($row.'Diretor Email') { $row.'Diretor Email' } else { "" }
        $ehGestorRaw = if ($row.EhGestor) { $row.EhGestor } elseif ($row.'É Gestor') { $row.'É Gestor' } elseif ($row.IsManager) { $row.IsManager } else { $false }
        
        if ($ehGestorRaw -eq "Sim" -or $ehGestorRaw -eq "Yes" -or $ehGestorRaw -eq $true -or $ehGestorRaw -eq "Não" -eq $false) {
            $ehGestor = ($ehGestorRaw -eq "Sim" -or $ehGestorRaw -eq "Yes" -or $ehGestorRaw -eq $true)
        }
        else {
            $ehGestor = $false
        }
        
        $itemValues = @{
            "Title"          = $nome
            "Email"          = $email
            "NomeCompleto"   = $nome
            "Departamento"   = $dept
            "Cargo"          = $cargo
            "AprovadorNome"  = $gestorNome
            "AprovadorEmail" = $gestorEmail
            "Ativo"          = $true
        }
        
        Add-PnPListItem -List "Colaboradores_Aprovadores" -Values $itemValues | Out-Null
        $count++
        Write-Host "." -NoNewline -ForegroundColor Green
        
    }
    catch {
        $errors++
        Write-Host "x" -NoNewline -ForegroundColor Red
    }
}

Write-Host ""
Write-Host ""
Write-Host "[RESULTADO] $count registros importados, $errors erros" -ForegroundColor $(if ($errors -eq 0) { "Green" } else { "Yellow" })

# ═══════════════════════════════════════════════════════════════════
# POPULAR FERIADOS 2026
# ═══════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "[FERIADOS] Adicionando feriados 2026..." -ForegroundColor Yellow

$feriados = @(
    @{ Title = "Confraternização Universal"; Data = "2026-01-01"; Tipo = "Nacional" },
    @{ Title = "Carnaval"; Data = "2026-02-16"; Tipo = "Nacional" },
    @{ Title = "Carnaval"; Data = "2026-02-17"; Tipo = "Nacional" },
    @{ Title = "Quarta-feira de Cinzas"; Data = "2026-02-18"; Tipo = "Ponte" },
    @{ Title = "Sexta-feira Santa"; Data = "2026-04-03"; Tipo = "Nacional" },
    @{ Title = "Tiradentes"; Data = "2026-04-21"; Tipo = "Nacional" },
    @{ Title = "Dia do Trabalho"; Data = "2026-05-01"; Tipo = "Nacional" },
    @{ Title = "Corpus Christi"; Data = "2026-06-04"; Tipo = "Nacional" },
    @{ Title = "Independência do Brasil"; Data = "2026-09-07"; Tipo = "Nacional" },
    @{ Title = "Nossa Senhora Aparecida"; Data = "2026-10-12"; Tipo = "Nacional" },
    @{ Title = "Finados"; Data = "2026-11-02"; Tipo = "Nacional" },
    @{ Title = "Proclamação da República"; Data = "2026-11-15"; Tipo = "Nacional" },
    @{ Title = "Natal"; Data = "2026-12-25"; Tipo = "Nacional" },
    @{ Title = "Recesso Fim de Ano"; Data = "2026-12-26"; Tipo = "Recesso" },
    @{ Title = "Recesso Fim de Ano"; Data = "2026-12-27"; Tipo = "Recesso" },
    @{ Title = "Recesso Fim de Ano"; Data = "2026-12-28"; Tipo = "Recesso" },
    @{ Title = "Recesso Fim de Ano"; Data = "2026-12-29"; Tipo = "Recesso" },
    @{ Title = "Recesso Fim de Ano"; Data = "2026-12-30"; Tipo = "Recesso" },
    @{ Title = "Recesso Fim de Ano"; Data = "2026-12-31"; Tipo = "Recesso" }
)

$feriadoCount = 0
foreach ($feriado in $feriados) {
    try {
        Add-PnPListItem -List "Feriados" -Values @{
            Title = $feriado.Title
            Data  = $feriado.Data
            Ano   = 2026
            Tipo  = $feriado.Tipo
        } | Out-Null
        $feriadoCount++
    }
    catch {}
}

Write-Host "[FERIADOS] $feriadoCount feriados adicionados" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════════
# RESUMO
# ═══════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " IMPORTAÇÃO CONCLUÍDA!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Resumo:" -ForegroundColor Cyan
Write-Host "  - Colaboradores: $count"
Write-Host "  - Feriados: $feriadoCount"
Write-Host ""

Disconnect-PnPOnline
