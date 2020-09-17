# Update-RKVM.ps1
# Updates an RK VM

Function Update-RKVM {

[CmdletBinding()]
Param(
  $VMName,
  $CPUCount = 4,
  $Memory   = 4GB,   # MEMORY IN gb
  $NHV      = $False
)

# Start of script
Write-Verbose "Update-RKVM - Updating a VM"

# Check VM Name specified
If ($null -eq $VMName) {
  Write-Error 'No VM Name Specified - returning'
  Return 
}
# Get VM
$VM = Get-VM -VMname $VMname
Write-Verbose "VM [$VMName] found - updating"

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
Write-Verbose "Setting Memory to   : [$($memory/1GB) GB]"

# Expose virtualisation in the VM?
Set-VMProcessor -VMName $VMName -ExposeVirtualizationExtensions $NHV
Write-Verbose "VM $VMName to enable nested HyperV: [$NHV]"

# Add a second NIC and bind to External.

$NICs = Get-VMNetworkAdapter -VMName $VMName
if ($Nics.Count -eq 1) {
  Write-Verbose 'Adding 2nd NIC and binding to External'  
  Add-VMNetworkAdapter -VMName $VMname -SwitchName External
}
else {
  Write-Verbose "Second NIC already exists in $VMName"
}

# ALL DONE
Write-Verbose "Starting $VMName"
Start-VM -VMname $VMName
Write-Verbose "VM $VMName restarted"
}

Update-RKVM -VMName SRV1 -NHV $true -verbose -CPUCount 6
