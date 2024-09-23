# Import the SharePoint Online module
Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking

# Function to authenticate and connect to SharePoint Online
function Connect-SharePoint {
    param (
        [string]$AdminSiteUrl
    )
        Write-Host "Connecting to SharePoint Online..." -ForegroundColor Green
        Connect-PnPOnline -Url $AdminSiteUrl.Replace("-admin","") -UseWebLogin
    }

# Function to delete older versions of files
function Remove-OlderVersions {
    param (
        [string]$SiteUrl,
        [int]$VersionsToKeep,
        [string]$LogFile
    )
    Write-Host "Connecting to site: $SiteUrl" -ForegroundColor Green
    Connect-PnPOnline -Url $SiteUrl -UseWebLogin
    Write-Host ("Gathering PNP List for site {0}" -f $SiteURL) -ForegroundColor Yellow
    $lists = Get-PnPList | Where-Object {($_.basetemplate -eq 101) -and ($_.EntityTypeName -like "*Documents*")}
    foreach ($list in $lists) {
        Write-Host ("Gathering items under the PNP List {0}" -f $list.Title) -ForegroundColor Yellow
        Write-Host ("Gathering files under folder {0}" -f $list.Title) -ForegroundColor Yellow
        $files = Get-PnPFolderItem -Identity $list.Title -ErrorAction SilentlyContinue
        foreach ($file in $files){
            Write-Host ("Gathering file versions for file {0}" -f $file.ServerRelativeUrl) -ForegroundColor Yellow
            $versions = Get-PnPFileVersion -url $file.ServerRelativeUrl -ErrorAction SilentlyContinue
            $totalVersions = $versions.Count
            if ($totalVersions -ge $VersionsToKeep) {
                $versionsToDelete = $totalVersions - $VersionsToKeep
                $lastModified = $file.TimeLastModified
                $threeMonthsAgo = (Get-Date).AddMonths(-3)
                if ($lastModified -lt $threeMonthsAgo) {
                    for ($i = 0; $i -lt $versionsToDelete; $i++) {
                        $version = $versions[$i]
                        $sizeDeleted += $version.Size
                        #Remove-PnPFileVersion -File $file.ServerRelativeUrl -VersionLabel $version.VersionLabel
                    }
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
$AdminSiteUrl = "https://tjmt-admin.sharepoint.com"
$Sites = import-csv -Path "D:\SPOSites\SharePointSites.csv"
$VersionsToKeep = 1
$LogFileDeletedVersions = "D:\SPOSites\SharepointLog.txt"
Connect-SharePoint -AdminSiteUrl $AdminSiteUrl
$deletedVersionsLog = @()
Foreach ($site in $sites) {
    $deletedVersionsLog += Remove-OlderVersions -SiteUrl $Site.url -VersionsToKeep $VersionsToKeep -LogFile $LogFileDeletedVersions
}
$deletedVersionsLog | Out-File -FilePath $LogFileDeletedVersions
Write-Host "Log files created:"
Write-Host $LogFileDeletedVersions