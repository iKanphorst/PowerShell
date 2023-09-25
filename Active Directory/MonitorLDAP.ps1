# Define the LDAP event ID (2887) for unencrypted LDAP traffic
$ldapEventId = 2887
$logFilePath = "C:\Path\To\Log\ldap_unencrypted.log"  # Specify the path for the log file

# Define a function to handle LDAP event log entries
function Handle-LdapEvent($event) {
    $message = $event.Message
    $sourceIp = [System.Net.IPAddress]::Parse($event.Properties[0].Value)
    $destinationIp = [System.Net.IPAddress]::Parse($event.Properties[1].Value)

    # Log the event to a file
    $logEntry = @"
Unencrypted LDAP Traffic Detected!
Source IP: $sourceIp
Destination IP: $destinationIp
Event Message: $message
------------------------
"@
    
    $logEntry | Out-File -FilePath $logFilePath -Append -Encoding UTF8

    Write-Host "Unencrypted LDAP Traffic Detected!"
    Write-Host "Source IP: $sourceIp"
    Write-Host "Destination IP: $destinationIp"
    Write-Host "Event Message: $message"
    Write-Host "------------------------"
    
    # You can add additional actions here, such as sending an email notification.
}

# Start monitoring for LDAP events
Write-Host "Monitoring for unencrypted LDAP traffic (Event ID $ldapEventId). Press Ctrl+C to exit."

# Keep the script running
try {
    while ($true) {
        # Get LDAP events from the Security log
        $ldapEvents = Get-WinEvent -LogName "Security" -FilterXPath @"
        <QueryList>
          <Query Id="0" Path="Security">
            <Select Path="Security">
              *[System[(EventID=$ldapEventId)]]
            </Select>
          </Query>
        </QueryList>
"@
        foreach ($event in $ldapEvents) {
            Handle-LdapEvent $event
        }
        Start-Sleep -Seconds 5
    }
}
catch {
    # Handle any errors here
}
