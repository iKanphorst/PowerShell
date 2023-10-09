Connect-IPPSSession
$Report = [System.Collections.Generic.List[Object]]::new() 
[array]$Policies = (Get-RetentionCompliancePolicy -ExcludeTeamsPolicy -DistributionDetail | ? {$_.SharePointLocation -ne $Null})
ForEach ($P in $Policies) {
        If ($P.SharePointLocation.Name -eq "All") {
            $ReportLine = [PSCustomObject]@{
              PolicyName = $P.Name
              SiteName   = "All SharePoint Sites"
              SiteURL    = "All SharePoint Sites" }
            $Report.Add($ReportLine) } 
            If ($P.SharePointLocationException -ne $Null) {
               $Locations = ($P | Select -ExpandProperty SharePointLocationException)
               ForEach ($L in $Locations) {
                  $Exception = "*Exclude* " + $L.DisplayName
                  $ReportLine = [PSCustomObject]@{
                    PolicyName = $P.Name
                    SiteName   = $Exception
                    SiteURL    = $L.Name }
               $Report.($ReportLine) }
        }
        ElseIf ($P.SharePointLocation.Name -ne "All") {
           $Locations = ($P | Select -ExpandProperty SharePointLocation)
           ForEach ($L in $Locations) {
               $ReportLine = [PSCustomObject]@{
                  PolicyName = $P.Name
                  SiteName   = $L.DisplayName
                  SiteURL    = $L.Name }
               $Report.Add($ReportLine)  }                    
          }
}