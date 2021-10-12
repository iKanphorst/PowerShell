#Requires -RunAsAdministrator
#Azure AIP UL Scanner deploy script
#Author: Igor Lysenko
#Company: Threatscape Ltda
#Date: 12/03/2020
# The purpose of this script is to helps the deployment of the AIP Scanner
# The proccess will consist in check all the permissions necessary and help the administrator in the deployment fase
# installing the service and creating all the cloud applications and permissions necessary in Azure.
Add-Type -AssemblyName System.Windows.Forms
#Checking for Azure AD Powershell Module
try{
    Write-Host "Checking if the AzureAD Module for PowerShell is installed..." -ForegroundColor Yellow
    Import-Module -Name AzureAD -ErrorAction Stop
} catch {
    Write-Host "AzureAd Module for PowerShell is not Installed. Proceeding with the install..." -ForegroundColor Red
    Install-Module -Name AzureAD -AllowClobber -Verbose -SkipPublisherCheck
} finally {
    Write-Host "Importing Azure AD Module for PowerShell..." -ForegroundColor Yellow
    Import-Module -Name AzureAD
    Write-Host "AzureAD Module imported." -ForegroundColor Green

    #Checking for AIP module
    try {
        Write-Host "Checking if the AIPService Module for PowerShell is installed..." -ForegroundColor Yellow
        Import-Module -Name AIPService -ErrorAction Stop
    } Catch {
        Write-Host "Installing Azure AIP Module for PowerShell..." -ForegroundColor Yellow
        Install-Module -Name AIPService -AllowClobber -SkipPublisherCheck
        Write-Host "AIPService Module installed." -ForegroundColor Green
    } finally {
        Write-Host "Importing AIPService Module for PowerShell..." -ForegroundColor Yellow
        Import-Module -Name AIPService
        Write-Host "AIPService Module imported." -ForegroundColor Green
    }

    #Creating the AIP Scanner Profile


    #Downloading the AIP UL client
    $AIPULURL = "https://download.microsoft.com/download/4/9/1/491251F7-46BA-46EC-B2B5-099155DD3C27/AzInfoProtection_UL.exe"
    try {
        Write-Host "Downloading the Azure Information Protection Unified Labeling client..." -ForegroundColor Green
        $SaveBrowser = New-Object System.Windows.Forms.SaveFileDialog -Property @{
            InitialDirectory = [Environment]::GetFolderPath('MyDocuments')
            Filter = 'Win32 Executable Files (*.exe)|*.exe'
            FileName = "AzInfoProtection_UL"
            CheckFileExists = $false
        }
        $Null = $SaveBrowser.ShowDialog()
        $Start_Time = Get-Date
        Invoke-WebRequest -Uri $AIPULURL -OutFile $SaveBrowser.FileName -Verbose -ErrorAction Stop
        Write-Output "AzInfoProtection_UL.exe client downloaded. Time Taken: $((Get-date).Subtract($Start_Time).Seconds) second(s)."
        Write-Host "File saved in" $SaveBrowser.FileName -NoNewline -ForegroundColor Green
    } catch {
        Write-Host "It was not possible to download the file. Please check the network connectivity."
    } finally {
        try {
            Write-Host "Installing the Azure Information Protection Unified Labeling client..." -ForegroundColor Green
            Start-Process -FilePath $SaveBrowser.FileName -ArgumentList "/q" -Wait -ErrorAction Stop
        } catch {
            Write-Host "It was not possible to install the Azure Information Protection Unified Labeling client. Please reboot the server and try again manually." -ForegroundColor Red -BackgroundColor Black
        } finally {
            Write-Host "Installation complete!" -ForegroundColor Green
            Write-Host "Importing AzureInformationProtection Module for PowerShell..." -ForegroundColor Yellow
            Import-Module -Name AzureInformationProtection -ErrorAction Stop
        }
    }
    #Connect to AzureAD
    Write-Host "Proceeding to the creation of the AIP-DelegatedUser Application on Azure AD." -ForegroundColor Yellow
    Write-Host "Provide the credentials for the Azure AD Tenant." -ForegroundColor Green
    Write-Host "This credential must have at least the Application Administrator Role assigned!" -ForegroundColor Yellow
    Connect-AzureAD -Verbose
   
    #Create the New AIP Delegated Application
    New-AzureADApplication -DisplayName AIP-DelegatedUser -ReplyUrls https://localhost -Verbose
    Write-Host "Waiting for the application to be created..." -ForegroundColor Yellow
    Start-Sleep 30
    $WebApp = Get-AzureADApplication -Filter "DisplayName eq 'AIP-DelegatedUser'"

    #Create the new AIP Delegated Application Service Principal Name
    $ADSpn = New-AzureADServicePrincipal -AppId $WebApp.AppId

    #Create the Key for authentication
    $Date = Get-Date
    Write-Host "Creating the new Authentication Key for the application " $WebApp.DisplayName -ForegroundColor Green
    New-AzureADApplicationPasswordCredential -ObjectId $WebApp.AppId -startDate $Date -endDate $Date.AddYears(5) -CustomKeyIdentifier "Azure Information Protection Unified Labeling Client" -Verbose
    Write-Host "Waiting for the application key to be created..." -ForegroundColor Yellow
    Start-Sleep 30
    try {
        $WebAppKey = Get-AzureADApplicationPasswordCredential -ObjectId $WebApp.AppId
        $WebAppKeyValue = $WebAppKey.Value
    } catch {
        Write-host "AIP-DelegatedUser Application key not synchronized... Checking again in 30 seconds..."
        Start-Sleep 30
    } finally {
        Write-Host "AIP-DelegateUser Application key created. Proceeding with the configuration." -ForegroundColor Green
        $WebAppKey = Get-AzureADApplicationPasswordCredential -ObjectId $WebApp.AppId
        $WebAppKeyValue = $WebAppKey.Value
    }
    
    #Retrieve the Azure AD Tenant ID for future Use
    Write-Host "Gathering the Azure AD Tenant ID..." -ForegroundColor Green
    $tenantId = (Get-AzureADTenantDetail).ObjectId

    #Define the permissions for the API on Azure Portal.
    Write-Host "The next steps must be performed over the Azure Portal!" -ForegroundColor Yellow
    Write-Host "Open the Azure Portal and go to the following section: Azure Active Directory -> App Registrations -> AIP-DelegatedUser" -ForegroundColor Yellow
    Write-Host "Manage -> API Permissions" -ForegroundColor Yellow 
    Write-Host "Add a Permission -> Microsoft APIs -> Azure Rights Management Services -> Application Permissions -> Content.DelegatedReader / Content.DelegatedWriter -> Add permissions" -ForegroundColor Yellow 
    Write-Host "Add a Permission -> APIs my organization uses -> Microsoft Information Protection Sync Service -> Application Permissions -> UnifiedPolicy.Tenant.Read -> Add permissions" -ForegroundColor Yellow 
    Write-Host "Manage -> API Permissions -> Grant Admin consent for" (Get-AzureADTenantDetail).DisplayName -ForegroundColor Yellow 
    Write-Host "Once you finish the configuration press any key to continue." -ForegroundColor Yellow
    [void][System.Console]::ReadKey($true)

    #Define the credentials for the AIP Service Account
    Write-Host "Please provide the credentials for the AIP Scanner service account." -ForegroundColor Green
    Write-Host "This account will be used for the AIP Scanner to scan the repositories configured." -ForegroundColor Green
    $pscreds = Get-Credential

    #Install the AIP Scanner an authorize the AIP Service account
    try {
        Write-Host "Azure configuration finished succesfully. Proceeding with the AIP Scanner install..." -ForegroundColor Green
        try {
            #Configuring the AIP Scanner
            Write-Host "To install the AIP Scanner it is necessary to provide a SQL Server. Please provide the DNS name for the server to be used."
            $SQLServerName = Read-Host "SQL Server Name"
            Write-Host "Testing connection with the SQL Server..." -ForegroundColor Yellow
            while (!(Test-NetConnection -ComputerName $SQLServerName -Port 1433)){
                Write-Host "It was not possible to connect to the following SQL server."
                $SQLServerName = Read-Host "SQL Server Name"
                Write-Host "Testing connection with the SQL Server..." -ForegroundColor Yellow   
            }
        } catch {
            Write-Host "Couldn`t connect to the SQL Server." -ForegroundColor Red -BackgroundColor Black            
        } finally {
            #Installing the AIP Scanner
            Write-Host "Installing AIP Scanner on server $env:COMPUTERNAME and SQL Server $SQLServerName..." -ForegroundColor Green
            Write-Host "Please inform the profile name for the AIP Scanner." -ForegroundColor Yellow
            Write-Host "You chan check the profile name on the Azure Portal -> Azure Information Protection -> Scanner -> Profiles." -ForegroundColor Yellow
            $AIPULProfile = Read-Host "Name of the Scanner Profile"
            Install-AIPScanner -SqlServerInstance $SQLServerName -Profile $AIPULProfile
        }
        write-host "It was not possible to authorize the AIP Service Account. Please check the permissions for the account." -ForegroundColor Red -BackgroundColor Black
    } catch {

    } finnaly {
        try {
            Write-Host "Performing the authorization for the AIP Service account on Behalf of the organization."
            Set-AIPAuthentication -AppId $webApp.ObjectID -AppSecret $WebAppKey.Value -TenantId $tenantId -DelegatedUser $DelegatedUser -OnBehalfOf $pscreds -Verbose -ErrorAction Stop
        } catch {
            Write-Host "It was not possible to authorize the account. Please authorize manually." -ForegroundColor Red
        } finally {
            Write-Host "AIP Scanner installation finished." -ForegroundColor Green
        }
    }
}