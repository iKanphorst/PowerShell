# Define the event log to monitor
$eventLog = "Security"

# Define the event ID for Kerberos Authentication events
$eventID = 4769

# Define the non-AES encryption types you want to monitor
$nonAESAlgorithms = @(0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B)

# Define the log file path to save matching events
$logFilePath = "C:\LDAPLog\NonAESAuthentications.log"

# Create a log file if it doesn't exist
if (-not (Test-Path -Path $logFilePath)) {
    New-Item -Path $logFilePath -ItemType File
}

# Function to write event details to the log file
function Write-LogEntry {
    param(
        [string]$message
    )
    Add-Content -Path $logFilePath -Value $message
}

# Function to monitor and filter Kerberos authentication events
function Monitor-KerberosEvents {
    $eventLog = Get-WinEvent -LogName $eventLog -FilterXPath "*[System[EventID=$eventID]]" -MaxEvents 1 -ErrorAction SilentlyContinue
    while ($true) {
        $event = Get-WinEvent -LogName $eventLog -MaxEvents 1 -ErrorAction SilentlyContinue
        if ($event) {
            $xmlEventData = [xml]$event.ToXml()
            $encryptionType = [int]$xmlEventData.Event.EventData.Data | Where-Object { $_.Name -eq "KeyEncryptionType" }
            
            if ($nonAESAlgorithms -contains $encryptionType) {
                $message = "Non-AES Encryption Detected:`r`n"
                $message += "Event ID: $($event.Id)`r`n"
                $message += "Computer: $($event.MachineName)`r`n"
                $message += "Time: $($event.TimeCreated)`r`n"
                $message += "User: $($xmlEventData.Event.EventData.Data | Where-Object { $_.Name -eq "TargetUserName" })."#text"`r`n"
                $message += "Client IP: $($xmlEventData.Event.EventData.Data | Where-Object { $_.Name -eq "IpAddress" })."#text"`r`n"
                $message += "Encryption Type: $($encryptionType)`r`n"
                $message += "---------------------------------------------------`r`n"

                Write-LogEntry -message $message
            }
        }
        Start-Sleep -Seconds 5 # Adjust the polling interval as needed
    }
}

# Start monitoring Kerberos authentication events
Monitor-KerberosEvents
