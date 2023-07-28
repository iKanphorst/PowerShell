#
# Find archive-enabled mailboxes and report their status
[array]$Mbx = Get-ExoMailbox -RecipientTypeDetails SharedMailbox, UserMailbox -Filter {ArchiveStatus -eq "Active"} -ResultSize Unlimited -Properties ArchiveQuota, ArchiveStatus, AutoExpandingArchiveEnabled, RecipientTypeDetails, ArchiveGuid
If ($Mbx -eq 0) { Write-Host "No mailboxes found with archives" ; break}

$Report = [System.Collections.Generic.List[Object]]::new()
ForEach ($M in $Mbx) {
   Write-Host "Processing mailbox" $M.DisplayName
   $ExpandingArchive = "No"
   If ($M.AutoExpandingArchiveEnabled -eq $True) { $ExpandingArchive = "Yes" }
   $Stats = Get-ExoMailboxStatistics -Archive -Identity $M.UserPrincipalName
   [string]$ArchiveSize = $Stats.TotalItemSize.Value
   [string]$DeletedArchiveItems = $Stats.TotalDeletedItemSize.Value 
    
   $ReportLine = [PSCustomObject][Ordered]@{  
       Mailbox             = $M.DisplayName
       UPN                 = $M.UserPrincipalName
       Type                = $M.RecipientTypeDetails
       ArchiveQuota        = $M.ArchiveQuota.Split("(")[0] 
       Expanding           = $ExpandingArchive
       ArchiveStatus       = $M.ArchiveStatus
       ArchiveSize         = $ArchiveSize.Split("(")[0] 
       ArchiveItems        = $Stats.ItemCount
       DeletedArchiveItems = $DeletedArchiveItems.Split("(")[0] 
       DeletedItems        = $Stats.DeletedItemCount  
       ArchiveGuid         = $M.ArchiveGuid  
    }
    $Report.Add($ReportLine) 
} #End ForEach

Write-Host ("{0} mailboxes processed" -f $Mbx.count)
$Report | Out-GridView 
$Report | Export-CSV -NoTypeInformation c:\temp\ArchiveMailboxes.csv