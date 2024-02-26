$Results = @()
$AllSC = Get-PnPTenantSite
 
foreach ($SC in $AllSC){
    Write-Host "Connecting to" $SC.Url -ForegroundColor Green
    Try{    
        Connect-PnPOnline -Url ($SC).Url -Credentials $creds -ErrorAction Stop
        $Policy = Get-PnPSitePolicy
        $SCProps = @{
            Url = $SC.Url
            Name = $Policy.Name
            Description = $Policy.Description
        }
        $Results += New-Object PSObject -Property $SCProps
    } 
    catch {
        Write-Host "You don't have access to this Site Collection" -ForegroundColor Red
    }
} #end foreach
$Results | Out-GridView Url, Name, Description