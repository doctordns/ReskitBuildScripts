# Configure-DC1-1.ps1
# Converts Server to DC
# Version    Date         What Changed
# -------    -----------  -------------------------------------------
# 1.0.0      14 Jan 2013  Initial release
# 1.1.0      24 Jan 2013  Added code to count how long it all took,
#                         Added checkpoint at the end of this script
# 1.1.1      25 Jan 2013  Added auto admin logon
# 1.1.2      5  Feb 2013  Added forced reboot of DC1-1 at script end
# 1.1.4      24 Feb 2013  Moved autoadmin login settings to -2 script 
# 1.1.5      20 Jul 2018  Updated for new book, and for less on DC1

# Define Conf script block to do configuration
$conf = {
# Startup script block stuff
$VerbosePreference = 'Continue'
$StartTime = Get-Date
Write-Verbose "Starting DC1-1 Configuration at: $StartTime"

# Add the features needed to promote this newly minted VM to be a DC.
Import-Module ServerManager -Verbose:$false
Write-Verbose "Installing AD-Domain-Services Windows feature"
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

# Now install the AD to DC1 - the reboot is or should be automagic
Write-Verbose "Creating a new Forest/Domain/DNS/DC - DC1"
$PasswordSS = ConvertTo-SecureString  -string 'Pa$$w0rd' -AsPlainText -Force
Install-ADDSForest -DomainName Reskit.Org `
                   -SafeModeAdministratorPassword $PasswordSS `
                   -Force -InstallDNS `
                   -DomainMode WinThreshold `
                   -ForestMode WinThreshold `
                   -NoReboot

# Say nice things and finish
$FinishTime = Get-Date
Write-Verbose "Finished at: $finishtime"
Write-Verbose "DC1 Promotion took $(($FinishTime - $StartTime).totalseconds.tostring('n2')) seconds"

} # End of Conf configuration Block

#
# Here is start of script to create a DC from DC1.
#

# Set verbose on
$VerbosePreference = 'Continue'

# Define DC1 and RK credentials

$Username   = 'dc1\Administrator'
$PasswordSS = ConvertTo-SecureString 'Pa$$w0rd' -AsPlainText -Force
$CredDC1    = New-Object System.management.Automation.PSCredential $Username,$PasswordSS

# Since presumably this is the first VM configured, make Sure that we enable CredSSP on the host
Write-Verbose " Enabling CredSSP on $(hostname)"
Write-Verbose ' Configure CredSSP client'
Enable-WSManCredSSP -Role Client -DelegateComputer '*.reskit.org' -Force 
Write-Verbose ' Also enable as server'
Enable-WSManCredSSP -Role Server -Force
Write-Verbose ' Setting Trusted Hosts'
Set-Item Wsman:\Localhost\client\trustedhosts '*.reskit.org' -Force 

# Run a simple script block to check that the server is actually running and is the one we think it is
# This is useful in testing!
 Write-Verbose 'Checking connectivity to DC1'
 Invoke-Command -ComputerName DC1.reskit.org -ScriptBlock { Ipconfig;hostname} -Credential $CredDC1 -verbose
 Pause

# Now create our forest/domain/dc 
Write-Verbose 'Configuring DC1 to be DC'
Invoke-Command -ComputerName DC1.reskit.org -Scriptblock $conf -Credential $Creddc1 -Verbose
Write-Verbose 'CONF block configuration of SRV1 completed.'
pause

# Complete the script by rebooting DC1
Write-Verbose 'Rebooting DC1 - please be patient'
$S = NEW-PSSESSION DC1.reskit.org -CRED $CREDDC1
INVOKE-COMMAND -ScriptBlock {RESTART-COMPUTER -FORCE; EXIT} -Session $S

Write-Verbose "Ready to move on after DC1 is fully rebooted"