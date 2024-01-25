#Parameters
$TenantURL =  "https://crescent.sharepoint.com"
  
#Get Credentials to connect
$Credential = Get-Credential
  
#Frame Tenant Admin URL from Tenant URL
$TenantAdminURL = $TenantURL.Insert($TenantURL.IndexOf("."),"-admin")
 
#Connect to Admin Center
Connect-PnPOnline -Url $TenantAdminURL -Credentials $Credential
  
#Get All Site collections - Filter BOT and MySite Host
$Sites = Get-PnPTenantSite -Filter "Url -like '$TenantURL'"
 
#Iterate through all sites
$SiteInventory = @()
$Sites | ForEach-Object {
    #Connect to each site collection
    Connect-PnPOnline -Url $_.URL -Credentials $Credential
 
    #Get the Root Web with "created" property
    $Web = Get-PnPWeb -Includes Created
 
    #Collect Data
    $SiteInventory += New-Object PSObject -Property  ([Ordered]@{
        "Site Name"  = $Web.Title
        "URL "= $Web.URL
        "Created Date" = $Web.Created
    })
}
#Sort Site Collection - Sort by Creation Date
$SiteInventory | Sort-Object 'Created Date' -Descending