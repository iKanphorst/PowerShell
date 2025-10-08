# Prompt for input
$sourceUserEmail = Read-Host "igor@lysenko.uk"
$destinationUserEmail = Read-Host "danillo@lysenko.uk"
$folderName = Read-Host "Enter the name of the folder to migrate (contents only)"
$adminUsername = Read-Host "Enter the Global Admin username"
$adminCredentials = Get-Credential -Credential $adminUsername

# Connect to MSOnline
Connect-MsolService -Credential $adminCredentials
$initialDomain = (Get-MsolDomain | Where-Object {$_.IsInitial -eq $true}).Name.Split(".")[0]

# Construct OneDrive URLs
$sourceUserUnderscore = $sourceUserEmail -replace "[^a-zA-Z]", "_"
$destinationUserUnderscore = $destinationUserEmail -replace "[^a-zA-Z]", "_"
$sourceOneDriveSite = "https://$initialDomain-my.sharepoint.com/personal/$sourceUserUnderscore"
$destinationOneDriveSite = "https://$initialDomain-my.sharepoint.com/personal/$destinationUserUnderscore"
$sharePointAdminURL = "https://$initialDomain-admin.sharepoint.com"

# Grant admin access
Connect-SPOService -Url $sharePointAdminURL -Credential $adminCredentials
Set-SPOUser -Site $sourceOneDriveSite -LoginName $adminUsername -IsSiteCollectionAdmin $true
Set-SPOUser -Site $destinationOneDriveSite -LoginName $adminUsername -IsSiteCollectionAdmin $true

# Connect to source OneDrive
Connect-PnPOnline -Url $sourceOneDriveSite -Credentials $adminCredentials

# Get all items in the folder
$sourceFolderPath = "Documents/$folderName"
$folderItems = Get-PnPListItem -List Documents -PageSize 1000 | Where-Object {
    $_.FieldValues.FileRef -like "*$sourceFolderPath/*"
}

# Connect to destination OneDrive
Connect-PnPOnline -Url $destinationOneDriveSite -Credentials $adminCredentials

# Copy contents to root
foreach ($item in $folderItems) {
    $relativePath = $item.FieldValues.FileRef -replace "^.*?$folderName/", ""
    $targetPath = "Documents/$relativePath"

    if ($item.FileSystemObjectType -eq "Folder") {
        Ensure-PnPFolder -SiteRelativePath $targetPath
    } elseif ($item.FileSystemObjectType -eq "File") {
        $sourceUrl = $item.FieldValues.FileRef
        Copy-PnPFile -SourceUrl $sourceUrl -TargetUrl $targetPath -OverwriteIfAlreadyExists -Force
    }
}

# Revoke admin access
Set-SPOUser -Site $sourceOneDriveSite -LoginName $adminUsername -IsSiteCollectionAdmin $false
Set-SPOUser -Site $destinationOneDriveSite -LoginName $adminUsername -IsSiteCollectionAdmin $false

Write-Host "✅ Contents of '$folderName' migrated successfully to the root of $destinationUserEmail's OneDrive."