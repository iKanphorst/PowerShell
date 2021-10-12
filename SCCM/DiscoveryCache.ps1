function SCCMPurgeList {
    # Definição de tempo máximo de vida da cache 
    $MaxRetention = "14" 
    # Conexão com o Com Object 
    $SCCMClient = New-Object -ComObject UIResource.UIResourceMgr 
    # Obtenção do diretório de cache 
    $SCCMCacheDir = ($SCCMClient.GetCacheInfo().Location) 
    # Listagem de conteúdo em estado de execução ou a ser executado 
    $PendingApps = $SCCMClient.GetAvailableApplications() | Where-Object { (($_.StartTime -gt (Get-Date)) -or ($_.IsCurrentlyRunning -eq "1")) }
    # Lista de conteúdo a ser eliminado 
    $PurgeApps = $SCCMClient.GetCacheInfo().GetCacheElements() | Where-Object { ($_.ContentID -notin $PendingApps.PackageID) -and ((Test-Path -Path $_.Location) -eq $true) -and ($_.LastReferenceTime -lt (Get-Date).AddDays(- $MaxRetention)) } 
    # Contagem de conteúdo a ser eliminado 
    $PurgeCount = ($PurgeApps.Items).Count 
    # Obtenção de diretórios 
    $ActiveDirs = $SCCMClient.GetCacheInfo().GetCacheElements() | ForEach-Object { Write-Output $_.Location }
    $MiscDirs = (Get-ChildItem -Path $SCCMCacheDir | Where-Object { (($_.PsIsContainer -eq $true) -and ($_.FullName -notin $ActiveDirs)) }).count 
    # Contagem total de lista a ser removida
    $PurgeCount = $PurgeCount + $MiscDirs
    # Retorno de total de itens
    $PurgeCount 
} 
SCCMPurgeList
