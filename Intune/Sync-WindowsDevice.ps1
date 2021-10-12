param (
  [String]$ComputerName
  )

Write-Host "Type the computer name to be synced: " -NoNewline -ForegroundColor Yellow
$ComputerName = Read-Host

Write-Host "Importing Powershell modules for Intune" -ForegroundColor Green
try { 
    Import-Module -Name Microsoft.Graph.Intune -ErrorAction Stop
} 
catch {
    try {
        Write-Host "Microsoft.Graph.Intune module not found in common module path, installing..." -ForegroundColor Yellow
        Install-Module -Name Microsoft.Graph.Intune -Scope CurrentUser -Force
        Import-Module Microsoft.Graph.Intune -Force
        }
    catch {
        Write-Host "Failed to install Intune Graph module. Is Powershell executed as admin?" -ForegroundColor Red -BackgroundColor Black
    }
}

Write-Output "Connecting to Graph"
try {
    Connect-MSGraph -AdminConsent -ErrorAction Stop
} catch {
    Write-Host "Failed to connect to MSGraph!" -ForegroundColor Red -BackgroundColor Black
    Exit 1
}

Write-Output "Looking up device..."
try {
    $deviceObj = Get-IntuneManagedDevice | Where-Object deviceName -Like $ComputerName
} catch {
    Write-Host "Failed to fetch device! Permissions or Admin Consent issue perhaps?" -ForegroundColor Red -BackgroundColor Black
    Exit 1
}

if ($null -ne $deviceObj){
    Write-Host "Sending sync signal to Intune Device" -ForegroundColor Green
    $deviceObj | Invoke-IntuneManagedDeviceSyncDevice -ErrorAction Stop -Verbose
} else {
    Write-Host "Device not found in intune (You might want to verify this manually in the Intune Portal)" -ForegroundColor Yellow -BackgroundColor Black
}

Write-Output "Done."