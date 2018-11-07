# Configure-SRV2-1.ps1
# Configures domain joined server SRV2


# Version    Date         What Changed
# -------    -----------  -------------------------------------------
# 1.0.0      14 Jan 2013  Initial release
# 1.1.0      24 Jan 2013  Added nice startup/shutdown messages
#                         Added a gpupdate just in case!
# 1.1.1      25 Jan 2013  Added auto admin logon
# 1.1.2       4 Feb 2013  Added Telnet client to initial features loaded onto SRV2
# 1.1.3       8 Nov 2013  Added powercfg to not power off monitor

$conf = {

$VerbosePreference = 'Continue'

$StartTime = Get-Date
Write-Verbose "Starting Configuration of SRV2 at: $StartTime"

# Define registry path for autologon, then set admin logon
$RegPath  = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
$User     = 'Administrator'
$Password  = 'Pa$$w0rd'
$Dom      = 'Reskit'  
Set-ItemProperty -Path $RegPath -Name AutoAdminLogon    -Value 1         -EA 0  
Set-ItemProperty -Path $RegPath -Name DefaultUserName   -Value $User     -EA 0  
Set-ItemProperty -Path $RegPath -Name DefaultPassword   -Value $Password -EA 0
Set-ItemProperty -Path $RegPath -Name DefaultDomainName -Value $Dom      -EA 0 
Write-Verbose "Set autologon for $Dom\$User"

# And here set the PowerConfig to not turn off the monitor!
Write-Verbose -Message 'Setting Monitor poweroff to zero'
powercfg /change monitor-timeout-ac 0

# For book = Do not add Windows Features
# FOr class - adjust this...

#Write-Verbose "Adding key Windows features to SRV2"
#$Features = @('PowerShell-ISE','Hyper-V-PowerShell',
              #'Telnet-Client', 'Desktop-Experience')
#Install-WindowsFeature $Features -IncludeManagementTools -Verbose

# Eenable CredSSP on Srv2
Write-Verbose ' Enabling CredSSP'
Write-Verbose ' First as client on VM host'
Enable-WSManCredSSP -Role Client -DelegateComputer '*.reskit.org' -Force 
Write-Verbose ' Enable as server'
Enable-WSManCredSSP -Role Server -Force
Write-Verbose ' Setting Trusted Hosts'
Set-Item Wsman:\Localhost\client\trustedhosts '*.reskit.org' -Force 

# Finally, Force a GPUpdate.
Write-Verbose 'Forcing a GP Update'
GpUpdate /Force 

# Say nice things and finish
$FinishTime = Get-Date
Write-Verbose "Finished at: $finishtime"
Write-Verbose "Configuring SRV2 took $(($FinishTime - $StartTime).totalseconds.tostring('n2')) seconds"
$
} # End of Conf script block

# start of script
Write-Verbose "Starging to configure SRV2"
#  Reskit Administrator credentials
$PasswordSS = ConvertTo-SecureString 'Pa$$w0rd' -AsPlainText -Force
$Username = "Reskit\administrator"
$Credrk = New-Object System.Management.Automation.PSCredential $Username,$PasswordSS

# Testing first, then do the conf block
Invoke-command -ComputerName SRV2.reskit.org -ScriptBlock {ipconfig;hostname} -Credential $Credrk -Verbose
Pause

# Now run the conf stcipt block to configure SRV2
Invoke-command -ComputerName SRV2.reskit.org -Scriptblock $conf -Credential $credrk -Verbose

#     OK - script block has completed - reboot the system and wait till it comes up
Restart-Computer -ComputerName SRV2.reskir.org  -Wait -For PowerShell -Force -Credential $CredRK
 
#    Finally, run a post-DCPromo snapshot
# Checkpoint-VM -VM $(Get-VM SRV2) -SnapshotName "SRV2 - Post configuration by ConfigureSRV2-1.ps1" 
