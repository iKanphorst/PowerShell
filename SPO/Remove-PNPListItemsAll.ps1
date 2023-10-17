Connect-PnPOnline -Url <URL Here> -useWebLogin  
Get-PnPListItem -List 'Preservation Hold Library' -PageSize 1 | ForEach-Object {  
       $Filename = $_.FieldValues.FileLeafRef  
       Write-Host "Removing $Filename" -ForegroundColor Cyan  
       Remove-PnPListItem -List 'Preservation Hold Library' -Identity $_ -Force  
}