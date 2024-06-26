# Import the required module
Import-Module Microsoft.Graph

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "AuditLog.Read.All"

# Function to get the audit logs for delete actions
function Get-DeletedFilesAndSites {
    param (
        [Parameter(Mandatory=$true)]
        [string]$StartTime,
        
        [Parameter(Mandatory=$true)]
        [string]$EndTime
    )

    $deletedFiles = @()

    # Get the audit logs within the specified timeframe
    $auditLogs = Get-MgAuditLogSignIn -Filter "activityDisplayName eq 'FileDeleted' or activityDisplayName eq 'SiteDeleted' and activityDateTime ge $StartTime and activityDateTime le $EndTime"

    foreach ($log in $auditLogs) {
        if ($log.ActivityDisplayName -eq "FileDeleted") {
            $deletedFiles += [PSCustomObject]@{
                FileName = $log.TargetResources.ResourceName
                DateDeleted = $log.ActivityDateTime
            }
        }
    }

    return $deletedFiles
}

# Specify the timeframe for the logs
$startTime = "2024-06-01T00:00:00Z"
$endTime = "2024-06-19T23:59:59Z"

# Get the deleted files
$deletedFiles = Get-DeletedFilesAndSites -StartTime $startTime -EndTime $endTime

# Output the list of deleted files
$deletedFiles | Format-Table -Property FileName, DateDeleted

# Calculate the total size of deleted files in GB
$totalSizeGB = ($deletedFiles | Measure-Object -Property FileSize -Sum).Sum
Write-Output "Total size of deleted files: $([math]::Round($totalSizeGB, 2)) GB"
