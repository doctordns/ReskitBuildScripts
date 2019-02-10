#  create volumes
# Assume new VHDX files just added as disks
# run on srv1

$Disks = Get-Disk
$DF = $Disks[1]
$DG = $Disks[2]
Initialize-Disk -UniqueId $DF.UniqueId -PartitionStyle GPT
Initialize-Disk -UniqueId $DG.UniqueId -PartitionStyle GPT

$SB = {
$Disks = Get-Disk
$DF = $Disks[1]
$DG = $Disks[2]
Initialize-Disk -UniqueId $DF.UniqueId -PartitionStyle GPT
Initialize-Disk -UniqueId $DG.UniqueId -PartitionStyle GPT
}
Invoke-Command -ComputerName SRV2 -ScriptBlock $SB

# create f, g on srv1
New-Volume -Disk $DF -FileSystem NTFS -DriveLetter F -FriendlyName 'SRV1-F'
New-Volume -Disk $DG -FileSystem NTFS -DriveLetter G -FriendlyName 'SRV2-G'

# create f, g on srv2
$SB = {
$Disks = Get-Disk
$DF = $Disks[1]
$DG = $Disks[2]
New-Volume -Disk $DF -FileSystem NTFS -DriveLetter F -FriendlyName 'SRV2-F'
New-Volume -Disk $DG -FileSystem NTFS -DriveLetter G -FriendlyName 'SRV2-G'
}
Invoke-Command -ComputerName SRV2 -ScriptBlock $SB


Test-SRTopology -SourceComputerName SR-SRV05 -SourceVolumeName f: -SourceLogVolumeName g: `
-DestinationComputerName SR-SRV06 -DestinationVolumeName f: -DestinationLogVolumeName g: `
 -DurationInMinutes 30 -ResultPath c:\temp  