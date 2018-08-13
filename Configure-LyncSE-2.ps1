#
# Install SE on SE1
# Part 2 - need to logoff at the end of this to re-logon with new admin rights!
#
#
$conf = {
$VerbosePreference = 'Continue'

# Mount the DVD
$Drive = Mount-DiskImage -ImagePath C:\_install\en_lync_server_2013_x64_dvd_1043673.iso -PassThru
$Lyncdriveletter = ($Drive | Get-Volume).Driveletter
Write-Verbose "Installing Lync from $LyncDriveLetter drive"

# Install VCC redistributable (vcredist_x64.exe)
Try {
    Write-Verbose "Installing VCC redistributable from e: drive"
    e:\Setup\amd64\vcredist_x64.exe /install /quiet
    start-Sleep -Seconds 5
    Write-Verbose 'Waiting for installation of VSS redistrituable from Edriveletter drive'
    Do {Start-Sleep -Seconds 5} While (Get-Process vcredist_x64 -ErrorAction SilentlyContinue)
}
catch {
    Write-Verbose 'Installing vss redistributable failed'
}
Write-Verbose "Installed VCC redistributable"

# Now install OCS Core (ocscore.msi)
Try {
    Write-Verbose "Installing OCSCORE.MSI from e: drive"
    E:\Setup\amd64\Setup\ocscore.msi /q
    start-Sleep -Seconds 5
    Write-Verbose 'Waiting for installation of OCSCore E: drive'
    Do {Start-Sleep -Seconds 5} While (Get-Process OCSCore -ErrorAction SilentlyContinue)
}
catch {
    Write-Verbose 'OCSCore failed'
}
Write-Verbose "Installed OCS Core"


# Install SQL CLR types
Try {
    Write-Verbose "Installing SQL CLR Types from E: drive"
    E:\Setup\amd64\SQLSysClrTypes.msi /q
    Write-Verbose 'Waiting for installation of CLRTypes E: drive'
    Do {Start-Sleep -Seconds 5} While (Get-Process sqlsysclrtypes -ErrorAction SilentlyContinue)
}
catch {
    Write-Verbose 'SQL CLR TYpes failed'
}
Write-Verbose "Installed SQL CLR types"

# Install SharedManagementObjects.msi
Try {
    Write-Verbose "Installing Shared Management Objects from e: drive"
    E:\Setup\amd64\SharedManagementObjects.msi /q
    Write-Verbose 'Waiting for installation of Sharedmanagement object from e:'
    Do {Start-Sleep -Seconds 5} While (Get-Process OCSCore -ErrorAction SilentlyContinue)
}
catch {
    Write-Verbose 'Installation of Shared Management Objects'
}
Write-Verbose "Installed Shared Mangement Objects"

# Install Admin Tools
Try {
    Write-Verbose "Installing Admin tools from E: drive"
    E:\Setup\amd64\setup\admintools.msi /q
    Do {Start-Sleep -Seconds 5} While (Get-Process admintools -ErrorAction SilentlyContinue)
}
catch {
    Write-Verbose 'Installing Admin tools failed'
}

} # End of $conf

# second logon
$conf2 = {
$VerbosePreference = 'Continue'

# Load Lync Module
Write-Verbose 'Importing Lync Module'
Import-Module 'C:\Program Files\Common Files\Microsoft Lync Server 2013\Modules\Lync\Lync.psd1'
Write-Verbose "$((get-command -module lync).count) commands loaded from Lync Module"

# Now setup AD
# First update schema
Write-Verbose 'Installing Lync Schema updates'
Install-CSAdServerSchema    -Confirm:$false -Verbose -Report "C:\_install\Install-CSAdServerSchema.html"

# Next enable Forest
Write-Verbose 'Enabling AD Forest'
Enable-CSAdForest           -Confirm:$false -Verbose -Report "C:\_install\Enable-CSAdForest.html"

# Now domaain prop
Write-Verbose 'Enabling AD Domain'
Enable-CSAdDomain           -Confirm:$false -Verbose -Report "C:\_install\Enable-CSAdDomain.html"

# Add admin to the right groups
Write-Verbose 'Adding Administrator to Domain Admins, and domain admins to RTCUniversalServerAdmins'
Add-ADGroupMember -Identity CSAdministrator -Members "Domain Admins"
Add-ADGroupMember -Identity RTCUniversalServerAdmins -Members "Domain Admins"

# Install the CS database
Write-Verbose 'Installing CS Database'
Install-CsDatabase -CentralManagementDatabase -SqlServerFqdn Se1.Reskit.Org -DatabasePaths 'C:\CSDB-Logs','C:\CSDB-CMS' -Report 'C:\_install\InstallDatabases.html'
Set-CsConfigurationStoreLocation -SqlServerFqdn SE1.reskit.org -Report 'C:\_install\Set-CsConfigurationStoreLocation.html'

Publish-CSTopology -Filename '$topologypath' -Force
Enable-CSTopology

}

####
## Start of script Configure-LyncSE-2.ps1
###

$StartTime = Get-Date
Write-Verbose '***'
Write-Verbose 'Starting Part 2 - insalling Lync Server'
Write-Verbose "Started At: $StartTime"

#  Create Reskit Administrator credentials
$PasswordSS = ConvertTo-SecureString 'Pa$$w0rd' -AsPlainText -Force
$Username = "Reskit\administrator"
$Credrk = New-Object System.Management.Automation.PSCredential $Username,$PasswordSS

# testing SE1 - this can be removed at a later date!
Invoke-Command -ScriptBlock {gip;hostname} -ComputerName SE1.reskit.org -Credential $credrk
Pause

# Do initial setup - load Lync basics
Invoke-Command -ScriptBlock $conf -ComputerName SE1.reskit.org -Credential $credrk

# Now reboot SE1
Write-Verbose 'Rebooting SE1'
Restart-Computer -ComputerName SE1.reskit.org  -Wait -For PowerShell -Force -Credential $CredRK
Write-Verbose 'Waiting 30 more seconds for reboot to really finish'
Start-Sleep -Seconds 30 # wait for reboot to really finish
Write-Verbose 'Rebooted SE1'
Pause
write-verbose '...continuing'

# For now - can be removed later
pause

# Do part 2 - Prepare the AD
Invoke-Command -ScriptBlock $conf2 -ComputerName SE1 -Credential $credrk

# All done Configure-LyncSE-2
$FinishTime = Get-Date
Write-Verbose "Finished at:  $FinishTime"
Write-Verbose "Elapsed time: $(($finishtime-$StartTime).totalminutes.tostring('N2')) minutes"
