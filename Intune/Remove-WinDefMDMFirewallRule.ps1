Write-Host "!!! IMPORTANT. IF YOU INFORM A WRONG NAME THE SCRIPT CAN DELETE A WRONG RULE OR NO RULE AT ALL !!!" -ForegroundColor Yellow -BackgroundColor red
$FWRule = Read-Host -Prompt "Inform the name of the rule to be removed from Windows Defender Firewall"
$FWRule = "*"+$FWRule+"*"
$RegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\Mdm\FirewallRules"
$regs = (Get-ItemProperty -Path $RegPath).psobject.properties | Select-Object Name, Value​
for ($i=1; $i -lt $regs.Count; $i++) {​
    $name = $regs.Get($i).Name​
    $value = $regs.Get($i).Value​
    if ($value -like $FWRule){​
        Write-Host "Policy found: "+$name -ForegroundColor Green​
        Write-Host "Removing Policy: "+$name -ForegroundColor White​
        Remove-ItemProperty -Path $RegPath -Name $name -Verbose​
    }
}