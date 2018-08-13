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
Install-ADDSForest -DomainName Reskit.Org -SafeModeAdministratorPassword $PasswordSS -force -InstallDNS -DomainMode Win2012 -ForestMode Win2012 -NoReboot

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

$Username   = "DC1\Administrator"
$PasswordSS = ConvertTo-SecureString 'Pa$$w0rd' -AsPlainText -Force
$CredDC1    = New-Object System.management.Automation.PSCredential $Username,$PasswordSS

# Optionally, create a snapshot pre-DC promotion to allow reverting.
# Write-Verbose 'Checkpointing DC1 pre promotion, post os creation'
# Checkpoint-VM -VM $(Get-VM DC1) -SnapshotName "DC1 - Post OS Creation" 

# Setup Trusted Hosts on Host Compuyter Just in case
Set-Item WSMan:\Localhost\Client\Trustedhosts  '*' -force

# Run a simple script block to check that the server is actually running and is the one we think it is
# This is useful in testing!
 Write-Verbose 'Checking connectivity to DC1'
 Invoke-Command -ComputerName DC1 -ScriptBlock { Ipconfig;hostname} -Credential $CredDC1 -verbose
 Pause

# Now create our forest/domain/dc 
Write-Verbose 'Configuring DC1 to be DC'
Invoke-Command -ComputerName DC1 -Scriptblock $conf -Credential $Creddc1 -Verbose

# Complete the script by rebooting DC1
Write-Verbose 'Rebooting DC1 - please be patient'
$S = NEW-PSSESSION DC1 -CRED $CREDDC1
INVOKE-COMMAND -ScriptBlock {RESTART-COMPUTER -FORCE; EXIT} -Session $S

Write-Verbose "Ready to move on after DC1 is fully rebooted"