#requires –RunAsAdministrator

# New-RKVM.ps1
# Script that creates VMs
# Version 1.0.0 - 14 Jan 2013d
# Version 1.0.1 - Added VHDSize to create-vm function
# Version 1.0.2 - Added more VMs to create (for Packt book etc)
# Version 1.0.3 - updated for Server 2019
#               - added 2nd NIC, and moved where disks are stored
# Version 2.0.0 - New for Packt v7 book - gets rid of differencing disk, use server 2020

# First define the create-VM Function

Function New-RKVM {

  #  +---------------------------------------------+
  #  !                                             !
  #  !           Create a New VM                   !
  #  !                                             !
  #  +---------------------------------------------+

  # Parameters are Name, Virtual Machine Path, path to reference vhdx, network switch to use,
  # VM Memory, Unattend file, IP address and DNS Server to set


  [Cmdletbinding()]
  Param ( 
    $Name             = 'DC1',
    $VmPath           = 'D:\v9',
    $ReferenceVHD     = 'D:\v9\Ref2020.vhdx',
    $Network          = 'Internal',
    [int64] $VMMemory = 1024mb,
    $UnattendXML      = 'D:\v9\unattend.xml',
    $IPAddr           = '10.10.10.10/24',
    $DnsSvr           = '10.10.10.10'
  )

  $StartTime = Get-Date
  Write-Verbose -Message "Starting Create-VM at: $Starttime"
  Write-verbose "Creating VM           : [$Name]"
  Write-verbose "Path to VM            : [$VMpath]"

  # Check to see if Switch exists (passed in $Network variable)
  If (Get-VMSwitch $Network) { Write-Verbose "VM Switch $Network Exists" } else {
    Write-Verbose "VM Switch not here  : [$Network]"
    New-VMSwitch -Name Internal -SwitchType Internal
    Write-Verbose "Switch Created      : [$Network]"
  }

  #    Copy Diferencing disk to this VM's location
  New-Item -Path $vmpath\$name -Force -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
  $VHDPath = "$vmpath\$name\$name.vhdx"
  Write-Verbose "Copying ref disk      : [$ReferenceVHD]"
  Copy-Item -Path $ReferenceVHD -Destination $VHDPath -Force
  Write-Verbose "Created Disk          : [$VHDPath]"

  #    Create a New VM
  Write-Verbose "Creating VM           : [$Name]"
  Write-Verbose "VHD path              : [$VHDPath]"
  Write-Verbose "VM Path               : [$Path\$Name]"
  $NewVMHT = @{
    Name = $Name 
    MemoryStartupBytes = $VMMemory 
    VHDPath            = $VHDPath 
    SwitchName         = $Network 
    Path               =  $VMPath 
    Generation         =  2
  }

  $VM = New-VM @NewVMHT

  Write-Verbose "New VM Created        : [$($VM.Name)]"

  # Mount the newly created VHD on the local machine
  Mount-DiskImage -ImagePath $VHDPath
  $VHDDisk = Get-DiskImage -ImagePath $vhdpath | Get-Disk
  $VHDPart = Get-Partition -DiskNumber $VHDDisk.Number | Select-Object -First 1

  $VHDVolumeName = ([string]$VHDPart.DriveLetter).trimend()
  $VHDVolume = ([string]$VHDPart.DriveLetter).trim() + ":"
  Write-Verbose "Volume [$VHDVolumename] created in VM [$name]"

#    Get Unattended.XML file
Write-Verbose "Using Unattended XML file [$unattendXML]"

#    Open XML file
$xml = [xml](get-content $UnattendXML)

#    Change Computer Name
Write-Verbose "Setting VM ComputerName to: [$name]"
$xml.unattend.settings.component | Where-Object { $_.Name -eq "Microsoft-Windows-Shell-Setup" } |
  ForEach-Object {
    if ($_.ComputerName) {
      $_.ComputerName = $name
    }
  }

#    Change IP address
Write-Verbose "Setting VM IPv4 address to: [$IPAddr]"
$xml.unattend.settings.component | Where-Object { $_.Name -eq "Microsoft-Windows-TCPIP" } |
  ForEach-Object {

    if ($_.Interfaces) {
      $ht = '#text'
      $_.interfaces.interface.unicastIPaddresses.ipaddress.$ht = $IPAddr
    }
  }

#    Change DNS Server address
Write-Verbose "Setting VM DNS address to: [$DNSSvr]"
$xml.unattend.settings.component | Where-Object { $_.Name -eq "Microsoft-Windows-DNS-Client" } |
  ForEach-Object {
    if ($_.Interfaces) {
      $ht = '#text'
      $_.interfaces.interface.DNSServerSearchOrder.ipaddress.$ht = $DNSSvr
    }
  }

#    Save XML File on Mounted VHDX file
$xml.Save("$VHDVolume\Unattend.XML")
Write-Verbose "Unattended XML file saved to vhd [$vhdvolume\unattend.xml]"

#    Dismount VHDX 
Write-Verbose "Dismounting disk image: [$VHDPath]"
Dismount-DiskImage -ImagePath $VHDPath | Format-table

#    Update additional Settings
Write-Verbose 'Setting additional VM settings'
Set-VM -Name $name -DynamicMemory
Set-VM -Name $name -MemoryMinimumBytes $VMMemory
Set-VM -Name $name -AutomaticStartAction Nothing
Set-VM -Name $name -AutomaticStopAction ShutDown

#    Show what has been created!
"VM Fully Created:"
Get-VM -Name $name  | Format-Table

#    Start VM
Write-Verbose "VM [$Name] being started"
Start-VM -Name $name

#    Now work out and write how long it took to create the VM
$Finishtime = Get-Date
Write-Verbose ("Creating VM ($name) took {0} seconds" -f ($FinishTime - $Starttime).totalseconds)
}  # End of Create-VM function


# Beginning of the script itself.

#######################################################################################################
#       CHECK THESE PATHS ===== CHECK THESE PATHS ===== CHECK THESE PATHS ===== CHECK THESE PATHS     #

# Location of Server 2012 DVD Iso Image
$Iso = 'd:\Builds\en-us_windows_server_2022_x64_dvd_620d7eac.iso'

# Where we put the reference VHDX
# Be careful here - make sure this is the file you just created in Create-ReferenceVHDX
$Ref = 'D:\v9\Ref2022.vhdx'

# Path were VMs, VHDXs and unattend.txt files live
$Path = 'D:\V9'

# Location of Unattend.xml - first for workstation systems, second for domain joined systems 
$Una   = 'D:\v9\UnAttend.xml'     # workgroup memeber
$Unadj = 'D:\v9\UnAttend.dj.xml'  # joined to reskit.org

#       CHECK THESE PATHS ===== CHECK THESE PATHS ===== CHECK THESE PATHS ===== CHECK THESE PATHS     #
#######################################################################################################
If (Test-Path $Iso) {    # testing ISO path
  Write-Verbose "ISO Image found [$Iso]"
}
else {
  Throw "Iso Image not found [$iso]"
}

If (Test-Path $REF) {     # Testing Reference Image
  Write-Verbose "Reference Image found [$REF]"
}
else {
  Throw "Reference Image not found [$REF]"
}

If (Test-Path $UNA) { # Testing unattend work group XML
  Write-Verbose "UNA XML Found [$UNA]"
}
else {
  Throw "UNA XML not found [$UNA]"
}

If (Test-Path $UNADJ) {
  Write-Verbose "UNADJ XML found [$UNADJ]"
}
else {
  Throw "UNADJ not found [$UNADJ]"
}

#   Now run the script to create the VMs as appropriate.
$Start = Get-Date


#######################################################################################################
#        Comment out the VMs you do NOT want to create then run the entire script
#        To comment out a VM creation, just add a '#" at the start of the line. 
#        Removing the comment line means you want to create that VM. 
#        BE creful!  If you make a mistake, stop the script. Kill any VMs created, then remove the
#        storage for the VMs. 
#
#        NOte this script is used for many PSMC courses - your course may not need ALL VMs created
#        Follow the directions in your lab guide, and before creating any VM, if you are in any doubt
#        Ask your instructor.
#######################################################################################################

##############
#
# Create VMs for PowerShell Master Class environment
#
# After OS installation, use the Configure-DC1* scripts to configure DC1 as a nice DC!
#
#  FOR GENERAL USE 
#    Create DC1 as NON-domain joined
# New-RKVM -name 'DC1'  -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $una -Verbose -IPAddr '10.10.10.10/24' -DNSSvr 10.10.10.10  -VMMemory 4gb 
#
#   SQL 2016
# New-RKVM -name "SQL2016" -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.221/24' -DNSSvr 10.10.10.10 -VMMemory 4gb
# And two general purpose servers
# New-RKVM -name 'SRV1'  -VmPath $path -ReferenceVHD $ref -Network 'Internal' -UnattendXML $unadj -Verbose -IPAddr '10.10.10.50/24' -DNSSvr 10.10.10.10  -VMMemory 4GB
# New-RKVM -name 'SRV2'  -VmPath $path -ReferenceVHD $ref -Network 'Internal' -UnattendXML $unadj -Verbose -IPAddr '10.10.10.50/24' -DNSSvr 10.10.10.10  -VMMemory 4GB

# for testing only 
# New-RKVM -name 'SRV1x'  -VmPath $path -ReferenceVHD $ref -Network 'Internal' -UnattendXML $unadj -Verbose -IPAddr '10.10.10.50/24' -DNSSvr 10.10.10.10  -VMMemory 4GB


#  Then use the configuration scripts as directed to build out each server.



#  For Thomas Lee's book projects
#
#  Your starting point depends on which book!

# 
#  For Packt POWERSHELL 7.1 Book - chap 1,2,3) - not domain joined till later
# New-RKVM -Name 'SRV1'  -VmPath $Path -ReferenceVHD $Ref -Network 'Internal' -UnattendXML $una -Verbose -IPAddr '10.10.10.50/24' -DNSSvr 10.10.10.10  -VMMemory 4GB

# Create DC1 as unjoined initially
#  New-RKVM -Name 'DC1'  -VmPath $path -ReferenceVHD $ref -Network 'Internal' -UnattendXML $una -Verbose -IPAddr '10.10.10.10/24' -DNSSvr 10.10.10.10  -VMMemory 2gb 

# Create DC2 as domain joined after DC1 is a DC
# New-RKVM -name 'DC2'  -vmPath $path -ReferenceVHD $ref -network 'Internal' -UnattendXML $unadj -Verbose -IPAddr '10.10.10.11/24' -DNSSvr 10.10.10.10  -VMMemory 2GB

# UKDC1 - created initially in reskit.org net, then becomes a child DC
# New-RKVM -name 'UKDC1'  -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.12/24' -DNSSvr 10.10.10.10  -VMMemory 4gb

# Create SRV2 as workgroup host after DC1/DC2/UKDC1 created as DCs
# New-RKVM -name 'SRV2'  -VmPath $path -ReferenceVHD $ref -Network 'Internal' -UnattendXML $una -Verbose -IPAddr '10.10.10.51/24' -DNSSvr 10.10.10.10  -VMMemory 4GB

# for Wiley book only
#  And KAPDC1.Kapoho.Com - DC/DNS in Kapoho.com domain - starts as work group host
# New-RKVM -name "KAPDC1"  -vmPath $path -ReferenceVHD $ref -network "Internal" -UnattendXML $una -Verbose -IPAddr '10.10.10.131/24' -DNSSvr 10.10.10.131  -VMMemory 1gb

#    FS1, FS1 - file servers for which to cluster
# New-RKVM -name "FS1" -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.101/24' -DNSSvr 10.10.10.10 -VMMemory 4gb
# New-RKVM -name "FS2" -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.102/24' -DNSSvr 10.10.10.10 -VMMemory 4gb

#    Storage Server - for iSCSI target
# New-RKVM -name "SS1" -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.111/24' -DNSSvr 10.10.10.10 -VMMemory 4gb

# SMTP server
# New-RKVM -name "SMTP" -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.251/24' -DNSSvr 10.10.10.10 -VMMemory 4gb


#    HV1, HV2 - Hyper-V Servers
# New-RKVM -name "HV1" -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.201/24' -DNSSvr 10.10.10.10 -VMMemory 4GB
# New-RKVM -name "HV2" -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.202/24' -DNSSvr 10.10.10.10 -VMMemory 4GB

#    NLB servers - Windows PowerShell only
# New-RKVM -name "NLB1"  -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.53/24' -DNSSvr 10.10.10.10  -VMMemory 4GB
# New-RKVM -name "NLB2"  -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.54/24' -DNSSvr 10.10.10.10  -VMMemory 4GB

#    Print Server
# New-RKVM -name "PSRV" -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.60/24' -DNSSvr 10.10.10.10 -VMMemory 4gb

#    WSUS Server - Windows PowerShell only
New-RKVM -name "WSUS1" -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.251/24' -DNSSvr 10.10.10.10 -VMMemory 1gb

#    Container Host
# New-RKVM -name "CH1" -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.221/24' -DNSSvr 10.10.10.10 -VMMemory 4gb

# for testing only
# New-RKVM -name 'DC1X'  -VmPath $path -ReferenceVHD $ref -Network 'Internal' -UnattendXML $una -Verbose -IPAddr '10.10.10.10/24' -DNSSvr 10.10.10.10  -VMMemory 2gb 
# New-RKVM -name 'SRV1x' -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.50/24' -DNSSvr 10.10.10.10  -VMMemory 4GB
# New-RKVM -name 'SRV2x' -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.51/24' -DNSSvr 10.10.10.10  -VMMemory 4GB
# New-RKVM -name 'FS1x'  -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.101/24' -DNSSvr 10.10.10.10 -VMMemory 4gb
# New-RKVM -name 'FS2x'  -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.102/24' -DNSSvr 10.10.10.10 -VMMemory 4gb




#######################################################################################################
#  script is all done - just say nice things and quit.
$Finish = Get-Date
"Create-VM.ps1 finished at : $Finish"
"Elapsed Time              :  $(($Finish-$Start).totalseconds) seconds"
#  end of New-RKVM.ps1
