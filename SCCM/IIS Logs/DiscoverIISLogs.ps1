#Tempo max de vida dos logs
[int]$MaxDays = 7
function DiscoverIISLogs ($MaxDays){
    try{
        #Import Modulo de administracao IIS
        Import-Module WebAdministration
        #Lista de sites
        $IISSites = Get-WebSite
        #Loop cada site do IIS
        foreach ($Site in $IISSites){
            #Caminho dos logs de cada site
            $IISLogsFolder = $Site.LogFile.Directory
            If ($IISLogsFolder -like "%SystemDrive%"){
                #Troca de Variavel padrao DOS para PowerShell
                $IISLogsFolder = $IISLogsFolder -replace "%SystemDrive%","$env:SystemDrive"
                }
            #Contage de Logs de acordo com o tempo maximo definido no inicio
            $LogCount = $LogCount + (Get-ChildItem -Path $IISLogsFolder -Recurse -Filter "*.log" | Where-Object {$(Get-Date).Subtract($_.LastWriteTime).Days -gt $MaxDays}).count
            }
            Return $LogCount
        }
    catch {return -1}
}
DiscoverIISLogs ($MaxDays)