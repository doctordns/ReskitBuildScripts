####
# Configure-Storage Servers
# Configures SSRV1-3 for storage spaces and storage spaces direct
#
# Version    Date         What Changed
# -------    -----------  -------------------------------------------
# 1.0.0      22 Aug 2018  Initial release


###  SET Variables
$VerbosePreference = 'Continue'

#    Set Credentials
$Username   = "Reskit\administrator"
$Password   = 'Pa$$w0rd'
$PasswordSS = ConvertTo-SecureString  -String $Password -AsPlainText -Force
$CredRK     = New-Object -Typename System.Management.Automation.PSCredential -Argumentlist $Username,$PasswordSS

# First add disks to each of the VMs
Stop-Vm -VMName SSRV1, SSRV2, SSRV3 -Force -TurnOff

# Create disks for SSRVx VMs
Write-Verbose 'Creating new VHDs'
$VHDPath = 'D:\v6'
New-VHD -path D:\v6\SSRV1\ssrv1d1.vhdx -Size 128GB -Dynamic # for SSDirect
New-VHD -path D:\v6\SSRV1\ssrv1d2.vhdx -Size 128GB -Dynamic # for SSDirect
New-VHD -path D:\v6\SSRV1\ssrv1d3.vhdx -Size 128GB -Dynamic # for SSDirect
New-VHD -path D:\v6\SSRV1\ssrv1I1.vhdx -Size 128GB -Dynamic # for iscsi
New-VHD -path D:\v6\SSRV1\ssrv1I2.vhdx -Size 128GB -Dynamic # for iscsi

New-VHD -path D:\v6\SSRV2\ssrv2d1.vhdx -Size 128GB -Dynamic # for SSDirect
New-VHD -path D:\v6\SSRV2\ssrv2d2.vhdx -Size 128GB -Dynamic # for SSDirect
New-VHD -path D:\v6\SSRV2\ssrv2d3.vhdx -Size 128GB -Dynamic # for SSDirect

New-VHD -path D:\v6\SSRV3\ssrv3d1.vhdx -Size 128GB -Dynamic # for SSDirect
New-VHD -path D:\v6\SSRV3\ssrv3d2.vhdx -Size 128GB -Dynamic # for SSDirect
New-VHD -path D:\v6\SSRV3\ssrv3d3.vhdx -Size 128GB -Dynamic # for SSDirect

# Attach the VHDs to the respective VMs
Write-Verbose 'Attach VHDs to VMs'
Add-VMHardDiskDrive  -VMName SSRV1 -Path D:\v6\SSRV1\ssrv1d1.vhdx -ControllerType SCSI -ControllerNumber 0
Add-VMHardDiskDrive  -VMName SSRV1 -Path D:\v6\SSRV1\ssrv1d2.vhdx -ControllerType SCSI -ControllerNumber 0
Add-VMHardDiskDrive  -VMName SSRV1 -Path D:\v6\SSRV1\ssrv1d3.vhdx -ControllerType SCSI -ControllerNumber 0

Add-VMScsiController -VMName SSRV1
Add-VMHardDiskDrive  -VMName SSRV1 -Path D:\v6\SSRV1\ssrv1I1.vhdx -ControllerType SCSI -ControllerNumber 1
Add-VMHardDiskDrive  -VMName SSRV1 -Path D:\v6\SSRV1\ssrv1I2.vhdx -ControllerType SCSI -ControllerNumber 1

Add-VMHardDiskDrive -VMName SSRV2 -Path D:\v6\SSRV2\ssrv2d1.vhdx -ControllerType SCSI -ControllerNumber 0
Add-VMHardDiskDrive -VMName SSRV2 -Path D:\v6\SSRV2\ssrv2d2.vhdx -ControllerType SCSI -ControllerNumber 0
Add-VMHardDiskDrive -VMName SSRV2 -Path D:\v6\SSRV2\ssrv2d3.vhdx -ControllerType SCSI -ControllerNumber 0

Add-VMScsiController -VMName SSRV3 # controller 1
Add-VMScsiController -VMName SSRV3 # controller 2
Add-VMHardDiskDrive -VMName SSRV3 -Path D:\v6\SSRV3\ssrv3d1.vhdx -ControllerType SCSI -ControllerNumber 0
Add-VMHardDiskDrive -VMName SSRV3 -Path D:\v6\SSRV3\ssrv3d2.vhdx -ControllerType SCSI -ControllerNumber 1
Add-VMHardDiskDrive -VMName SSRV3 -Path D:\v6\SSRV3\ssrv3d3.vhdx -ControllerType SCSI -ControllerNumber 2

# See what have we done disk wise

Get-VMHardDiskDrive -VMName ssrv1,ssrv2,ssrv3 | sort path

$Ht = @{name='Length(GB)'
        expression = {((($_.length)/1gb)).tostring('n3')}
        }

Get-ChildItem -Path D:\v6\ssrv*.vhdx -Recurse | FT Fullname, $ht

#  Check NICs and add one if needed.

1..3 | foreach {
  $nics = Get-VMNetworkAdapter -VMName "SSRV$_" 
  If ($Nics.count -eq 1) {
  "adding External nic to SSRV$_"
  Add-VMNetworkAdapter -VMName "SSRV$_" -SwitchName 'External'
  }
  Else {"Not adding 2nd NIC"}
}

# Start the VMs
Start-VM -VMName SSRV1, SSRV2, SSRV3


#  FOR NOW NOTHING TO ADD INTO THIS SERVER

Write-Verbose "Configure-SSRV.ps1 is complete. "
