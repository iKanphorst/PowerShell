# Ensure PnP.Powershell module is installed and loaded
if (-not (Get-Module -ListAvailable -Name "PnP.Powershell")) {
    Install-Module -Name "PnP.Powershell" -Force -AllowClobber
}

# Define parameters
$csvPath = "CSV Path" # CSV containing the site URLs
$logFilePath = "LOG Path" # Log file for purged versions
$minVersionsToKeep = X # Define minimum number of versions to keep
$lastModifiedLimit = (Get-Date).AddMonths(-3) # Files modified within the last 3 months will be ignored

#Connect to the Admin Site
Connect-PnPOnline -Url "https://YourTenant-admin.sharepoint.com" -Interactive -ClientId <ClientID>

# Function to log purge details
function Log-PurgeDetails {
    param(
        [string]$fileUrl,
        [int]$versionsDeleted,
        [int64]$sizeFreed
    )
    $logMessage = "$(Get-Date) - File: $fileUrl, Versions Deleted: $versionsDeleted, Size Freed: $sizeFreed bytes"
    Add-Content -Path $logFilePath -Value $logMessage
}

# Import the list of sites from CSV
$sites = Import-Csv -Path $csvPath

foreach ($site in $sites) {
    $siteUrl = $site.Url # Assuming the CSV contains a column named 'Url'

    try {
        # Connect to the SharePoint site
        Connect-PnPOnline -Url $siteUrl -Interactive -ClientId <ClientID>

        # Get all document libraries in the site
        $docLibraries = Get-PnPList | Where-Object { $_.BaseTemplate -eq 101 } # 101 is the template ID for Document Libraries

        foreach ($docLibrary in $docLibraries) {
            # Get all files from the document library
            Write-Output ("Processing {0} list" -f $docLibrary.Title)
            $files = Get-PnPListItem -List $docLibrary.Id -PageSize 1000 | Where-Object { $_.FileSystemObjectType -eq "File" }

            foreach ($file in $files) {
                Write-Output ("Processing file {0}" -f $file.FieldValues.FileRef)
                $fileItem = Get-PnPFile -Url $file.FieldValues.FileRef -AsListItem

                # Check the last modified date
                $lastModified = [datetime]$fileItem["Modified"]

                if ($lastModified -lt $lastModifiedLimit) {
                    # Get file version info
                    $versions = Get-PnPFileVersion -Url $file.FieldValues.FileRef
                    

                    if ($versions.Count -ge $minVersionsToKeep) {
                        $versionsToDelete = $versions | Select-Object -Skip $minVersionsToKeep
                        $sizeFreed = 0
                        $versionsDeleted = 0

                        foreach ($version in $versionsToDelete) {
                            # Delete the version
                            Remove-PnPFileVersion -Url $file.FieldValues.FileRef -Identity $version.ID -Force -Verbose

                            # Calculate the space freed (approximate, by using size of the version if available)
                            $sizeFreed += $version.Size
                            $versionsDeleted++
                        }

                        # Log the purge details
                        Log-PurgeDetails -fileUrl $file.FieldValues.FileRef -versionsDeleted $versionsDeleted -sizeFreed $sizeFreed
                    }
                }
            }
        }
    } catch {
        Write-Host "Error processing site: $siteUrl/n. Error details: $_"
    } finally {
        # Close PnP connection for the current site
        Disconnect-PnPOnline -Verbose
    }
}

# Close the script
Write-Host "Version purging process completed." -ForegroundColor Green
