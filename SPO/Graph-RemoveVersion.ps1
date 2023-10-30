# Import required module
Import-Module Microsoft.Graph.Sites

# Set the access token
$token = "<access-token>"

# Get all site collections
$sites = Get-MgSite -All

foreach ($site in $sites) {
    # Get all lists in the site
    $lists = Get-MgSiteList -SiteId $site.Id -All

    foreach ($list in $lists) {
        # Get all items in the list
        $items = Get-MgSiteListItem -SiteId $site.Id -ListId $list.Id -All

        foreach ($item in $items) {
            # Get all versions of the item
            $versions = Get-MgSiteListItemVersion -SiteId $site.Id -ListId $list.Id -ItemId $item.Id -All

            if ($versions.Count -gt 5) {
                # Sort versions by last modified date and select all but the latest 5
                $versionsToRemove = $versions | Sort-Object lastModifiedDateTime | Select-Object -First ($versions.Count - 5)

                foreach ($version in $versionsToRemove) {
                    # Remove the version
                    Remove-MgSiteListItemVersion -SiteId $site.Id -ListId $list.Id -ItemId $item.Id -VersionId $version.Id
                }
            }
        }
    }
}
