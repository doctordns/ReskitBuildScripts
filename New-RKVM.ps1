# New-RKVM.ps1
# Script that creates VMs
# Version 1.0.0 - 14 Jan 2013
# Version 1.0.1 - Added VHDSize to create-vm function
# Version 1.0.2 - Added more VMs to create (for Packt book etc)
# Version 1.0.3 - updated for Server 2019
#               - added 2nd NIC, and moved where disks are stored


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
        $Name = "DC1",
        $VmPath = "d:\v6",
        $ReferenceVHD = "C:\v6\Ref2019.vhdx",
        $Network = "Internal",
        [int64] $VMMemory = 1024mb,
        $UnattendXML = "C:\v6\unattend.xml",
        $IPAddr = '10.10.10.10/24',
        $DnsSvr = '10.10.10.10'
    )

    $Starttime = Get-Date
    Write-Verbose -Message "Starting Create-VM at: $Starttime"
    Write-verbose "Creating VM          : [$Name]"
    Write-verbose "Path to VM           : [$VMpath]"

    # Check to see if Switch exists (passed in $Network variable)
    If (Get-VMSwitch $Network) {Write-Verbose "VM Switch $Network Exists"} else {
        Write-Verbose "VM Switch $network does not exist -creating!"
        New-VMSwitch -Name Internal -SwitchType Internal
        Write-Verbose "Switch $Network created"
    }

    #    Set path to differencing disk location
    $Path = "$vmpath\$name\$name.vhdx"
    Write-Verbose "Creating Disk at [$Path]"

    #    Add a new differencing VHDX, Based on parent
    $vmDisk01 = New-VHD –Path $Path -Differencing –ParentPath $ReferenceVHD -ErrorAction Stop
    Write-Verbose "Added VM Disk [$($VMdisk01.Path)], pointing to [$ReferenceVHD]"

    #    Create a New VM
    $VM = New-VM –Name $Name –MemoryStartupBytes $VMMemory –VHDPath $VMDisk01.path -SwitchName $Network -Path $vmPath 
    Write-Verbose "VM [$Name] created"

    # Mount the Disk on the local machine
    Mount-DiskImage -ImagePath $path
    $VHDDisk = Get-DiskImage -ImagePath $path | Get-Disk
    $VHDPart = Get-Partition -DiskNumber $VHDDisk.Number
    $VHDVolumeName = [string]$VHDPart.DriveLetter
    $VHDVolume = [string]$VHDPart.DriveLetter + ":"
    Write-verbose "Volume [$VHDVolumename] created in VM [$name]"

    #    Get Unattended.XML file
    Write-Verbose "Using Unattended XML file [$unattendXML]"

    #    Open XML file
    $xml = [xml](get-content $UnattendXML)

    #    Change ComputerName
    Write-Verbose "Setting VM ComputerName to: [$name]"
    $xml.unattend.settings.component | Where-Object { $_.Name -eq "Microsoft-Windows-Shell-Setup" } |
        ForEach-Object {
        if ($_.ComputerName) {
            $_.ComputerName = $name
        }
    }

    #    Change IP address
    Write-Verbose "Setting VM ComputerName to: [$name]"
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
    Write-Verbose "Dismounting disk image: [$Path]"
    Dismount-DiskImage -ImagePath $path

    #    Update additional Settings
    Write-Verbose 'Setting additional VM settings'
    Set-VM -Name $name -DynamicMemory
    Set-VM -Name $name -MemoryMinimumBytes $VMMemory
    Set-VM -Name $name -AutomaticStartAction Nothing
    Set-Vm -Name $name -AutomaticStopAction ShutDown

    #    Show what has been created!
    "VM Created:"
    Get-VM -Name $name | Format-List *

    #    Start VM
    Write-verbose "VM [$Name] being started"
    Start-VM -Name $name

    #    Now work out and write how long it took to create the VM
    $Finishtime = Get-Date
    Write-Verbose ("Creating VM ($name) took {0} seconds" -f ($FinishTime - $Starttime).totalseconds)
}  # End of Create-VM function


# Beginning of the script itself.

#######################################################################################################
#       CHECK THESE PATHS ===== CHECK THESE PATHS ===== CHECK THESE PATHS ===== CHECK THESE PATHS     #

# Location of Server 2012 DVD Iso Image
$Iso   = 'D:\builds\Windows_InsiderPreview_Server_vNext_en-us_17733.iso'

# Where we put the reference VHDX
# Be careful here - make sure this is the file you just created in Create-ReferenceVHDX
$Ref   = 'D:\v6\Ref2019.vhdx'

# Path were VMs, VHDXs and unattend.txt files live
$Path  = 'D:\v6'

# Location of Unattend.xml - first for workstation systems, second for domain joined systems 
$Una   = 'D:\v6\UnAttend.xml'
$Unadj = 'D:\v6\UnAttend.dj.xml'

#       CHECK THESE PATHS ===== CHECK THESE PATHS ===== CHECK THESE PATHS ===== CHECK THESE PATHS     #
#######################################################################################################



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
# Create VMs for all environments
#
# For general use, use the Configure-DC1* scripts to configure DC1 as a nice DC!
# For the PowerShell Cookbook, create two separate workgroup servers and allow the recipes to configure.
#
#  FOR GENERAL USE
#    Create DC1 as NON-domain joined
# New-RKVM -name 'DC1'  -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $una -Verbose -IPAddr '10.10.10.10/24' -DNSSvr 10.10.10.10  -VMMemory 2gb 
#    Configure DC1 using relevant scripts THEN create DC2
# New-RKVM -name "DC2"  -vmPath $path -ReferenceVHD $ref -network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.11/24' -DNSSvr 10.10.10.10  -VMMemory 1gb
#

#  FOR POWERSHELL COOKBOOK USE
# Create DC1 and DC2 as NON-domain joined and allow book recipes to configure
# Since both are workgroup systems, run at same time, then configure with book recipes
# New-RKVM -name 'DC1'  -VmPath $path -ReferenceVHD $ref -Network 'Internal' -UnattendXML $una -Verbose -IPAddr '10.10.10.10/24' -DNSSvr 10.10.10.10  -VMMemory 2gb 
# New-RKVM -name 'DC2'  -vmPath $path -ReferenceVHD $ref -network 'Internal' -UnattendXML $una -Verbose -IPAddr '10.10.10.11/24' -DNSSvr 10.10.10.10  -VMMemory 756mb

#
#    Remaining VMs use the domain-join version of unattend.xml
#

#    CA Servers
# NB: ROOTCA is NOT domain Joined
# New-RKVM -Name "ROOTCA" -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $una   -Verbose -IPAddr '10.10.10.20/24' -DNSSvr 10.10.10.10  -VMMemory 1gb 
# New-RKVM -name "CA"     -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.21/24' -DNSSvr 10.10.10.10  -VMMemory 1gb 

#    General Servers
# New-RKVM -name "SRV1"  -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.50/24' -DNSSvr 10.10.10.10  -VMMemory 1GB
# New-RKVM -name "SRV2"  -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.51/24' -DNSSvr 10.10.10.10  -VMMemory 1GB

#    FS1, FS1 - file servers for which to cluster-Attachments "\\folder\file*.xlsx" 
# New-RKVM -name "FS1" -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.101/24' -DNSSvr 10.10.10.10 -VMMemory 768mb
# New-RKVM -name "FS2" -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.102/24' -DNSSvr 10.10.10.10 -VMMemory 768mb

#    Storage Servers
# New-RKVM -name "SSRV1" -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.111/24' -DNSSvr 10.10.10.10 -VMMemory 1gb
# New-RKVM -name "SSRV2" -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.112/24' -DNSSvr 10.10.10.10 -VMMemory 1gb
# New-RKVM -name "SSRV3" -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.113/24' -DNSSvr 10.10.10.10 -VMMemory 1gb

#    HV1, HV2 - Hyper-V Servers
# New-RKVM -name "HV1" -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.201/24' -DNSSvr 10.10.10.10 -VMMemory 768mb
# New-RKVM -name "HV2" -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.202/24' -DNSSvr 10.10.10.10 -VMMemory 2gb

#    NLB servers
# New-RKVM -name "NLB1"  -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.53/24' -DNSSvr 10.10.10.10  -VMMemory 2GB
# New-RKVM -name "NLB2"  -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.54/24' -DNSSvr 10.10.10.10  -VMMemory 2GB

#    Print Server
# New-RKVMM -name "PSRV" -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.60/24' -DNSSvr 10.10.10.10 -VMMemory 768mb

#    WSUS Server
 New-RKVM -name "WSUS1" -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.251/24' -DNSSvr 10.10.10.10 -VMMemory 1gb

#    Container Host
# New-RKVM -name "CH1" -VmPath $path -ReferenceVHD $ref -Network "Internal" -UnattendXML $unadj -Verbose -IPAddr '10.10.10.221/24' -DNSSvr 10.10.10.10 -VMMemory 1gb


#######################################################################################################
#  script is all done - just say nice things and quit.
$Finish = Get-Date
"Create-VM.ps1 finished at : $Finish"
"Elapsed Time              :  $(($Finish-$Start).totalseconds) seconds"
#  end of create-vm