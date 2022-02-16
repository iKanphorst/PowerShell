#Tempo max de vida dos logs
[int]$MaxDays = 7
function PurgeIISLogs ($MaxDays){
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
            #Remocao do Log de acordo com o tempo maximo definido no inicio
            Get-ChildItem -Path $IISLogsFolder -Recurse -Filter "*.log" | Where-Object {$(Get-Date).Subtract($_.LastWriteTime).Days -gt $MaxDays} | ForEach-Object {Remove-Item $_.FullName -Force -Verbose}
            }
        }
    catch {}
}
PurgeIISLogs ($MaxDays)