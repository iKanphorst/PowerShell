# Connect to SharePoint Online
$adminSiteUrl = "https://your-tenant-admin.sharepoint.com"
Connect-SPOService -Url $adminSiteUrl

# Get storage usage before retention policy
$beforeRetention = @()
$sites = Get-SPOSite -IncludePersonalSite $false -Limit All
foreach ($site in $sites) {
    $beforeRetention += [pscustomobject]@{
        Url = $site.Url
        StorageUsage = $site.StorageUsageCurrent
    }
}

# Save the data to a file (optional)
$beforeRetention | Export-Csv -Path "BeforeRetention.csv" -NoTypeInformation

# (Apply the retention policy and wait for it to take effect)

# Get storage usage after retention policy
$afterRetention = @()
foreach ($site in $sites) {
    $afterRetention += [pscustomobject]@{
        Url = $site.Url
        StorageUsage = $site.StorageUsageCurrent
    }
}

# Save the data to a file (optional)
$afterRetention | Export-Csv -Path "AfterRetention.csv" -NoTypeInformation

# Compare the storage usage
$comparison = @()
for ($i = 0; $i -lt $beforeRetention.Count; $i++) {
    $comparison += [pscustomobject]@{
        Url = $beforeRetention[$i].Url
        BeforeStorageUsage = $beforeRetention[$i].StorageUsage
        AfterStorageUsage = $afterRetention[$i].StorageUsage
        SpaceFreed = $beforeRetention[$i].StorageUsage - $afterRetention[$i].StorageUsage
    }
}

# Output the comparison
$comparison | Format-Table -AutoSize
