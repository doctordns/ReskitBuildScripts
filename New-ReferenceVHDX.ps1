# Create-ReferenceVHDX.ps1
# Script that creates a reference VHDX for later VM Creation
# Version 1.0.0 - 14 Jan 2013
#   First version released
# Version 1.1.0 - 24 Jan 201
#   Added a check to ensure the VHDX exists and failing if not.
#   Typically this is just an error with the value passed in
#   Also, changed time display to display seconds with just 2 decimal points.\
# Version 1.1.1 21 Feb
#   changed disk size on Reference disk to 128gb.
# Version 1.2 Updated for Server 2016
# Version 1.3 - Updated for Server 2019 and rename file and function.
#             - Iso updated to 17733


# Define a function to create a reference VHDX. 

Function New-ReferenceVHDX {

[Cmdletbinding()]
Param (
#     ISO of OS
      [string] $Iso = $(Throw 'No ISO specified'),

#     Path to reference VHD
      [string] $RefVHDXPath = $(Throw 'No Reference disk specified')
)

# Get start time
$StartTime = Get-Date
Write-Verbose "Beginning at $StartTime"

# First do some error checking
If   (Test-Path $iso) {Write-Verbose "ISO Path [$iso] exists"}
Else {Write-Verbose "ISO Path missing - quitting";Return}

# Import the DISM module
Write-Verbose 'Loading DISM module' -Verbose:$false
Import-Module -Name DISM -Verbose:$False

# Mount the OS ISO image onto the local machine
Write-Verbose "Mounting ISO image [$iso]"
Mount-DiskImage -ImagePath $iso 

# Get the Volume the Image is mounted to
Write-Verbose 'Getting disk image of the ISO'
$ISOImage = Get-DiskImage -ImagePath $ISO | Get-Volume
Write-Verbose "Got disk image [$($ISOImage.DriveLetter)]"

# Get the drive Letter of the drive where the image is mounted
# Add the drive letter separator (:)
$ISODrive = [string]$ISOImage.DriveLetter+":"
Write-Verbose "OS ISO mounted on drive letter [$ISODrive]"

# Next we will get the installation versions from the install.wim.
# $Indexlist is the index of WIMs on the DVD - display the versions
# available in the DVD and let user select the one to serve as the base
# image - probably DataCentre Full Install
$IndexList = Get-WindowsImage -ImagePath $ISODrive\sources\install.wim
Write-Verbose "$($indexList.count) images found"

# don't Display the list and return the index
$item = $IndexList | Out-GridView -OutputMode Single
$index = $item.ImageIndex

# Just create it

Write-Verbose "Selected image index [$index]"
Write-Verbose "Image Name: [$($indexlist[$index].Imagename)]"

# Create the VHDX for the reference image
$VMDisk01 = New-VHD –Path $RefVHDXPath -SizeBytes 128GB
Write-Verbose "Created VHDX File [$($vmdisk01.path)]"

# Get the disk number
Mount-DiskImage -ImagePath $RefVHDXPath
$VHDDisk = Get-DiskImage -ImagePath $RefVHDXPath | Get-Disk
$VHDDiskNumber = [string]$VHDDisk.Number
Write-Verbose "Reference image is on disk number [$VhddiskNumber]"

# Create a New Partition on this disk
# This block may throw a dialog box which you can just cancel!
Initialize-Disk -Number $VHDDiskNumber -PartitionStyle MBR
$VHDDrive = New-Partition -DiskNumber $VHDDiskNumber `
           -AssignDriveLetter -UseMaximumSize  -IsActive |
                Format-Volume -Confirm:$false

$VHDVolume = [string]$VHDDrive.DriveLetter+":"
Write-Verbose "VHD drive [$vhddrive], Vhd volume [$vhdvolume]"

# Execute DISM to apply image to reference disk
Write-Verbose 'Using DISM to apply image to the volume'
Write-Verbose "Started at [$(Get-Date)]"
Write-Verbose 'THIS WILL TAKE SOME TIME!'
Dism.exe /apply-Image /ImageFile:$ISODrive\Sources\install.wim /index:$Index /ApplyDir:$VHDVolume\
Write-Verbose "Finished at [$(Get-Date)]"

# Execute BCDBoot so volume will boot
Write-Verbose 'Setting BCDBoot'
BCDBoot.exe $VHDVolume\Windows /s $VHDVolume /f BIOS

# Dismount the Images
Write-Verbose "Dismounting ISO and new disk"
Dismount-DiskImage -ImagePath $ISO
Dismount-DiskImage -ImagePath $RefVHDXPath

Write-Verbose "Created Reference Disk [$RefVHDXPath]"
Get-ChildItem $RefVHDXPath

$FinishTime = Get-Date
$TT= $FinishTime - $StartTime
Write-Verbose  "Finishing at $FinishTime"
Write-verbose  "Creating base image took [$($TT.totalminutes.tostring('n2'))] minutes"
}  # End of Create-ReferenceVHDX

################################################################################################################
#       CHECK THESE PATHS ===== CHECK THESE PATHS ===== CHECK THESE PATHS ===== CHECK THESE PATHS              #

#    Path to Server 2016 DVD                                                                                      
 $ISO          = 'd:\BUILDS\en_windows_server_2019_x64_dvd_4cb967d8.iso'

#    PathTo the reference VDHX is to go     
 $RefVhdxPath  = 'D:\v6\Ref2019RTM.vhdx'

#       CHECK THESE PATHS ===== CHECK THESE PATHS ===== CHECK THESE PATHS ===== CHECK THESE PATHS               #
#################################################################################################################
# But just to be safe:
"Checking prereqs"
If (! (Test-Path $iso)) {"Product ISO [$iso] not found"; return} 
Else {"Product ISO is found!"}

if (Test-path $RefVhdxPath) {"Reference disk already exists"; return} Else {
"Reference disk not found - to be created now"}

# Ok now do the creation of the reference Hard Disk

New-ReferenceVHDX -iso $Iso -RefVHDXPath $RefVhdxPath  -Verbose