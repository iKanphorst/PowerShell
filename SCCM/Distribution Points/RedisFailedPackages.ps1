# Import the Configuration Manager module
Import-Module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')

# Change to the drive of the site you're working with
cd "TJC:"

# Get all distribution points
$DPs = Get-CMDistributionPoint

# Loop through each distribution point
foreach ($DP in $DPs) {
    # Get all packages from the distribution point
    $Packages = Get-CMPackageStatusDistributionPoint | Where-Object { $_.ServerNALPath -eq $DP.NALPath }

    # Loop through each package
    foreach ($Package in $Packages) {
        # Check if the package status is 'Failed'
        if ($Package.State -eq 'Failed') {
            # Redistribute the failed package
            Start-CMContentDistribution -PackageId $Package.PackageID -DistributionPointName $DP.NetworkOSPath
        }
    }
}