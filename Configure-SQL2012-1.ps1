# Configure-SQL2012-1.ps1
# Performs initial configuration of SQL1 in the domain.
# Version    Date         What Changed
# -------    -----------  -------------------------------------------
# 1.0.0      20 Feb 2013  Initial release
# 1.1.0       8 Nov 2013  Added Powercfg to not turn off the monitor


# note: The setup of SQL is done in two steps
# Step 1. Insert OS DVD then install the pre-reqs and .NET - done by conf1 script block
# Step 2. Insert SQL Server DVD then install SQL Server    - done by conf2 script block.
#
# The script also needs paths to the OS and SQL server DVDs ($OS and $SQL) to be specified.


# First script block - install Windows features needed for SQL
$conf1 = {

$VerbosePreference = 'Continue'

# Define registry path for autologon, then set admin logon
Write-Verbose ' Setting Autoadmin logon'
$RegPath  = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
$user     = 'Administrator'
$password  = 'Pa$$w0rd'
$dom      = 'Reskit'  
Set-ItemProperty -Path $RegPath -Name AutoAdminLogon    -Value 1         -EA 0  
Set-ItemProperty -Path $RegPath -Name DefaultUserName   -Value $User     -EA 0  
Set-ItemProperty -Path $RegPath -Name DefaultPassword   -Value $Password -EA 0
Set-ItemProperty -Path $RegPath -Name DefaultDomainName -Value $Dom      -EA 0 

# And here set the PowerConfig to not turn off the monitor!
Write-Verbose -Message ' Setting Monitor poweroff to zero'
Powercfg /change monitor-timeout-ac 0

# Install key Windows features needed to support SQL
Write-Verbose 'Installing Windows features needed for SQL Server'
$Features = @('PowerShell-ISE','Rsat-AD-PowerShell','Hyper-V-PowerShell',
              'Web-Server','Web-Mgmt-Tools','Web-Mgmt-Console',
              'Web-Scripting-Tools', 'Telnet-Client', 'Desktop-Experience')
Install-WindowsFeature $Features -IncludeManagementTools -Verbose

# Next install the .NET Framework 2.0/3.5
Write-Verbose ' Installing the older .Net Versions'
Install-WindowsFeature Net-Framework-Core -Source d:\sources\sxs
Write-Verbose 'Completed installation of all pre-reqs'
}

# Second script block to install SQL itself
$conf2 = {
  $VerbosePreference = 'Continue'
  Write-Verbose ' Installing SQL 2012 - this will take a long time - circa 30 minutes'
  
  # OK Setup SQL
  Cd D:\
  D:\Setup.exe /Q /Action=Install /AgtSvcStartupType=Disabled /AsSysAdminAccounts="BUILTIN\Administrators" /BrowserSvcStartupType=Disabled /Features=SQL,AS,RS,IS,Tools /IndicateProgress /InstanceName=MSSQLSERVER /RsSvcStartupType=Automatic  /SQLSvcAccount="NT Authority\Network Service" /AgtSvcAccount="NT Authority\System" /AsSvcAccount="NT Authority\System" /RsSvcAccount="NT Authority\Network Service" /IsSvcAccount="NT Authority\System"  /SQLSysAdminAccounts="BUILTIN\Administrators" /IAcceptSQLServerLicenseTerms
 
 # setup a shortcut on the desktop to Management Studio
  Write-Verbose 'Creating a shortcut to SQL Management Studio on the desktop for admin'
  $WshShell = New-Object -ComObject WScript.Shell
  $Shortcut = $WshShell.CreateShortcut("$Home\Desktop\SQLManagementStudio.lnk")
  $Shortcut.TargetPath = 'C:\Program Files (x86)\Microsoft SQL Server\110\Tools\Binn\ManagementStudio\Ssms.exe'
  $Shortcut.Save()
  
  Write-Verbose 'Finished Conf2 script block'
}


##########################  Check the Paths  #########################################################

# SQL Server 2012 Install DVD Image

$sql = 'c:\builds\en_sql_server_2012_enterprise_edition_with_sp1_x64_dvd_1227976.iso'

# Windows Server Install
$os  ='c:\builds\9600.16384.130821-1623_x64fre_Server_EN-US_IRM_SSS_DV5.iso' 

# Credentials
$PasswordSS = ConvertTo-SecureString 'Pa$$w0rd' -AsPlainText -Force
$Username   = "Reskit\Administrator"
$credrk     = New-Object System.Management.Automation.PSCredential $Username,$PasswordSS
##########################  Check these   ############################################################


###   Start of script proper

# Startup
$VerbosePreference = 'Continue'
$StartTime = Get-Date
Write-Verbose "Starting create of SQL server at $StartTime"

# Check Stuff that can go wrong
Set-Alias WV  Write-Verbose  # naughty boy - just saving space
If (Test-Path $sql) {wv "$SQL ISO found"} Else {wv "$SQL ISO NOT FOUND - STOPPING";return}
If (Test-Path $os)  {wv "$os ISO found"}  Else {wv "$OS ISo NOT FOUND - STOPPING";return}
Write-Verbose "Both product CDs found"

# First, test the connection to DC1
Invoke-Command -ComputerName SQL2012 -ScriptBlock { ipconfig;hostname} -Credential $credrk -verbose
Pause

# Add the OS DVD into SQL2012 VM
$DvdParm = @{ControllerNumber=1; 
             ControllerLocation=0;
             Path=$OS;
             VMname="SQL2012";
             ErrorAction=0}
Set-VmDvdDrive @DvdParm

# Now setup SQL2012 with the .NET Framework
Invoke-Command -ComputerName SQL2012 -Scriptblock $Conf1 -Credential $Credrk -Verbose
Write-Verbose 'Completed Part 1 - installation of all pre-reqs for SQL1'
Write-Verbose 'Rebooting SQL2012 to finish off installation of .NET'
Restart-Computer -ComputerName SQL2012  -Wait -For PowerShell -Force -Credential $CredRK

# since we added desktop services - this is going to take timne to install and another reboot...
Write-Verbose 'Waiting 5 min for desktop stuf to complete and another reboot'
Start-sleep 300


# Now with all pre-reqs loaded, we can install SQL
# But first, add this DVD into SQL1 VM
# We just need to change the drive path in the hash table we created earlier
$DvdParm.Path=$SQL
# Now set the DVD to point to the SQL DVD
Set-VmDvdDrive @DvdParm
Write-Verbose ' Reset SQL DVD to point to SQL Server DVD'
# Now invoke $Conf2 to Install SQL2012
Invoke-command -ComputerName SQL2012 -Scriptblock $Conf2 -Credential $Credrk -Verbose
Write-Verbose ' Conf2 script block completed'

#     OK - script block has completed - reboot the system and wait till it comes up
Write-Verbose 'Final rebooting of SQL2012 to finish off installation of SQL '

Restart-Computer -ComputerName SQL2012  -Wait -For PowerShell -Force -Credential $CredRK
 
#    Finally, run a post-Install snapshot
Checkpoint-VM -VM $(Get-VM SQL2012) -SnapshotName "SQL2012 - post configuration by ConfigureSQL2012-1.ps1" 

# Now say nice things and finish
$FinishTime = Get-Date
Write-Verbose "SQL Configuration completed at $finishtime"
Write-Verbose "It took: [$(($FinishTime-$StartTime).totalminutes.tostring('n2'))] minutes"


# Things to add
#1. Creating a sample db/table and some sample data
#2. Add SQLPSX