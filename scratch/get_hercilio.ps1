Import-Module ImportExcel
$d = Import-Excel 'C:\VMs\Projects\Copilot_Studio_Config\Users_Approvers.xlsx'
$herc = $d | Where-Object { $_.Nome -like '*Hercilio*' }
$herc | Format-List *
