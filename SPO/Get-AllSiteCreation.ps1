#Parameters
$TenantURL =  "https://kanphorst.sharepoint.com"
  
#Get Credentials to connect
#$Credential = Get-Credential
  
#Frame Tenant Admin URL from Tenant URL
$TenantAdminURL = $TenantURL.Insert($TenantURL.IndexOf("."),"-admin")
 
#Connect to Admin Center
Connect-PnPOnline -Url $TenantAdminURL -UseWebLogin
  
#Get All Site collections - Filter BOT and MySite Host
$Sites = Get-PnPTenantSite -Filter "Url -like '$TenantURL'"
 
#Iterate through all sites
$SiteInventory = @()
$Sites | ForEach-Object {

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