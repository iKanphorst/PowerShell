<#
.SYNOPSIS
    Creates an SCCM collection and adds computers from a CSV file as direct members.

.DESCRIPTION
    This script creates a new device collection in SCCM and adds computers listed in a CSV file
    as direct members to that collection. It requires the ConfigurationManager PowerShell module.
    
    If no CSV path is provided, a file dialog will open to select the CSV file.

.PARAMETER SiteCode
    The site code of the SCCM site.

.PARAMETER SiteServer
    The FQDN of the SCCM site server.

.PARAMETER CollectionName
    The name for the new collection to be created.

.PARAMETER CollectionFolderPath
    The folder path where the collection should be created (e.g., "DeviceCollection\MyFolder").

.PARAMETER LimitingCollectionName
    The name of the limiting collection for the new collection.

.PARAMETER CSVPath
    The path to the CSV file containing the computer names. If not provided, a file dialog will open to select the file.

.PARAMETER ComputerNameColumn
    The column name in the CSV file that contains the computer names.

.PARAMETER RefreshType
    The refresh type for the collection. Valid values are "Manual", "Periodic", "Continuous", or "Both".

.PARAMETER RefreshSchedule
    The schedule for periodic refresh (only used if RefreshType is "Periodic" or "Both").

.EXAMPLE
    .\Create-SCCMCollectionFromCSV.ps1 -SiteCode "P01" -SiteServer "sccm.contoso.com" -CollectionName "Computers from CSV" -CollectionFolderPath "DeviceCollection\MyCollections" -LimitingCollectionName "All Systems" -ComputerNameColumn "ComputerName" -RefreshType "Manual"
    
    This example will open a file dialog to select the CSV file.

.EXAMPLE
    .\Create-SCCMCollectionFromCSV.ps1 -SiteCode "P01" -SiteServer "sccm.contoso.com" -CollectionName "Computers from CSV" -CollectionFolderPath "DeviceCollection\MyCollections" -LimitingCollectionName "All Systems" -CSVPath "C:\Temp\Computers.csv" -ComputerNameColumn "ComputerName" -RefreshType "Manual"
    
    This example uses the specified CSV file path.

.NOTES
    File Name      : Create-SCCMCollectionFromCSV.ps1
    Author         : Your Name
    Prerequisite   : ConfigurationManager PowerShell module
    Date           : Date Created
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SiteCode,

    [Parameter(Mandatory = $true)]
    [string]$SiteServer,

    [Parameter(Mandatory = $true)]
    [string]$CollectionName,

    [Parameter(Mandatory = $false)]
    [string]$CollectionFolderPath,

    [Parameter(Mandatory = $true)]
    [string]$LimitingCollectionName,

    [Parameter(Mandatory = $false)]
    [string]$CSVPath,

    [Parameter(Mandatory = $true)]
    [string]$ComputerNameColumn,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Manual", "Periodic", "Continuous", "Both")]
    [string]$RefreshType = "Manual",

    [Parameter(Mandatory = $false)]
    [string]$RefreshSchedule
)

# Load required assemblies for UI elements
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName PresentationFramework

function Show-FileDialog {
    [CmdletBinding()]
    param()
    
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "CSV Files (*.csv)|*.csv|All Files (*.*)|*.*"
    $openFileDialog.Title = "Select CSV File with Computer Names"
    $openFileDialog.Multiselect = $false
    
    if ($openFileDialog.ShowDialog() -eq 'OK') {
        return $openFileDialog.FileName
    }
    else {
        Write-Error "No file selected. Operation cancelled."
        exit 1
    }
}

function Connect-SCCM {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SiteCode,
        
        [Parameter(Mandatory = $true)]
        [string]$SiteServer
    )

    # Import the ConfigurationManager module
    if (-not (Get-Module ConfigurationManager)) {
        try {
            Import-Module (Join-Path $(Split-Path $ENV:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1) -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to import the ConfigurationManager module. Make sure the SCCM console is installed on this machine."
            exit 1
        }
    }

    # Connect to the site
    try {
        $CMSiteConnection = New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $SiteServer -ErrorAction Stop
        Set-Location "$($SiteCode):" -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to connect to the SCCM site. Error: $($_.Exception.Message)"
        exit 1
    }

    Write-Host "Successfully connected to SCCM site $SiteCode on server $SiteServer" -ForegroundColor Green
}

function Create-SCCMCollection {
    param (
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $true)]
        [string]$LimitingCollectionName,
        
        [Parameter(Mandatory = $false)]
        [string]$CollectionFolderPath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Manual", "Periodic", "Continuous", "Both")]
        [string]$RefreshType = "Manual",
        
        [Parameter(Mandatory = $false)]
        [string]$RefreshSchedule
    )

    # Check if collection already exists
    $existingCollection = Get-CMDeviceCollection -Name $CollectionName
    if ($existingCollection) {
        Write-Warning "A collection with the name '$CollectionName' already exists. Using the existing collection."
        return $existingCollection
    }

    # Get the limiting collection ID
    $limitingCollection = Get-CMDeviceCollection -Name $LimitingCollectionName
    if (-not $limitingCollection) {
        Write-Error "Limiting collection '$LimitingCollectionName' not found."
        exit 1
    }

    # Create the collection
    try {
        $newCollectionParams = @{
            Name = $CollectionName
            LimitingCollectionId = $limitingCollection.CollectionID
        }

        # Set refresh type
        switch ($RefreshType) {
            "Manual" {
                $newCollectionParams.Add("RefreshType", "Manual")
            }
            "Periodic" {
                $newCollectionParams.Add("RefreshType", "Periodic")
                if ($RefreshSchedule) {
                    $schedule = New-CMSchedule -RecurInterval Days -RecurCount 7 # Default weekly
                    if ($RefreshSchedule -eq "Daily") {
                        $schedule = New-CMSchedule -RecurInterval Days -RecurCount 1
                    }
                    elseif ($RefreshSchedule -eq "Weekly") {
                        $schedule = New-CMSchedule -RecurInterval Days -RecurCount 7
                    }
                    elseif ($RefreshSchedule -eq "Monthly") {
                        $schedule = New-CMSchedule -RecurInterval Days -RecurCount 30
                    }
                    $newCollectionParams.Add("RefreshSchedule", $schedule)
                }
            }
            "Continuous" {
                $newCollectionParams.Add("RefreshType", "Continuous")
            }
            "Both" {
                $newCollectionParams.Add("RefreshType", "Both")
                if ($RefreshSchedule) {
                    $schedule = New-CMSchedule -RecurInterval Days -RecurCount 7 # Default weekly
                    if ($RefreshSchedule -eq "Daily") {
                        $schedule = New-CMSchedule -RecurInterval Days -RecurCount 1
                    }
                    elseif ($RefreshSchedule -eq "Weekly") {
                        $schedule = New-CMSchedule -RecurInterval Days -RecurCount 7
                    }
                    elseif ($RefreshSchedule -eq "Monthly") {
                        $schedule = New-CMSchedule -RecurInterval Days -RecurCount 30
                    }
                    $newCollectionParams.Add("RefreshSchedule", $schedule)
                }
            }
        }

        $newCollection = New-CMDeviceCollection @newCollectionParams
        Write-Host "Successfully created collection '$CollectionName'" -ForegroundColor Green

        # Move the collection to the specified folder if provided
        if ($CollectionFolderPath -and $newCollection) {
            try {
                $folderPath = "$($SiteCode):\DeviceCollection\$CollectionFolderPath"
                if (-not (Test-Path $folderPath)) {
                    Write-Warning "Folder path '$folderPath' does not exist. The collection will be created in the root folder."
                }
                else {
                    Move-CMObject -InputObject $newCollection -FolderPath $folderPath
                    Write-Host "Moved collection to folder '$CollectionFolderPath'" -ForegroundColor Green
                }
            }
            catch {
                Write-Warning "Failed to move collection to folder '$CollectionFolderPath'. Error: $($_.Exception.Message)"
            }
        }

        return $newCollection
    }
    catch {
        Write-Error "Failed to create collection. Error: $($_.Exception.Message)"
        exit 1
    }
}

function Add-ComputersToCollection {
    param (
        [Parameter(Mandatory = $true)]
        [string]$CollectionID,
        
        [Parameter(Mandatory = $false)]
        [string]$CSVPath,
        
        [Parameter(Mandatory = $true)]
        [string]$ComputerNameColumn
    )

    # If CSVPath is not provided, show file dialog
    if ([string]::IsNullOrEmpty($CSVPath)) {
        Write-Host "No CSV path provided. Opening file dialog to select CSV file..." -ForegroundColor Cyan
        $CSVPath = Show-FileDialog
        Write-Host "Selected CSV file: $CSVPath" -ForegroundColor Cyan
    }

    # Check if CSV file exists
    if (-not (Test-Path $CSVPath)) {
        Write-Error "CSV file not found at path: $CSVPath"
        exit 1
    }

    # Import CSV
    try {
        $computers = Import-Csv -Path $CSVPath
    }
    catch {
        Write-Error "Failed to import CSV file. Error: $($_.Exception.Message)"
        exit 1
    }

    # Check if the specified column exists
    if (-not ($computers | Get-Member -Name $ComputerNameColumn -MemberType NoteProperty)) {
        Write-Error "Column '$ComputerNameColumn' not found in the CSV file."
        exit 1
    }

    $addedCount = 0
    $errorCount = 0
    $alreadyExistsCount = 0

    # Add each computer to the collection
    foreach ($computer in $computers) {
        $computerName = $computer.$ComputerNameColumn
        
        if ([string]::IsNullOrWhiteSpace($computerName)) {
            Write-Warning "Empty computer name found in CSV. Skipping."
            continue
        }

        # Check if the computer exists in SCCM
        $resourceID = Get-CMDevice -Name $computerName | Select-Object -ExpandProperty ResourceID -ErrorAction SilentlyContinue
        
        if (-not $resourceID) {
            Write-Warning "Computer '$computerName' not found in SCCM. Skipping."
            $errorCount++
            continue
        }

        # Check if the computer is already a member of the collection
        $existingMember = Get-CMDeviceCollectionDirectMembershipRule -CollectionId $CollectionID | 
            Where-Object { $_.RuleName -eq $computerName }
        
        if ($existingMember) {
            Write-Host "Computer '$computerName' is already a member of the collection. Skipping." -ForegroundColor Yellow
            $alreadyExistsCount++
            continue
        }

        # Add the computer to the collection
        try {
            Add-CMDeviceCollectionDirectMembershipRule -CollectionId $CollectionID -ResourceId $resourceID
            Write-Host "Added computer '$computerName' to the collection." -ForegroundColor Green
            $addedCount++
        }
        catch {
            Write-Warning "Failed to add computer '$computerName' to the collection. Error: $($_.Exception.Message)"
            $errorCount++
        }
    }

    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "- Total computers in CSV: $($computers.Count)" -ForegroundColor Cyan
    Write-Host "- Successfully added: $addedCount" -ForegroundColor Green
    Write-Host "- Already in collection: $alreadyExistsCount" -ForegroundColor Yellow
    Write-Host "- Failed to add: $errorCount" -ForegroundColor Red
}

# Main script execution
try {
    # Connect to SCCM
    Connect-SCCM -SiteCode $SiteCode -SiteServer $SiteServer

    # Create the collection
    $collection = Create-SCCMCollection -CollectionName $CollectionName -LimitingCollectionName $LimitingCollectionName -CollectionFolderPath $CollectionFolderPath -RefreshType $RefreshType -RefreshSchedule $RefreshSchedule

    # Add computers from CSV to the collection
    if ($collection) {
        Add-ComputersToCollection -CollectionID $collection.CollectionID -CSVPath $CSVPath -ComputerNameColumn $ComputerNameColumn
    }

    # Return to the original location
    Set-Location $env:USERPROFILE
    Write-Host "Script completed successfully." -ForegroundColor Green
}
catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    # Return to the original location
    Set-Location $env:USERPROFILE
    exit 1
}
