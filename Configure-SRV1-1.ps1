# Configure-SRV1-1.ps1
# Configures domain joined server SRV1

# Version    Date         What Changed
# -------    -----------  -------------------------------------------
# 1.0.0      14 Jan 2013  Initial release
# 1.1.0      24 Jan 2013  Added nice startup/shutdown messages
#                         Added a GPupdate just in case
# 1.1.1      25 Jan 2013  Added auto admin logon
# 1.1.2       9 Feb 2013  Added Enablement of CredSSP on this machine
# 1.1.3       8 Nov 2013  Set Monitor to not poweroff
# 1.1.4       7 Jun 2014  Removed adding the desktop Experience - no point!

$conf = {
Import-Module -Name ServerManager -Verbose:$false
$VerbosePreference = 'Continue'
$StartTime = Get-Date
Write-Verbose "Starting configuration of SRV1 at: $StartTime"

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
Write-Verbose -message " Autoadmin logon for $dom\$user set"

# And here set the PowerConfig to not turn off the monitor!
Write-Verbose -Message ' Setting Monitor poweroff to zero'
Powercfg /change monitor-timeout-ac 0

# Here we used to install minimal Windows features
# Add Web server and management tools/console
# If you are following the book vs the course, you may want to 
# remove this step.
Write-Verbose ' Installing key Windows features for labs'

$Features = @('Web-Server','Web-Mgmt-Tools','Web-Mgmt-Console',
              'Web-Scripting-Tools')
Install-WindowsFeature $Features -IncludeManagementTools 

#     Next, enable CredSSP on Srv1
Write-Verbose ' Enabling CredSSP'
Write-Verbose ' First as client on VM host'
Enable-WSManCredSSP -Role Client -DelegateComputer '*.reskit.org' -Force 
Write-Verbose ' Enable as server'
Enable-WSManCredSSP -Role Server -Force
Write-Verbose ' Setting Trusted Hosts'
Set-Item Wsman:\Localhost\client\trustedhosts '*.reskit.org' -Force 

#     Say nice things and finish
$FinishTime = Get-Date
Write-Host "Finished first config block at: $FinishTime"
Write-Host "Configuring SRV1 took $(($FinishTime - $StartTime).totalseconds.tostring('n2')) seconds"
} # End of Conf script block

$conf2 = {
$VerbosePreference = 'Continue'
Write-Verbose 'Starting 2nd conf block'

#     Set Credentials for SRV1
Write-Verbose ' Segtting credentials'
$Username   = "reskit\administrator"
$PasswordSS = ConvertTo-SecureString  -string 'Pa$$w0rd' -AsPlainText -Force
$credrk     = New-Object -Typename  System.Management.Automation.PSCredential -Argumentlist $username,$PasswordSS


#    Get the module to get IIS:
Import-Module WebAdministration -Verbose:$False

#   Add new web binding for SSL
Write-Verbose ' Setting Binding for SSL'
New-WebBinding -Name "Default Web Site" -IP "*" -Port 443 -Protocol https

#     Get a cert for this VM
Write-Verbose ' Creating self signed certificate - this will take a moment'
New-SelfSignedCertificate -DNS SRV1.Reskit.Org -CertStoreLocation cert:\LocalMachine\my
Write-Verbose 'Self signed certificate created, but is untrusted'

#     Ok now get that cert into $cert
#     There should now only be 1 cert in the local machine's my store
$Cert=(Get-ChildItem Cert:\localmachine\my | Where Subject -Match 'SRV1')
$thumbprint = $Cert.Thumbprint
Write-Verbose " Cert being used has thumbprint: [$Thumbprint]"

#     Add $cert to IIS Bindings for the whole SRV1 site
Write-Verbose "Setting SSL bindings with this cert"
New-Item IIS:\SSLBindings\0.0.0.0!443 -value $Cert

####  TODO - add some code to copy the self signed cert to local machine's CA cert store.

Write-Verbose 'Finished 2nd conf block running in SRV1'

} #   End of Conf2 script block

# Here is the start of the script.

#  Before starting - if you want VM internet access run this next section
Write-Verbose 'Adding second NIC to SRV1 to enable Inet access'
$I = Get-VMSwitch -Name External -ErrorAction SilentlyContinue
If (! $I)
 {'External switch does not exist - quitting';exit}

$N =  Get-VMNetworkAdapter -VMName SRV1
if ($N.count -ge 2)  # already a 2nd or more nic??
   {'Two nics already in the vm - skipping 2nd nic creation'}
else {  # add second NIC but stop VM first
 Stop-VM -VMName SRV1
 Add-VMNetworkAdapter -VMName SRV1 -SwitchName 'External'   # adjust switch name as needed
 Start-VM -VMName SRV1
}

#  Set credentials then invoke the first script block on SRV1. This
#  enables autoadminlogon, adds key Windows features labs need, 
#  installs RSAT tools, CredSSP,  then does a group policy update. The
#  server is then rebooted to effect CredSSP. 
#
#  A second script block, Conf2, then runs to setup SSL on SRV1 
#  using CredSSP logon.

#     Set Credentials for SRV1
$Username   = "reskit\administrator"
$PasswordSS = ConvertTo-SecureString  -string 'Pa$$w0rd' -AsPlainText -Force
$Credrk     = New-Object -Typename  System.Management.Automation.PSCredential -Argumentlist $username,$PasswordSS

#     Set Vervbose mode on
$VerbosePreference = 'Continue'

#     Before invoking the script block Conf1, do a check to ensure we have right machine
Invoke-Command -ComputerName SRV1.reskit.org -ScriptBlock {ipconfig; hostname} -Credential $credrk -Verbose
Pause
 
#     Perform initial configure of Srv1 with Conf script block
Invoke-Command -ComputerName SRV1.reskit.org -Scriptblock $conf -Credential $credrk -Verbose

#     Reboot the server and wait till it comes back up
Write-Verbose 'Rebooting system, please be patient'
Restart-Computer -ComputerName SRV1.reskit.org  -Wait -For PowerShell -Force -Credential $CredRK

#     Configure Srv1 with a cert - needed previous block to complete before we can use CredSSP
Write-Verbose 'Running Conf2 script block to give this server a cert and install SSL'
Invoke-command -ComputerName SRV1 -Scriptblock $conf2 -Credential $Credrk -Verbose -Authentication Credssp 

#     OK - script block has completed - reboot the system and wait till it comes up
Write-Verbose ' Rebooting SRV1 - please be patient'
Restart-Computer -ComputerName SRV1  -Wait -For PowerShell -Force -Credential $CredRK
 
#    Finally, run a post-DCPromo snapshot
#Checkpoint-VM -VM $(Get-VM SRV1) -SnapshotName "SRV1 - Post configuration by ConfigureSRV1-1.ps1" 
# All DOne!!