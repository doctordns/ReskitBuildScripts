####
# Configure-DC1-2
# Configures DC1 after dcpromo is completed
#
# Version    Date         What Changed
# -------    -----------  -------------------------------------------
# 1.0.0      14 Jan 2013  Initial release
# 1.1.0      24 Jan 2013  Added code to count how long it all took,
#                         Added checkpoint at the end of this script
# 1.1.1      25 Jan 2013  Added auto admin logon
# 1.1.2       5 Feb 2013  Added forced reboot of DC1-1 at script end 
# 1.1.3      16 Feb 2013  Moved setting autoadmin logon to 1st conf file 
# 1.1.4       8 Nov 2013  Added powercfg call to stop monitor timeout,
# 1.1.5      20 Aug 2018  update for 2016, and removed any addition of extra features
#                         
####

#     Configuration block
$Conf = {

#    Turn on verbosity
$VerbosePreference = 'Continue'

$StartTime = Get-Date
Write-Verbose "Starting at: $StartTime"

# Make sure ADWS service is running
If ((Get-Service adws).Status -NE 'Running') {
  Write-Verbose 'ADWS Service not running - stopping'
  Return
}
Write-Verbose 'ADWS Service running!'

#    Set Credentials for use in this configuration block
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

#    Install and configure DHCP
Write-Verbose -Message 'Adding and then configuring DHCP'
Install-WindowsFeature DHCP -IncludeManagementTools

# Create necessary DHCP Groups and set config appropriately and restart the service
Import-Module DHCPServer -Verbose:$False 
Add-DHCPServerSecurityGroup -Verbose
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12 -Name ConfigurationState -Value 2
Restart-Service -Name DHCPServer –Force 
Write-Verbose 'DHCP Installed'

Add-DhcpServerV4Scope -Name "ReskitNet0" `
                      -StartRange 10.10.10.150 `
                      -EndRange 10.10.10.199 `
                      -SubnetMask 255.255.255.0
Write-Verbose 'Reskitnet0 DHCP Scope added'

# Set Option Values
Set-DhcpServerV4OptionValue -DnsDomain Reskit.Org `
                            -DnsServer 10.10.10.10

# Authorise the DCHP server in the AD                            
Write-Verbose 'Authorising DHCP Server in AD'                            
Add-DhcpServerInDC -DnsName Dc1.reskit.org
Write-Verbose 'DHCP Server authorised in AD'

#    Add users to the AD and then add them to some groups
#    Hash table for common new user paraemters
Write-Verbose -Message 'Adding user TFL'
$NewUserHT  = @{AccountPassword       = $PasswordSS;
                Enabled               = $true;
                PasswordNeverExpires  = $true;
                ChangePasswordAtLogon = $false
                }

#     Create one new user (me!) and add to enterprise and domain admins security groups
New-ADUser @NewUserHT -SamAccountName tfl `
                      -UserPrincipalName 'tfl@reskit.org' `
                      -Name "tfl" `
                      -DisplayName 'Thomas Lee'
Add-ADPrincipalGroupMembership -Identity "CN=tfl,CN=Users,DC=reskit,DC=org" `
                               -MemberOf "CN=Enterprise Admins,CN=Users,DC=reskit,DC=org" ,
                                         "CN=Domain Admins,CN=Users,DC=reskit,DC=org" 
# Fix Admin too!
Set-ADUser Administrator -PasswordNeverExpires $True

#     Say nice things and finish
$FinishTime = Get-Date
Write-Verbose "Finished at: $FinishTime"
Write-Verbose "DC1 Configuration took $(($FinishTime - $StartTime).TotalSeconds.ToString('n2')) seconds"

} # End Conf configuration script block

#    Start of script proper
#    Turnon verbosity
$VerbosePreference = 'Continue'

#    Set Credentials
$Username   = "Reskit\administrator"
$Password   = 'Pa$$w0rd'
$PasswordSS = ConvertTo-SecureString  -String $Password -AsPlainText -Force
$CredRK     = New-Object -Typename System.Management.Automation.PSCredential -Argumentlist $Username,$PasswordSS

#    Following code used to test the credentials. Remove the comments on next two lines the first time you 
#    run this script
Invoke-Command -ComputerName DC1.reskit.org -ScriptBlock {ipconfig;hostname} -Credential $Credrk -verbose
Pause

# now run the script to finish configuring dc1
Invoke-Command -ComputerName DC1.Reskit.org -Scriptblock $conf -Credential $CredRK -verbose
Write-Verbose 'Configuration complete, rebooting'
pause

#     OK - script block has completed - reboot the system and wait till it comes up
Write-Verbose  'Restarting'
Restart-Computer -ComputerName DC1.reskit.org  -Wait -For PowerShell -Force -Credential $CredRK
 
#    Finally, run a post-DCPromo snapshot
# Checkpoint-VM -VM $(Get-VM DC1) -SnapshotName "DC1 - post configuration by Configure-DC1-2.ps1" 
 
Write-Verbose "Configure-DC1-2.ps1 is complete. "
Write-Verbose "You can now move on to the next configuration task once DC1 is rebooted"