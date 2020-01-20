# Update-RKVM.ps1`
# JUpdates an RK VM

Function Update-RKVM {

[CmdletBinding()]
Param(
$VMName,
$CPUCount = 4,
$Memory   = 4GB,   # MEMORY IN gb
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
Write-Verbose "Setting VM Memory to: [$Memory]"
Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $True -MinimumBytes $MEMORY -Startupbytes ($Memory + 128MB)
Write-Verbose "Setting Memory to: [$($memory/1GB) GB]"

# Expose virtualisation in the VM?
Set-VMProcessor -VMName $VMName -ExposeVirtualizationExtensions $NHV
Write-Verbose "VM $VMName to enable nested HyperV: [$NHV]"

# Add a second NIC and bind to External.
$NICs = Get-VMNetworkAdapter -VMName $VMName
if ($Nics.Count -eq 1) {
    Add-VMNetworkAdapter -VMName -SwitchName External
}

# ALL DONE
Start-VM -VMname $VMName
Write-Verbose "VM $VMName restarted"
}
