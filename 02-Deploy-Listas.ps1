# ============================================
# SCRIPT: Deploy Listas SharePoint - Gestão Férias
# Compatível com: SharePointPnPPowerShellOnline 3.29 (PS 5.1) ou PnP.PowerShell (PS 7+)
# ============================================

param(
    [string]$SiteUrl = "https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA"
)

# ============================================
# CONEXÃO
# ============================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " DEPLOY LISTAS - GESTÃO FÉRIAS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Site: $SiteUrl" -ForegroundColor Gray
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

# ============================================
# DEFINIÇÃO DAS LISTAS E COLUNAS
# ============================================

$Listas = @(
    @{
        Name    = "Colaboradores_Aprovadores"
        Columns = @(
            @{ DisplayName = "Email"; InternalName = "Email"; Type = "Text" }
            @{ DisplayName = "NomeCompleto"; InternalName = "NomeCompleto"; Type = "Text" }
            @{ DisplayName = "Departamento"; InternalName = "Departamento"; Type = "Text" }
            @{ DisplayName = "Cargo"; InternalName = "Cargo"; Type = "Text" }
            @{ DisplayName = "AprovadorEmail"; InternalName = "AprovadorEmail"; Type = "Text" }
            @{ DisplayName = "AprovadorNome"; InternalName = "AprovadorNome"; Type = "Text" }
            @{ DisplayName = "DataAdmissao"; InternalName = "DataAdmissao"; Type = "DateTime" }
            @{ DisplayName = "Ativo"; InternalName = "Ativo"; Type = "Boolean" }
        )
    },
    @{
        Name    = "Solicitacoes_Ferias"
        Columns = @(
            @{ DisplayName = "ColaboradorEmail"; InternalName = "ColaboradorEmail"; Type = "Text" }
            @{ DisplayName = "ColaboradorNome"; InternalName = "ColaboradorNome"; Type = "Text" }
            @{ DisplayName = "DataInicio"; InternalName = "DataInicio"; Type = "DateTime" }
            @{ DisplayName = "DataFim"; InternalName = "DataFim"; Type = "DateTime" }
            @{ DisplayName = "DiasUteis"; InternalName = "DiasUteis"; Type = "Number" }
            @{ DisplayName = "Tipo"; InternalName = "Tipo"; Type = "Text" }
            @{ DisplayName = "Status"; InternalName = "Status"; Type = "Text" }
            @{ DisplayName = "AprovadorEmail"; InternalName = "AprovadorEmail"; Type = "Text" }
            @{ DisplayName = "DataAprovacao"; InternalName = "DataAprovacao"; Type = "DateTime" }
            @{ DisplayName = "Observacoes"; InternalName = "Observacoes"; Type = "Note" }
            @{ DisplayName = "CriadoPorBot"; InternalName = "CriadoPorBot"; Type = "Boolean" }
        )
    },
    @{
        Name    = "Historico_Ferias"
        Columns = @(
            @{ DisplayName = "ColaboradorEmail"; InternalName = "ColaboradorEmail"; Type = "Text" }
            @{ DisplayName = "AnoReferencia"; InternalName = "AnoReferencia"; Type = "Number" }
            @{ DisplayName = "DataInicio"; InternalName = "DataInicio"; Type = "DateTime" }
            @{ DisplayName = "DataFim"; InternalName = "DataFim"; Type = "DateTime" }
            @{ DisplayName = "DiasUteis"; InternalName = "DiasUteis"; Type = "Number" }
            @{ DisplayName = "Tipo"; InternalName = "Tipo"; Type = "Text" }
            @{ DisplayName = "Status"; InternalName = "Status"; Type = "Text" }
        )
    },
    @{
        Name    = "Saldo_Ferias"
        Columns = @(
            @{ DisplayName = "ColaboradorEmail"; InternalName = "ColaboradorEmail"; Type = "Text" }
            @{ DisplayName = "AnoReferencia"; InternalName = "AnoReferencia"; Type = "Number" }
            @{ DisplayName = "SaldoTotal"; InternalName = "SaldoTotal"; Type = "Number" }
            @{ DisplayName = "DiasUsados"; InternalName = "DiasUsados"; Type = "Number" }
            @{ DisplayName = "DiasAgendados"; InternalName = "DiasAgendados"; Type = "Number" }
            @{ DisplayName = "SaldoDisponivel"; InternalName = "SaldoDisponivel"; Type = "Number" }
            @{ DisplayName = "DataAtualizacao"; InternalName = "DataAtualizacao"; Type = "DateTime" }
        )
    },
    @{
        Name    = "Feriados"
        Columns = @(
            @{ DisplayName = "Data"; InternalName = "Data"; Type = "DateTime" }
            @{ DisplayName = "Descricao"; InternalName = "Descricao"; Type = "Text" }
            @{ DisplayName = "Tipo"; InternalName = "Tipo"; Type = "Text" }
            @{ DisplayName = "Ano"; InternalName = "Ano"; Type = "Number" }
        )
    },
    @{
        Name    = "Alertas_Ferias"
        Columns = @(
            @{ DisplayName = "ColaboradorEmail"; InternalName = "ColaboradorEmail"; Type = "Text" }
            @{ DisplayName = "TipoAlerta"; InternalName = "TipoAlerta"; Type = "Text" }
            @{ DisplayName = "Mensagem"; InternalName = "Mensagem"; Type = "Note" }
            @{ DisplayName = "DataEnvio"; InternalName = "DataEnvio"; Type = "DateTime" }
            @{ DisplayName = "Enviado"; InternalName = "Enviado"; Type = "Boolean" }
            @{ DisplayName = "SolicitacaoId"; InternalName = "SolicitacaoId"; Type = "Number" }
        )
    }
)

# ============================================
# CRIAR LISTAS E COLUNAS
# ============================================

foreach ($lista in $Listas) {
    $listName = $lista.Name
    
    Write-Host ""
    Write-Host "[LISTA] Processando '$listName'..." -ForegroundColor Yellow
    
    # Verificar se lista existe
    $existingList = Get-PnPList -Identity $listName -ErrorAction SilentlyContinue
    
    if ($existingList) {
        Write-Host "  [SKIP] Lista já existe - GUID: $($existingList.Id)" -ForegroundColor Gray
    }
    else {
        # Criar lista
        $newList = New-PnPList -Title $listName -Template GenericList -EnableVersioning
        Write-Host "  [OK] Lista criada - GUID: $($newList.Id)" -ForegroundColor Green
    }
    
    # Criar colunas
    foreach ($col in $lista.Columns) {
        $existing = Get-PnPField -List $listName -Identity $col.InternalName -ErrorAction SilentlyContinue
        
        if (-not $existing) {
            try {
                Add-PnPField -List $listName `
                    -DisplayName $col.DisplayName `
                    -InternalName $col.InternalName `
                    -Type $col.Type `
                    -AddToDefaultView
                Write-Host "    [OK] Coluna '$($col.DisplayName)' criada" -ForegroundColor Green
            }
            catch {
                Write-Host "    [ERRO] Coluna '$($col.DisplayName)': $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        else {
            Write-Host "    [SKIP] Coluna '$($col.DisplayName)' já existe" -ForegroundColor Gray
        }
    }
}

# ============================================
# DESCONEXÃO
# ============================================
Write-Host ""
Write-Host "[CONEXÃO] Desconectando..." -ForegroundColor Yellow
Disconnect-PnPOnline
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " DEPLOY CONCLUÍDO!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
