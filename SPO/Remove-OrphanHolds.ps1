# Connect to SharePoint Online
Connect-SPOService -Url "https://your-domain-admin.sharepoint.com"

# Get a list of sites
$sites = Get-SPOSite -Limit All

foreach ($site in $sites) {
    # Get a list of holds for the site
    $holds = Get-SPOComplianceTagHold -Site $site.Url

    foreach ($hold in $holds) {
        # Check if the hold is orphaned
        if ($hold.IsOrphaned -eq $true) {
            # Remove the orphaned hold
            Remove-SPOComplianceTagHold -Site $site.Url -Identity $hold.Identity
            Write-Host "Removed orphan hold: $($hold.Identity) from $($site.Url)"
        }
    }
}

# Disconnect from SharePoint Online
Disconnect-SPOService
