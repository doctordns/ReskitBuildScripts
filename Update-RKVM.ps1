# Update-RKVM

# updates an RK VM

Function Update-RKVM {

[CmdletBinding()]
Param(
$VMName,
$CPUCount = 1,
$Memory   = 4,  #gb
$NHV      = $False
)

# Get VM
$VM = Get-VM -VMname $VMname
Write-Verbose "VM [$VMName] found"

# Stop it if it's running
If ($VM.State -eq 'Running') {
Stop-VM -VMName $VMName
Write-Verbose "Stopping VM: [$VMName]"
}
Else {
Write-Verbose "VM [$VMName] is NOT running"
}

# Set CPU Count
Set-VM -VMName $VMName -ProcessorCount $CPUCount
Write-Verbose "Setting CPU Count to: [$CPUCount]"

# Set memory
$M = 1GB * $Memory
Write-Verbose "Setting VM Memory to: [$m]"
Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $True -MinimumBytes $m -Startupbytes ($m + 128MB)
Write-Verbose "Setting Memory to: [$($memory)GB]"

# Expose virtualisation in the VM?
Set-VMProcessor -VMName $VMName -ExposeVirtualizationExtensions $NHV
Write-Verbose "VM $VMName to enable nested HyperV: [$NHV]"

# ALL DONE
Start-VM -VMname $VMName
Write-Verbose "VM $VMName restarted"
}
