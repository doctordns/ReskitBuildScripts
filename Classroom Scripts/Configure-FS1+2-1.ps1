# Configure-fs1+2-1.ps1
# Configures domain joined server DNS1

# Version    Date         What Changed
# -------    -----------  -------------------------------------------
# 1.0.0      11-jan 2018


# Define the configuration block
$conf = {
$VerbosePreference = 'continue'
Write-Verbose 'starting'

#    Set Credentials 
$User       = 'Reskit\Administrator'
$Password   = 'Pa$$w0rd'
$PasswordSS = ConvertTo-SecureString  -String $Password -AsPlainText -Force
$Dom        = 'Reskit'
$CredRK     = New-Object -Typename System.Management.Automation.PSCredential -Argumentlist $User,$PasswordSS

# Define registry path for autologon, then set admin logon
Write-Verbose -Message 'Setting Autologon'
$RegPath  = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
$user     = 'Administrator'
$password = 'Pa$$w0rd'
$dom      = 'Reskit'  
Set-ItemProperty -Path $RegPath -Name AutoAdminLogon    -Value 1         -EA 0  
Set-ItemProperty -Path $RegPath -Name DefaultUserName   -Value $User     -EA 0  
Set-ItemProperty -Path $RegPath -Name DefaultPassword   -Value $Password -EA 0
Set-ItemProperty -Path $RegPath -Name DefaultDomainName -Value $Dom      -EA 0 

# And here set the PowerConfig to not turn off the monitor!
Write-Verbose -Message 'Setting Monitor poweroff to zero'
powercfg /change monitor-timeout-ac 0
}

### Script startes here

#    Turn on verbosity
$OVP = $VerbosePreference
$VerbosePreference = 'Continue'

# say nice things
$StartTime = Get-Date
Write-Verbose "Starting at: $StartTime"

#    Set Credentials 
$User       = 'Reskit\Administrator'
$Password   = 'Pa$$w0rd'
$PasswordSS = ConvertTo-SecureString  -String $Password -AsPlainText -Force
$Dom        = 'Reskit'
$CredRK     = New-Object -Typename System.Management.Automation.PSCredential -Argumentlist $User,$PasswordSS

# now run the sb on FS1, FS2
Invoke-command -ComputerName fs1, fs1 -ScriptBlock $conf -cred $CredRK

# reset verbosity
$VerbosePreference = $OVP

Write-Verbose "Configuring $(hostname)"
Write-Verbose 'You can now move on to the next configuration task'
