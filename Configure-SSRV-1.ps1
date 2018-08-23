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
Write-Verbose 'Enabling hyper-v inside vms'
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


# For iSCSI
New-VHD -path D:\v6\SSRV1\ssrv1I1.vhdx -Size 128GB -Dynamic | Out-Null
New-VHD -path D:\v6\SSRV1\ssrv1I2.vhdx -Size 128GB -Dynamic | Out-Null

New-VHD -path D:\v6\SSRV2\ssrv2I1.vhdx -Size 128GB -Dynamic | Out-Null
New-VHD -path D:\v6\SSRV2\ssrv2I2.vhdx -Size 128GB -Dynamic | Out-Null

New-VHD -path D:\v6\SSRV3\ssrv3I1.vhdx -Size 128GB -Dynamic | Out-Null
New-VHD -path D:\v6\SSRV3\ssrv3I2.vhdx -Size 128GB -Dynamic | Out-Null

# Attach the VHDs to the respective VMs
Write-Verbose 'Attach VHDs to VMs'

# For SSRV1 -  disks on controller 0, 2 on Controller 1
Add-VMHardDiskDrive  -VMName SSRV1 -Path D:\v6\SSRV1\ssrv1d1.vhdx -ControllerType SCSI -ControllerNumber 0
Add-VMHardDiskDrive  -VMName SSRV1 -Path D:\v6\SSRV1\ssrv1d2.vhdx -ControllerType SCSI -ControllerNumber 0
Add-VMHardDiskDrive  -VMName SSRV1 -Path D:\v6\SSRV1\ssrv1d3.vhdx -ControllerType SCSI -ControllerNumber 0
#  new controller and two additional disks
Add-VMScsiController -VMName SSRV1
Add-VMHardDiskDrive  -VMName SSRV1 -Path D:\v6\SSRV1\ssrv1I1.vhdx -ControllerType SCSI -ControllerNumber 1
Add-VMHardDiskDrive  -VMName SSRV1 -Path D:\v6\SSRV1\ssrv1I2.vhdx -ControllerType SCSI -ControllerNumber 1

# For SSRV2 - 5 disks on controller 0
Add-VMHardDiskDrive -VMName SSRV2 -Path D:\v6\SSRV2\ssrv2d1.vhdx -ControllerType SCSI -ControllerNumber 0
Add-VMHardDiskDrive -VMName SSRV2 -Path D:\v6\SSRV2\ssrv2d2.vhdx -ControllerType SCSI -ControllerNumber 0
Add-VMHardDiskDrive -VMName SSRV2 -Path D:\v6\SSRV2\ssrv2d3.vhdx -ControllerType SCSI -ControllerNumber 0
Add-VMHardDiskDrive -VMName SSRV2 -Path D:\v6\SSRV2\ssrv2I1.vhdx -ControllerType SCSI -ControllerNumber 0
Add-VMHardDiskDrive -VMName SSRV2 -Path D:\v6\SSRV2\ssrv2I2.vhdx -ControllerType SCSI -ControllerNumber 0

# For SSRV5 - 5 disks on separate controllers
Add-VMScsiController -VMName SSRV3 # add controller 1
Add-VMScsiController -VMName SSRV3 # add controller 2
Add-VMScsiController -VMName SSRV3 # add controller 3
Add-VMScsiController -VMName SSRV3 # add controller 4

Add-VMHardDiskDrive -VMName SSRV3 -Path D:\v6\SSRV3\ssrv3d1.vhdx -ControllerType SCSI -ControllerNumber 0
Add-VMHardDiskDrive -VMName SSRV3 -Path D:\v6\SSRV3\ssrv3d2.vhdx -ControllerType SCSI -ControllerNumber 1
Add-VMHardDiskDrive -VMName SSRV3 -Path D:\v6\SSRV3\ssrv3d3.vhdx -ControllerType SCSI -ControllerNumber 2
Add-VMHardDiskDrive -VMName SSRV3 -Path D:\v6\SSRV3\ssrv3I1.vhdx -ControllerType SCSI -ControllerNumber 3
Add-VMHardDiskDrive -VMName SSRV3 -Path D:\v6\SSRV3\ssrv3I2.vhdx -ControllerType SCSI -ControllerNumber 4

# See what have we done disk wise

Get-VMHardDiskDrive -VMName ssrv1,ssrv2,ssrv3 | sort path

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

#  FOR NOW NOTHING more TO ADD INTO THIS SERVER
Write-Verbose "Configure-SSRV.ps1 is complete. "

