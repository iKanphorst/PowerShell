# Import the SharePoint Online module
Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking

# Function to authenticate and connect to SharePoint Online
function Connect-SharePoint {
    param (
        [string]$AdminSiteUrl
    )
    
    Write-Host "Connecting to SharePoint Online..." -ForegroundColor Green
    Connect-SPOService -Url $AdminSiteUrl
}

# Function to check if the site is under a retention policy
function Get-RetentionPolicies {
    param (
        [string]$SiteUrl
    )

    Write-Host "Checking retention policies for site: $SiteUrl..." -ForegroundColor Green
    $policies = Get-SPOSite -Identity $SiteUrl | Select-Object -ExpandProperty ComplianceAttribute
    return $policies
}

# Function to forcefully remove grace period status
function Remove-GracePeriodStatus {
    param (
        [string]$SiteUrl
    )
    
    Write-Host "Removing grace period status from site: $SiteUrl..." -ForegroundColor Green
    Set-SPOSite -Identity $SiteUrl -LockState Unlock
}

# Function to delete older versions of files
function Delete-OlderVersions {
    param (
        [string]$SiteUrl,
        [int]$VersionsToKeep,
        [string]$LogFile
    )

    Write-Host "Connecting to site: $SiteUrl" -ForegroundColor Green
    $context = New-Object Microsoft.SharePoint.Client.ClientContext($SiteUrl)
    $credentials = Get-Credential
    $context.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($credentials.Username, $credentials.Password)

    $web = $context.Web
    $context.Load($web)
    $context.ExecuteQuery()

    $lists = $web.Lists
    $context.Load($lists)
    $context.ExecuteQuery()

    $filesDeleted = 0
    $versionsDeleted = 0
    $sizeDeleted = 0

    foreach ($list in $lists) {
        if ($list.BaseTemplate -eq [Microsoft.SharePoint.Client.ListTemplateType]::DocumentLibrary) {
            $context.Load($list)
            $context.ExecuteQuery()

            $query = [Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery()
            $items = $list.GetItems($query)
            $context.Load($items)
            $context.ExecuteQuery()

            foreach ($item in $items) {
                $file = $item.File
                $context.Load($file)
                $context.Load($file.Versions)
                $context.ExecuteQuery()

                $totalVersions = $file.Versions.Count
                if ($totalVersions -gt $VersionsToKeep) {
                    $versionsToDelete = $totalVersions - $VersionsToKeep
                    for ($i = 0; $i -lt $versionsToDelete; $i++) {
                        $version = $file.Versions[$i]
                        $sizeDeleted += $version.Size
                        $version.DeleteObject()
                    }
                    $context.ExecuteQuery()
                    $filesDeleted++
                    $versionsDeleted += $versionsToDelete
                    Add-Content -Path $LogFile -Value "$($file.ServerRelativeUrl), Versions deleted: $versionsToDelete"
                }
            }
        }
    }

    Write-Host "Summary:" -ForegroundColor Green
    Write-Host "Total files processed: $filesDeleted"
    Write-Host "Total versions deleted: $versionsDeleted"
    Write-Host "Total size deleted (bytes): $sizeDeleted"
}

# Main script
$AdminSiteUrl = "https://yourtenant-admin.sharepoint.com"
$SiteUrl = import-csv -Path "CSV PATH HERE"
$VersionsToKeep = 5
$LogFileDeletedVersions = "DeletedVersionsLog.txt"
$LogFileRetentionPolicies = "RetentionPoliciesLog.txt"

Connect-SharePoint -AdminSiteUrl $AdminSiteUrl

    Foreach ($site in $sites) {
        $retentionPolicies = Get-RetentionPolicies -SiteUrl $site.Url

        if ($retentionPolicies -contains "Grace") {
            Remove-GracePeriodStatus -SiteUrl $Site.url
            foreach ($site in $sites) {
                # Get a list of holds for the site
                $holds = Get-SPOComplianceTagHo{ld -Site $site.Url
                foreach ($hold in $holds) {
                    # Check if the hold is orphaned
                    if ($hold.IsOrphaned -eq $true) {
                        # Remove the orphaned hold
                        Remove-SPOComplianceTagHold -Site $site.Url -Identity $hold.Identity
                        Write-Host "Removed orphan hold: $($hold.Identity) from $($site.Url)"
                    }
                    Delete-OlderVersions -SiteUrl $Site.Url -VersionsToKeep $VersionsToKeep -LogFile $LogFileDeletedVersions
                }
        } elseif ($retentionPolicies.Count -gt 0) {
            Add-Content -Path $LogFileRetentionPolicies -Value "Site URL: $Site.Url"
            foreach ($policy in $retentionPolicies) {
                Add-Content -Path $LogFileRetentionPolicies -Value "Retention Policy: $policy"
            }
            Write-Host "The site is under valid retention policies. Please exclude the policies before proceeding." -ForegroundColor Red
        } else {
            Delete-OlderVersions -SiteUrl $Site.Url -VersionsToKeep $VersionsToKeep -LogFile $LogFileDeletedVersions
            }
        }
    }
}
Write-Host "Log files created:"
Write-Host $LogFileDeletedVersions
Write-Host $LogFileRetentionPolicies
