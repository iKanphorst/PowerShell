[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Import required modules
Install-Module SharePointPnPPowerShellOnline

# Set variables
$tenant = "yourtenant"
$username = "adminaccount@yourtenant.onmicrosoft.com"

# Connect to SharePoint Online
Connect-PnPOnline -Url https://$tenant-admin.sharepoint.com -UseWebLogin

# Get all site collections
$sites = Get-PnPTenantSite

foreach ($site in $sites) {
    # Connect to the site collection
    Connect-PnPOnline -Url $site.Url -UseWebLogin

    # Get all lists in the site collection
    $lists = Get-PnPList

    foreach ($list in $lists) {
        if ($list.BaseType -eq "DocumentLibrary" -and $list.Hidden -eq $false) {
            # Get all items in the list
            $items = Get-PnPListItem -List $list

            foreach ($item in $items) {
                # Get all versions of the item
                $versions = Get-PnPProperty -ClientObject $item -Property "Versions"

                if ($versions.Count -gt 5) {
                    # Only keep the 5 most recent versions
                    for ($i = 5; $i -lt $versions.Count; $i++) {
                        # Delete the version
                        $versions[$i].DeleteObject()
                    }
                }
            }
        }
    }
}
