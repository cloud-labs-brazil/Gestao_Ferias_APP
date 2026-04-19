Connect-PnPOnline -Url "https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA" -UseWebLogin

$lists = @("Solicitacoes_Ferias", "Colaboradores_Aprovadores", "Saldo_Ferias", "Feriados", "Historico_Ferias", "Alertas_Ferias")

foreach ($listName in $lists) {
    try {
        $list = Get-PnPList -Identity $listName
        Write-Host "$($list.Title) => $($list.Id)" -ForegroundColor Green
    } catch {
        Write-Host "$listName => NOT FOUND" -ForegroundColor Red
    }
}
