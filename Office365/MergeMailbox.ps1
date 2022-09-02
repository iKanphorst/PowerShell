$ID = (Get-MsolUser -UserPrincipalName <onPremAccount>).ImmutableId
Set-MsolUser -UserPrincipalName <CloudOnlyAccount> -ImmutableId $ID