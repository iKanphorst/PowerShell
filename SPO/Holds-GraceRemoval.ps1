# Install the SharePointPnPPowerShellOnline module if you haven't already
Install-Module SharePointPnPPowerShellOnline -Force

# Import the SharePointPnPPowerShellOnline module
Import-Module SharePointPnPPowerShellOnline

param (
    [Parameter(Mandatory)]
    [string]$CentralURL
)

# Connect to SharePoint Online (you will be prompted to enter credentials)
Connect-PnPOnline -Url "https://"+$CentralURL -Interactive

# Get all site collections
$siteCollections = Get-PnPTenantSite

# Loop through each site collection
foreach ($site in $siteCollections) {
    Write-Host "Processing site:" $site.Url
    
    # Connect to the site collection
    Connect-PnPOnline -Url $site.Url -UseWebLogin 
    
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
