#Importing Modules
Write-Host "Importing Powershell modules for Intune" -ForegroundColor Green
try { 
    Import-Module -Name Microsoft.Graph.Intune -ErrorAction Stop
} 
catch {
    Write-Host "Microsoft.Graph.Intune module not found in common module path, installing (needs powershell as admin)..." -ForegroundColor Yellow
    Install-Module -Name Microsoft.Graph.Intune -Scope CurrentUser -Force
    Import-Module Microsoft.Graph.Intune -Force -Verbose
}

Write-Host "Connecting to Graph" -ForegroundColor Green
try {
    Connect-MSGraph -AdminConsent -ErrorAction Stop -Quiet -Verbose
    #Change to -AdminConsent if it is running the first time.
} catch {
    Write-Host "Failed to connect to MSGraph! Admin Consent?" -ForegroundColor Red -BackgroundColor Black
    Exit 1
}

#Getting device list
Write-Host "Getting Windows device list" -ForegroundColor Yellow
try {
    $deviceObjList = Get-IntuneManagedDevice | Where-Object operatingSystem -eq "Windows" | Get-MSGraphAllPages -Verbose
} catch {
    Write-Host "Failed to fetch devices!" -ForegroundColor Red -BackgroundColor Black
    Exit 1
}
$Count = $deviceObjList | measure

#Sending sync signal for all the devices
if ($Count.Count -gt 0){
    Write-Host "Sending sync signal to all Windows devices" -ForegroundColor Green
    foreach ($deviceObj in $deviceObjList) {
        try {
            "ID: {0} / Name: {1} / Owner: {2} / LastSync: {3}" -f $deviceObj.id,$deviceObj.deviceName,$deviceObj.userDisplayName,$deviceObj.lastSyncDateTime
            $deviceObj | Invoke-IntuneManagedDeviceSyncDevice -ErrorAction Stop
            $deviceObj | Invoke-IntuneManagedDeviceWindowsDefenderUpdateSignature -Verbose
        } catch {
            Write-Host "Failed to send sync action to $($deviceObj.id)" -ForegroundColor Red -BackgroundColor Black
        }
    }
} else {
    Write-Host "No Windows devices found in Intune!" -ForegroundColor Yellow
}

Write-Output "Done."