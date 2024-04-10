Add-Type -AssemblyName System.Windows.Forms

# Create an OpenFileDialog object
$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$openFileDialog.InitialDirectory = $env:SystemRoot
$openFileDialog.Filter = "CSV Files (*.csv)|*.csv"
$openFileDialog.Title = "Select CSV File"

# Show the dialog box and check if the user clicked OK
$null = $openFileDialog.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::Open) {
    # Get the selected CSV file path
    $csvFilePath = $openFileDialog.FileName
    
    # Import the CSV file
    $csvData = Import-CSV -Path $csvFilePath -Verbose
    
    # Display the content of the imported CSV file
    Write-Host ("CSV file {0} imported successfully. Number of sites loaded: {1}`n" -f $csvFilePath, ($csvData | Measure-Object).Count) -ForegroundColor Yellow
} else {
    Write-Host "No file selected."
}
#Parameter
Write-Information -MessageData $
Write-Host "Type the policy name to have the imported sites added to the eclusion list.`n" -ForegroundColor Yellow
$PolicyName = Read-Host 
 
Try {
    #Connect to Compliance Center through Exchange Online Module
    Connect-IPPSSession
 
    #Get the Policy
    Write-Host ("Getting the policy {0}", $policyname) -foregroundcolor Green 
    $Policy = Get-RetentionCompliancePolicy -Identity $PolicyName
 
    If($Policy)
    {
        foreach ($csvDataSite in $csvData){
            #Exclude site from Retention Policy
            Set-RetentionCompliancePolicy -AddSharePointLocationException $csvDataSite.SiteURL -Identity $Policy.Name -Verbose
        }
    }
}
Catch {
    write-host "Error: $($_.Exception.Message)" -foregroundcolor Red
}