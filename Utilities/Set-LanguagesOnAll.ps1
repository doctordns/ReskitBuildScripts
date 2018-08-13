# Set-LanguageALL.ps1

# What we want to do
$conf = {
Write-Verbose "Setting Language on: [$(hostname)]"

# Set Lanuage
#organise favourite to be 1st on the list.
Set-WinUserLanguageList en-US,en-GB,nb-NO,sv-SE,sv-FI,nl-NL,nl-BE   -Force
Get-WinUserLanguageList | ft
}

# Start of script proper - first set output mode
$VerbosePreference = 'Continue'

# Where we want to do it
$computers = 'DNS1.reskit.org', 'DNS2.reskit.org'  # computers to fix

# Who we are
$PasswordSS = ConvertTo-SecureString 'Pa$$w0rd' -AsPlainText -Force
$Username = "administrator@reskit.org"
$credrk = New-Object System.Management.Automation.PSCredential $Username,$PasswordSS

# SO let's rock and roll
Invoke-command -ComputerName  dns1,dns2 -ScriptBlock {hostname} -Credential $creddc1 -verbose

Pause

Write-Verbose "Running Conf on $computers"
Invoke-command -ComputerName dns1,dns2 -ScriptBlock $conf -Credential $creddc1 -verbose
