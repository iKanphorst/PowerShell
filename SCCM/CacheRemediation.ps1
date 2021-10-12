function SCCMPurgeList
{
    # Especificação de vida máxima
    $MaxRetention = "14"
    # Conexão ao COM Object
    $SCCMClient = New-Object -ComObject UIResource.UIResourceMgr
    # Checagem de COM Object e processos
    if ($SCCMClient -ne $null)
    {
        if (($SCCMClient.GetType()).Name -match "_ComObject")
        {
            #Obtenção do diretório de cache
            $SCCMCacheDir = ($SCCMClient.GetCacheInfo().Location) 
            # Listagem de conteúdo em estado de execução ou a ser executado
            $PendingApps = $SCCMClient.GetAvailableApplications() | Where-Object { (($_.StartTime -gt (Get-Date)) -or ($_.IsCurrentlyRunning -eq "1"))}
            # Lista de aplicações a serem removidas da cache
            $PurgeApps = $SCCMClient.GetCacheInfo().GetCacheElements() | Where-Object { ($_.ContentID -notin $PendingApps.PackageID) -and $((Test-Path -Path $_.Location) -eq $true) -and ($_.LastReferenceTime -lt (Get-Date).AddDays(- $MaxRetention)) }
            # Limpeza de aplicações não necessárias
            foreach ($App in $PurgeApps){
                $SCCMClient.GetCacheInfo().DeleteCacheElement($App.CacheElementID)
                }
            # Limpeza dos diretórios
            $ActiveDirs = $SCCMClient.GetCacheInfo().GetCacheElements() | ForEach-Object { Write-Output $_.Location } Get-ChildItem -Path $SCCMCacheDir | Where-Object { (($_.PsIsContainer -eq $true) -and ($_.FullName -notin $ActiveDirs)) } | Remove-Item -Recurse -Force -Verbose
            }
         } 
      }
SCCMPurgeList