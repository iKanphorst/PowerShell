Connect-ExchangeOnline
$Operations = "FileDeleted, FileDeletedFirstStageRecycleBin, FileDeletedSecondStageRecycleBin, FileRecycled"
$StartDate = (Get-Date).AddDays(-90); $EndDate = (Get-Date)
$FirstStageDeletions = 0; $SecondStageDeletions = 0; $UserDeletions = 0
$OutputFile = "c:\temp\ODSPFileDeletions.CSV"

# Find out what the OneDrive base URL is for the tenant
$Report = [System.Collections.Generic.List[Object]]::new() # Create output file

Write-Host "Searching Office 365 Audit Records to find deletion records for SharePoint Online documents"
[array]$Records = (Search-UnifiedAuditLog -Operations $Operations -StartDate $StartDate -EndDate $EndDate -ResultSize 5000 -Formatted)
If (!($Records)) {
    Write-Host "No audit records for SharePoint Online deletions found."
} Else {
    Write-Host "Processing" $Records.Count "SharePoint Online file deletion records..."
    # Scan each audit record to extract information
    ForEach ($Rec in $Records) {
        $AuditData = ConvertFrom-Json $Rec.Auditdata
        
        # Exclude OneDrive sites
        If ($AuditData.SiteUrl -match "my.sharepoint.com") {
            Continue
        }

        Switch ($AuditData.Operation) {
            "FileDeleted" { # Old Normal deletion
                $Reason = "Moved document to site recycle bin"
                $UserDeletions++
            }
            "FileRecycled" { # New Normal deletion
                $Reason = "Moved document to site recycle bin"
                $UserDeletions++
            }
            "FileDeletedFirstStageRecycleBin" { # Deletion from the first stage recycle bin
                $Reason = "Deleted document from first stage recycle bin"
                $FirstStageDeletions++
            }
            "FileDeletedSecondStageRecycleBin" { # Deletion from the second stage recycle bin
                $Reason = "Deleted document from second stage recycle bin"
                $SecondStageDeletions++
            }
        } #End switch 
        Switch ($AuditData.UserType) {
            "Regular" { # Normal user
                $DeletedBy = "User"
                If ($AuditData.UserId -eq "SHAREPOINT\System") { $DeletedBy = "SharePoint System Account" }
            }
            "CustomPolicy" { #Retention policy
                $DeletedBy = "Retention policy"
            }
        } #End Switch

        If ([string]::IsNullOrWhiteSpace($AuditData.UserAgent)) {
            $UserAgent = "Background process"
        } Else {
            $UserAgent = $AuditData.UserAgent
        }
        $Workload = "SharePoint Online"

        # Handle situation where it's a Teams meeting recording that expires
        If ($AuditData.SourceFileName) {
            $SiteURL  = $AuditData.SiteURL
            $Folder   = $AuditData.SourceRelativeURL
            $FileName = $AuditData.SourceFileName
        } Elseif ($Rec.UserIds -ne "SHAREPOINT\system") {
            $FileName = $AuditData.ObjectId
            $SiteUrl  = $AuditData.SiteURL
            $Folder   = [System.IO.Path]::GetDirectoryName($AuditData.SourceRelativeURL)
        }
        $AuditData

        $ReportLine = [PSCustomObject] @{
            TimeStamp    = Get-Date($AuditData.CreationTime) -format g
            "Deleted by" = $DeletedBy
            User         = $AuditData.UserId
            Site         = $SiteURL
            "Folder"     = $Folder
            "File name"  = $FileName
            Workload     = $Workload
            Reason       = $Reason
            Action       = $AuditData.Operation
            Client       = $UserAgent
        }
        $Report.Add($ReportLine)
    }
}
Write-Host ("All done - SharePoint Online deletions in the period {0} to {1}" -f $StartDate, $EndDate)
Write-Host ""
Write-Host "Deletions from site:                    "  $UserDeletions
Write-Host "Deletions from first stage recycle bin: "  $FirstStageDeletions
Write-Host "Deletions from second stage recycle bin: " $SecondStageDeletions
Write-Host "----------------------------------------------------------------"
Write-Host ""
Write-Host "CSV file containing records is available in" $OutputFile

$Report | Sort-Object Reason, {$_.TimeStamp -as [datetime]} | Select-Object Timestamp, "Deleted By", Reason, User, "File Name", "File size (bytes)", Site, Workload | Out-GridView
$Report | Sort-Object Reason, {$_.TimeStamp -as [datetime]} | Export-CSV -NoTypeInformation $OutputFile 