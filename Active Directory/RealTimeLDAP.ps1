# Import Active Directory module
Import-Module ActiveDirectory

# Get all domain controllers in the current domain
$DCs = Get-ADDomainController -Filter *

# Define the LDAP port to check
$LDAPPort = 389

# Define a function to test LDAP connection using ADSI
function Test-LDAPConnection {
    param (
        [string]$Server,
        [int]$Port
    )
    try {
        # Create an LDAP connection string with the server and port
        $LDAP = "LDAP://$Server`:$Port"
        # Create an ADSI object with the LDAP connection string
        $Connection = [ADSI]$LDAP
        # Close the connection
        $Connection.Close()
        # Return true if the connection was successful
        return $true
    }
    catch {
        # Return false if the connection failed
        return $false
    }
}

# Define a function to monitor LDAP connections in real time
function Monitor-LDAPConnections {
    param (
        [array]$DCs,
        [int]$LDAPPort,
        [int]$Interval = 10 # Seconds between each check
    )
    # Create an empty hashtable to store the results
    $Results = @{}

    # Loop through each domain controller
    foreach ($DC in $DCs) {
        # Initialize the result for each DC as null
        $Results[$DC.Name] = $null
    }

    # Start an infinite loop
    while ($true) {
        # Loop through each domain controller
        foreach ($DC in $DCs) {
            # Test LDAP connection on port 389 (unsecure)
            $LDAPResult = Test-LDAPConnection -Server $DC.Name -Port $LDAPPort

            # Check if the result is different from the previous one
            if ($LDAPResult -ne $Results[$DC.Name]) {
                # Update the result in the hashtable
                $Results[$DC.Name] = $LDAPResult

                # Create a custom object to store the result
                $Object = [pscustomobject]@{
                    DomainController = $DC.Name
                    LDAP = $LDAPResult
                    TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                }

                # Output the object to the console
                Write-Output $Object

                # Optionally, you can send an email alert or perform other actions based on the result here.
            }
        }

        # Wait for the specified interval before checking again
        Start-Sleep -Seconds $Interval
    }
}

# Call the function to monitor LDAP connections in real time
Monitor-LDAPConnections -DCs $DCs -LDAPPort $LDAPPort -Interval 5

