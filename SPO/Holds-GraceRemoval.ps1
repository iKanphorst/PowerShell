# Install the SharePointPnPPowerShellOnline module if you haven't already
Install-Module SharePointPnPPowerShellOnline -Force

# Import the SharePointPnPPowerShellOnline module
Import-Module SharePointPnPPowerShellOnline

# Connect to SharePoint Online (you will be prompted to enter credentials)
Connect-PnPOnline -Url "https://m365ace.sharepoint.com" -Tenant "m365ace.onmicrosoft.com" -Thumbprint 5E28FC22260A069426C5D4B32C733C95F5306EAC

# Get all site collections
$siteCollections = Get-PnPTenantSite

# Loop through each site collection
foreach ($site in $siteCollections) {
    Write-Host "Processing site:" $site.Url
    
    # Connect to the site collection
    Connect-PnPOnline -Url $site.Url -ClientID "b14b9f1b-6477-4965-ae90-298a683db40c" -Thumbprint 5E28FC22260A069426C5D4B32C733C95F5306EAC 
    
    # Retrieve the access token to authenticate with Microsoft Graph
    $accessToken = Get-PnPGraphAccessToken 

    # Define the endpoint to retrieve the holds
    $uri = "https://graph.microsoft.com/v1.0/sites/$($site.Url)/holds"

    # Invoke the REST API to get the holds
    $holds = Invoke-RestMethod -Uri $uri -Headers @{Authorization = "Bearer $($accessToken.AccessToken)"} -Method Get

    # Remove holds in the grace period
    foreach ($hold in $holds.value) {
        # Check if the hold is in the grace period
        if ($hold.status -eq "Pending") {
            Write-Host "Removing hold:" $hold.displayName -ForegroundColor Yellow
            # Define the endpoint to remove the hold
            $removeUri = "https://graph.microsoft.com/v1.0/sites/$($site.Url)/holds/$($hold.id)"
            # Invoke the REST API to remove the hold
            Invoke-RestMethod -Uri $removeUri -Headers @{Authorization = "Bearer $($accessToken.AccessToken)"} -Method Delete -Verbose
        }
    }
    
    # Disconnect from the site collection
    Disconnect-PnPOnline
}

# Disconnect from SharePoint Online
Disconnect-PnPOnline
