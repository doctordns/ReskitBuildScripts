####
# Configure-Storage Servers
# Configures SSRV1-3 for storage spaces and storage spaces direct
#
# Version    Date         What Changed
# -------    -----------  -------------------------------------------
# 1.0.0      22 Aug 2018  Initial release


###  SET Variables
$OVP = $VerbosePreference
$VerbosePreference = 'Continue'

#    Set Credentials
$Username   = "Reskit\administrator"
$Password   = 'Pa$$w0rd'
$PasswordSS = ConvertTo-SecureString  -String $Password -AsPlainText -Force
$CredRK     = New-Object -Typename System.Management.Automation.PSCredential -Argumentlist $Username,$PasswordSS

# First Stop the VMs
Stop-Vm -VMName SSRV1, SSRV2, SSRV3 -Force -TurnOff

# Update hardware for each VM
# Enable virtualisation on processors and give each SSRVx two procs
Write-Verbose 'Enabling Hyper-B inside VMs'
Set-VMProcessor -VMName SSRV1 -ExposeVirtualizationExtensions $true -count 2
Set-VMProcessor -VMName SSRV2 -ExposeVirtualizationExtensions $true -count 2
Set-VMProcessor -VMName SSRV3 -ExposeVirtualizationExtensions $true -count 2

# Create disks for SSRVx VMs
Write-Verbose 'Creating new VHDXs'
$VHDPath = 'D:\v6'
# for STSD
New-VHD -path D:\v6\SSRV1\ssrv1d1.vhdx -Size 128GB -Dynamic | Out-Null
New-VHD -path D:\v6\SSRV1\ssrv1d2.vhdx -Size 128GB -Dynamic | Out-Null
New-VHD -path D:\v6\SSRV1\ssrv1d3.vhdx -Size 128GB -Dynamic | Out-Null

New-VHD -path D:\v6\SSRV2\ssrv2d1.vhdx -Size 128GB -Dynamic | Out-Null
New-VHD -path D:\v6\SSRV2\ssrv2d2.vhdx -Size 128GB -Dynamic | Out-Null
New-VHD -path D:\v6\SSRV2\ssrv2d3.vhdx -Size 128GB -Dynamic | Out-Null

New-VHD -path D:\v6\SSRV3\ssrv3d1.vhdx -Size 128GB -Dynamic | Out-Null
New-VHD -path D:\v6\SSRV3\ssrv3d2.vhdx -Size 128GB -Dynamic | Out-Null
New-VHD -path D:\v6\SSRV3\ssrv3d3.vhdx -Size 128GB -Dynamic | Out-Null

# Attach the VHDs to the respective VMs
Write-Verbose 'Attach VHDs to VMs'

# For SSRV1 -  disks on controller 0
Add-VMHardDiskDrive -VMName SSRV1 -Path D:\v6\SSRV1\ssrv1d1.vhdx -ControllerType SCSI -ControllerNumber 0
Add-VMHardDiskDrive -VMName SSRV1 -Path D:\v6\SSRV1\ssrv1d2.vhdx -ControllerType SCSI -ControllerNumber 0
Add-VMHardDiskDrive -VMName SSRV1 -Path D:\v6\SSRV1\ssrv1d3.vhdx -ControllerType SCSI -ControllerNumber 0

# For SSRV2 - disks on controller 0
Add-VMHardDiskDrive -VMName SSRV2 -Path D:\v6\SSRV2\ssrv2d1.vhdx -ControllerType SCSI -ControllerNumber 0
Add-VMHardDiskDrive -VMName SSRV2 -Path D:\v6\SSRV2\ssrv2d2.vhdx -ControllerType SCSI -ControllerNumber 0
Add-VMHardDiskDrive -VMName SSRV2 -Path D:\v6\SSRV2\ssrv2d3.vhdx -ControllerType SCSI -ControllerNumber 0

# For SSRV5 - 3 disks on separate controllers
Add-VMScsiController -VMName SSRV3 # add controller 1
Add-VMScsiController -VMName SSRV3 # add controller 2
Add-VMHardDiskDrive -VMName SSRV3 -Path D:\v6\SSRV3\ssrv3d1.vhdx -ControllerType SCSI -ControllerNumber 0
Add-VMHardDiskDrive -VMName SSRV3 -Path D:\v6\SSRV3\ssrv3d2.vhdx -ControllerType SCSI -ControllerNumber 1
Add-VMHardDiskDrive -VMName SSRV3 -Path D:\v6\SSRV3\ssrv3d3.vhdx -ControllerType SCSI -ControllerNumber 2

# See what have we done disk wise

Get-VMHardDiskDrive -VMName ssrv1,ssrv2,ssrv3 | Sort-Object -Property path

$Ht = @{name='Length(GB)'
        expression = {"      $(($_.length/1gb).tostring('n2'))"}
        }

Get-ChildItem -Path D:\v6\ssrv*.vhdx -Recurse | FT Fullname, $ht

#  Check NICs and add one if needed.
# do it 3 times for each SSRVx server
1..3 | foreach {
  $nics = Get-VMNetworkAdapter -VMName "SSRV$_" 
  If ($Nics.count -eq 1) {
  "adding External nic to SSRV$_"
  Add-VMNetworkAdapter -VMName "SSRV$_" -SwitchName 'External'
  }
  Else {"Not adding 2nd NIC to SSRV$_"}
}

# Start the VMs
Start-VM -VMName SSRV1, SSRV2, SSRV3


# reset verbose
Write-Verbose "Resetting verbose preference to [$OVP]"
$VerbosePreference =$OVP 

# in each Vm..

$Conf = {# Define registry path for autologon, then set admin logon
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

#  Add PSUpdate
Install-PackageProvider -Name Nuget -Force
Install-Module PSWindowsUpdate -Force

}

$Computers = 'SSRV1.Reskit.Org',
             'SSRV2.Reskit.Org',
             'SSRV3.Reskit.Org'
$ICMHT = @{
  Computername = $Computers 
  ScriptBlock  = $conf 
  Credential   = $CredRK
}
Invoke-Command @ICMHT

Write-Verbose "Configure-SSRV.ps1 is complete. "



