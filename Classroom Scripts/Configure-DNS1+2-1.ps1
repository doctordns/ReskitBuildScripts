# Configure-DNS-1.ps1
# Configures domain joined server DNS1

# Version    Date         What Changed
# -------    -----------  -------------------------------------------
# 1.0.0      14 Sept 2013 First build


# Define the configuration block
$conf = {
Import-Module -Name ServerManager -Verbose:$false
$VerbosePreference = 'Continue'
$StartTime = Get-Date
Write-Verbose "Starting configuration of DNS1 at: $StartTime    [$(hostname)]"

#    Define registry path for autologon, then set admin logon
#    Autologon to $dom\$user with password of $password
#    Change below to alter the user
$RegPath  = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
$user     = 'Administrator'
$password  = 'Pa$$w0rd'
$dom      = 'Reskit'  
Set-ItemProperty -Path $RegPath -Name AutoAdminLogon    -Value 1         -EA 0  
Set-ItemProperty -Path $RegPath -Name DefaultUserName   -Value $User     -EA 0  
Set-ItemProperty -Path $RegPath -Name DefaultPassword   -Value $Password -EA 0
Set-ItemProperty -Path $RegPath -Name DefaultDomainName -Value $Dom      -EA 0 
Write-Verbose "Autoadmin logon for $dom\$user set     [$(hostname)]"

# And here set the PowerConfig to not turn off the monitor!
Write-Verbose -Message 'Setting Monitor poweroff to zero'
Powercfg /change monitor-timeout-ac 0

#    Install Windows features for labs
Write-Verbose "Installing key Windows features for labs + DNS      [$(hostname)]"
$Features = @('PowerShell-ISE','Rsat-AD-PowerShell','Hyper-V-PowerShell',
              'Web-Server','Web-Mgmt-Tools','Web-Mgmt-Console',
              'Web-Scripting-Tools',
              'DNS', 'RSAT-DNS-Server')
Install-WindowsFeature $Features -IncludeManagementTools 

#     Next, enable CredSSP on Srv1
Write-Verbose "Enabling CredSSP      [$(hostname)]"
Enable-WSManCredSSP -Role Client -DelegateComputer '*.reskit.org' -Force  | out-null
Enable-WSManCredSSP -Role Server -Force | out-null
Set-Item Wsman:\Localhost\client\trustedhosts '*.reskit.org' -Force
 
#     Say nice things and finish
$FinishTime = Get-Date
Write-Verbose "Finished at: $FinishTime"
Write-Verbose "Configuring $(hostname) took $(($FinishTime - $StartTime).totalseconds.tostring('n2')) seconds"
} # End of Conf script block


# Here is the start of the script. We set credentials then invoke
# the first script block on DNS1. This enables autoadminlogon, adds
# key Windows features labs need

#     Set Credentials for DNS1 and 2
$Username   = "Reskit\administrator"
$PasswordSS = ConvertTo-SecureString  -string 'Pa$$w0rd' -AsPlainText -Force
$credrk     = New-Object -Typename  System.Management.Automation.PSCredential -Argumentlist $username,$PasswordSS

#     Set Vervbose mode on
$VerbosePreference = 'Continue'

#     Before invoking the script block Conf1, do a check to ensure we have right machine
Write-Verbose 'Checking Connectivity'
Invoke-Command -ComputerName DNS1, DNS2 -ScriptBlock {ipconfig; hostname} -Credential $credrk -Verbose
Pause
 
#     Perform initial configure of DNS1 with Conf script block
Write -Verbose "Configuring DNS1 and DNS2"
Invoke-Command -ComputerName DNS1,DNS2 -Scriptblock $conf -Credential $credrk -Verbose

Write-Verbose "Restarting both DNS1 and 2"
Restart-Computer -ComputerName DNS1,DNS2  -Wait -For PowerShell -Force -Credential $CredRK
 
#    Finally, run a snapshot
#Checkpoint-VM -VM $(Get-VM DNS1) -SnapshotName "DNS1 - Post configuration by ConfigureDNS1-1.ps1" 

Write-Verbose "All done with both DNS1 and 2"