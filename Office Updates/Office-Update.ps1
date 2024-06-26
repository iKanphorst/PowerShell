<#PSScriptInfo
 
.VERSION 1.0.0
 
.GUID 2ce89b3d-09af-4864-bbde-6e981967837c
 
.AUTHOR cho.sangho@outlook.com
 
.COMPANYNAME
 
.COPYRIGHT
 
.TAGS
 
.LICENSEURI
 
.PROJECTURI
 
.ICONURI
 
.EXTERNALMODULEDEPENDENCIES
 
.REQUIREDSCRIPTS
 
.EXTERNALSCRIPTDEPENDENCIES
 
.RELEASENOTES
 
 
#> 



<#
 
.DESCRIPTION
-This sciprt helps you to update or rollback your Office 365 client.
-You can choose your build number or channel.
-This sciprt change your update channel for Office 365 client.
-You may need to change execution policy of your system. (Run : Set-ExecutionPolicy -ExecutionPolicy RemoteSigned #more detail : https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-6)
-You may need to unblock this script. (User Unblock-File cmdlet or right click - Properties - Unblock)
-You need to run Internet Explorer if you get a blank drop down list of Version field. (Initial setting for IE is required)
 
#> 

Param()


#info text
Write-Host ""
Write-Host "You can download this script at : " -NoNewline
Write-Host "https://aka.ms/update365" -ForegroundColor Yellow
Write-Host ""
Write-Host "Update history for Office 365 ProPlus : "-NoNewline
Write-Host "https://docs.microsoft.com/en-us/officeupdates/update-history-office365-proplus-by-date" -ForegroundColor Yellow
Write-Host "Release information for updates to Office 365 ProPlus : " -NoNewline
Write-Host "https://docs.microsoft.com/en-us/officeupdates/release-notes-office365-proplus" -ForegroundColor Yellow
Write-Host "Update history for Office Insider for Windows desktop: " -NoNewline
Write-Host "https://support.office.com/en-us/article/update-history-for-office-insider-for-windows-desktop-64bbb317-972a-4933-8b82-cc866f0b067c" -ForegroundColor Yellow
Write-Host ""


if (Test-Path "$env:CommonProgramFiles\microsoft shared\ClickToRun\OfficeC2RClient.exe"){
$ErrorActionPreference= 'silentlycontinue'

Write-Host "Getting a release information of Office 365......."

#get release version
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$URI="https://docs.microsoft.com/en-us/officeupdates/update-history-office365-proplus-by-date"
$HTML = Invoke-WebRequest -Uri $URI
$result = $HTML.Content

$InsiderURL="https://support.office.com/en-us/article/update-history-for-office-insider-for-windows-desktop-64bbb317-972a-4933-8b82-cc866f0b067c#InsiderLevel=Insider"
$InsiderHTML = Invoke-WebRequest -Uri $InsiderURL
$InsiderResult = [regex]::matches( $InsiderHTML.Content , '(January|February|March|Arpil|May|June|July|August|September|October|November|December)\s\d{1,2}[stndrh]{0,2},\s\d{4}</p>\s*</td>\s*<td>\s*<p>Version\s\d{4}\s\(Build\s\d{4}\.\d{4}\)')


#Channel Name
$nameCurrent = "Monthly Channel (Current Channel)"
$nameDeferred = "Semi-Annual Channel (Deferred Channel)"
$nameFirstdeferred = "Semi-Annual Channel (Targeted) (First Release for Deferred Channel)"
$nameInsiderfast = "Insider (Insider Fast)"
$nameInsiderslow = "Monthly Channel (Targeted) (Insider Slow)"
$nameDevMain = "DevMain Channel (Dogfood)"

#CDNBaseUrl
$CDNBaseUrlCurrent = "http://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60"
$CDNBaseUrlDeferred = "http://officecdn.microsoft.com/pr/7ffbc6bf-bc32-4f92-8982-f9dd17fd3114"
$CDNBaseUrlFirstDeferred = "http://officecdn.microsoft.com/pr/b8f9b850-328d-4355-9145-c59439a0c4cf"
$CDNBaseUrlInsiderFast= "http://officecdn.microsoft.com/pr/5440fd1f-7ecb-4221-8110-145efaa6372f"
$CDNBaseUrlInsiderSlow= "http://officecdn.microsoft.com/pr/64256afe-f5d9-4f86-8936-8840a6a4f5be"
$CDNBaseUrlDevMain = "http://officecdn.microsoft.com/pr/ea4a4090-de26-49d7-93c1-91bff9e53fc3"

#Channel filter
$current = [regex]::matches( $result, '<a href=\"monthly-channel(.*?)</a>')
$deferred = [regex]::matches( $result, '<a href=\"semi-annual-channel-(\d{4})(.*?)</a>')
$firstDeferred = [regex]::matches( $result, '<a href=\"semi-annual-channel-targeted(.*?)</a>') 
$InsiderFastContent=(($InsiderHTML.Content -split "<table id=""tblID0EAAABAACAAA"" class=""banded"">")[1] -split "<table id=""tblID0EAAAAAACAAA"" class=""banded"">")[0]
$InsiderSlowContent=(($InsiderHTML.Content -split "<table id=""tblID0EAAABAACAAA"" class=""banded"">")[1] -split "<table id=""tblID0EAAAAAACAAA"" class=""banded"">")[1]
$InsiderFastBuild = [regex]::Matches($InsiderFastContent,"Version \d{4} \(Build \d{4,5}\.\d{4,5}\)")
$InsiderSlowBuild = [regex]::Matches($InsiderslowContent,"<p>\d{4}</p>\s*</td>\s*<td>\s*<p>\d{4,5}\.\d{4,5}</p>")


$ChannelChanged = $false


#Form

Add-Type -AssemblyName System.Windows.Forms

$Form = New-Object system.Windows.Forms.Form
$Form.Text = "Office 365 Update Tool"
$Form.Size = New-Object System.Drawing.Size(370,120)
$form.MaximumSize = New-Object System.Drawing.Size(370,150)
$Form.MinimumSize = New-Object System.Drawing.Size(370,150)
$CenterScreen = [System.Windows.Forms.FormStartPosition]::CenterScreen;
$Form.StartPosition = $CenterScreen
$Form.TopMost = $True

$CmbChannel = New-Object System.Windows.Forms.ComboBox
$CmbChannel.Text = "Select release channel..."
$CmbChannel.Location = New-Object System.Drawing.Point(10,15)
$CmbChannel.Size = New-Object System.Drawing.Size(330,80)
$Form.controls.Add($CmbChannel)

$CmbBuild = New-Object System.Windows.Forms.ComboBox
$CmbBuild.Text = "Select release channel first..."
$CmbBuild.Location = New-Object System.Drawing.Point(10,40)
$CmbBuild.Size = New-Object System.Drawing.Size(330,400)
$Form.Controls.Add($CmbBuild)

$BtnUpdate = New-Object System.Windows.Forms.Button
$BtnUpdate.Text = "Update"
$BtnUpdate.Location = New-Object System.Drawing.Point(265,75)
$BtnUpdate.Enabled = $false
$Form.Controls.Add($BtnUpdate)

$ChkUpdate = New-Object System.Windows.Forms.Checkbox
$ChkUpdate.Text = "Disable updates"
$ChkUpdate.Location = New-Object System.Drawing.Point(10,75)
$ChkUpdate.Size = New-Object System.Drawing.Size(200,20)
$Form.Controls.Add($ChkUpdate)


#Cmb contents
$CmbChannel.Items.Add($nameCurrent) >> $null
$CmbChannel.Items.Add($nameDeferred) >> $null
$CmbChannel.Items.Add($nameFirstdeferred) >> $null
$CmbChannel.Items.Add($nameInsiderfast) >> $null
$CmbChannel.Items.Add($nameInsiderslow) >> $null
$CmbChannel.Items.Add($nameDevMain) >> $null

#Event handler

$CmbChannel_SelectedIndexChanged =
{
    $BtnUpdate.Enabled = $false
    if($CmbChannel.Text -eq $nameCurrent){
        $CmbBuild.Items.Clear()
        $CmbBuild.Text = "Select build number..."

        for($i=0;$i -lt $current.count;$i++){
            $date_build = ([regex]::matches($current.value[$i],'Version \d{4} \(Build \d{4,5}\.\d{4,5}\)' )).value
            $CmbBuild.Items.Add($date_build)
        }
    }
    elseif($CmbChannel.Text -eq $nameDeferred){
        $CmbBuild.Items.Clear()
        $CmbBuild.Text = "Select build number..."
        for($i=0;$i -lt $deferred.count;$i++){
            $date_build = ([regex]::matches($deferred.value[$i],'Version \d{4} \(Build \d{4,5}\.\d{4,5}\)' )).value
            $CmbBuild.Items.Add($date_build)
        }


    }
    elseif($CmbChannel.Text -eq $nameFirstdeferred){
        $CmbBuild.Items.Clear()
        $CmbBuild.Text = "Select build number..."    
        for($i=0;$i -lt $firstDeferred.count;$i++){
            $date_build = ([regex]::matches($firstDeferred.value[$i],'Version \d{4} \(Build \d{4,5}\.\d{4,5}\)' )).value
            $CmbBuild.Items.Add($date_build)
        }    
   
    }

    elseif($CmbChannel.Text -eq $nameInsiderfast){
        $CmbBuild.Items.Clear()
        $CmbBuild.Text = "Select build number..."    
        for($i=0;$i -lt $InsiderFastBuild.count;$i++){
            $CmbBuild.Items.Add($InsiderFastBuild[$i].value)
        }    
   
    }

    elseif($CmbChannel.Text -eq $nameInsiderslow){
        $CmbBuild.Items.Clear()
        $CmbBuild.Text = "Select build number..."    
        for($i=0;$i -lt $InsiderSlowBuild.count;$i++){
            $isVersion=[regex]::Matches($InsiderSlowBuild[$i].value,"<p>\d{4,5}</p>") -replace "<p>","" -replace "</p>",""
            $isBuild = [regex]::Matches($InsiderSlowBuild[$i].value,"<p>\d{4,5}\.\d{4,5}</p>") -replace "<p>","" -replace "</p>",""
            $date_build = "Version " + $isVersion + " (Build " + $isBuild + ")" 
            $CmbBuild.Items.Add($date_build)
        }    
   
    }

    elseif($CmbChannel.Text -eq $nameDevMain){
        $BtnUpdate.Enabled = $true
        $CmbBuild.Items.Clear()
        $CmbBuild.Text = "Update to the latest build."       
    }


}

$CmbBuild_SelectedIndexChanged = { $BtnUpdate.Enabled = $True }

$BtnUpdate_Click =
{
    if($CmbChannel.Text -eq $nameCurrent){

        if((Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Office\ClickToRun\Configuration).CDNBaseUrl -ne $CDNBaseUrlCurrent)        {
            $ChannelChanged = $true
            Start-Process powershell.exe -Verb runAs{
            Set-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Office\ClickToRun\Configuration -Name CDNBaseUrl -Value "http://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60"
            Remove-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Office\ClickToRun\Updates -Name UpdateToVersion
            }
        }
    }
    
    elseif($CmbChannel.Text -eq $nameDeferred){
        if((Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Office\ClickToRun\Configuration).CDNBaseUrl -ne $CDNBaseUrlDeferred){         
            $ChannelChanged = $true
            Start-Process powershell.exe -Verb runAs{
            Set-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Office\ClickToRun\Configuration -Name CDNBaseUrl -Value "http://officecdn.microsoft.com/pr/7ffbc6bf-bc32-4f92-8982-f9dd17fd3114"
            Remove-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Office\ClickToRun\Updates -Name UpdateToVersion
            }
        }
    }
    elseif($CmbChannel.Text -eq $nameFirstdeferred){
        if((Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Office\ClickToRun\Configuration).CDNBaseUrl -ne $CDNBaseUrlFirstDeferred){         
            $ChannelChanged = $true
            Start-Process powershell.exe -Verb runAs{
            Set-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Office\ClickToRun\Configuration -Name CDNBaseUrl -Value "http://officecdn.microsoft.com/pr/b8f9b850-328d-4355-9145-c59439a0c4cf"
            Remove-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Office\ClickToRun\Updates -Name UpdateToVersion
            }
        }
    }
    elseif($CmbChannel.Text -eq $nameInsiderfast){
        if((Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Office\ClickToRun\Configuration).CDNBaseUrl -ne $CDNBaseUrlInsiderFast){         
            $ChannelChanged = $true
            Start-Process powershell.exe -Verb runAs{
            Set-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Office\ClickToRun\Configuration -Name CDNBaseUrl -Value "http://officecdn.microsoft.com/pr/5440fd1f-7ecb-4221-8110-145efaa6372f"
            Remove-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Office\ClickToRun\Updates -Name UpdateToVersion
            }
        }
    }

    elseif($CmbChannel.Text -eq $nameInsiderslow){
        if((Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Office\ClickToRun\Configuration).CDNBaseUrl -ne $CDNBaseUrlInsiderSlow){         
            $ChannelChanged = $true
            Start-Process powershell.exe -Verb runAs{
            Set-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Office\ClickToRun\Configuration -Name CDNBaseUrl -Value "http://officecdn.microsoft.com/pr/64256afe-f5d9-4f86-8936-8840a6a4f5be"
            Remove-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Office\ClickToRun\Updates -Name UpdateToVersion
            }
        }
    }

    elseif($CmbChannel.Text -eq $nameDevMain){
        
        if((Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Office\ClickToRun\Configuration).CDNBaseUrl -ne $CDNBaseUrlDevMain){         
            $ChannelChanged = $true
            Start-Process powershell.exe -Verb runAs{
            Set-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Office\ClickToRun\Configuration -Name CDNBaseUrl -Value "http://officecdn.microsoft.com/pr/ea4a4090-de26-49d7-93c1-91bff9e53fc3"
            Remove-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Office\ClickToRun\Updates -Name UpdateToVersion
            }
        }
    }

    $Form.Close()

        if($ChannelChanged -eq $true){
            Write-Host "Modifing registry value for "$CmbChannel.text -NoNewline
            for($c = 0; $c -lt 5; $c++){
                Write-Host "." -NoNewline
                Start-Sleep -Seconds 1 
            }
            Write-Host ""
        }

    
    
    if($CmbChannel.Text -ne $nameDevMain){
        $build = "16.0."+(($CmbBuild.text -split "Build ")[1] -split "\)")[0]
        & "$env:CommonProgramFiles\microsoft shared\ClickToRun\OfficeC2RClient.exe" /update user updatetoversion=$build}
    
    else{& "$env:CommonProgramFiles\microsoft shared\ClickToRun\OfficeC2RClient.exe" /update user}

    Write-Host "Updating Office 365......."

    if($ChkUpdate.Checked -eq $true){
        Write-Host "Disable updates......."
        Start-Process powershell.exe -Verb runAs{
        Set-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Office\ClickToRun\Configuration -Name UpdatesEnabled -Value "False"
        }

    }

}

$CmbChannel.add_SelectedIndexChanged($CmbChannel_SelectedIndexChanged)
$BtnUpdate.add_Click($BtnUpdate_Click)
$CmbBuild.add_SelectedIndexChanged($CmbBuild_SelectedIndexChanged)
$Form.ShowDialog()
}

else {
    Write-Host "Please verify Office 365 is installed correctly. Can't find '$env:CommonProgramFiles\microsoft shared\ClickToRun\OfficeC2RClient.exe'" -ForegroundColor Yellow
}
Contact UsTerms of UsePrivacy PolicyGallery StatusFeedbackFAQs© 2021 Microsoft Corporation