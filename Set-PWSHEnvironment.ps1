#  Set-PWSHEnvironment.ps1
#
# Sets up the PowerShell 7 Environment on a host
# Installs latest version of PowerShell, and VS Code with a few extensions

# 1. Install Nuget and Powershellget
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
Install-PackageProvider Nuget -Force |
  Out-Null
Install-Module -Name PowerShellGet -Force -AllowClobber 

# 2. Install PS 7
New-Item -Path c:\Foo -ItemType Directory -EA 0
Set-Location -Path c:\Foo
$URI = "https://aka.ms/install-powershell.ps1"
Invoke-RestMethod -Uri $URI | 
  Out-File -FilePath C:\Foo\Install-PowerShell.ps1
C:\Foo\Install-PowerShell.ps1 -UseMSI -Preview -Quiet

# 3. Save install-vscode script
Save-Script -Name Install-VSCode -Path C:\Foo

# 4. Now run it and add in some popular VSCode Extensions
#    Ignore depricated method warnings.
$Extensions =  "Streetsidesoftware.code-spell-checker",
               "yzhang.markdown-all-in-one",
               "davidanson.vscode-markdownlint"
$InstallHT = @{
  BuildEdition         = 'Stable'
  AdditionalExtensions = $Extensions
  LaunchWhenDOne       = $true
}             
.\Install-VSCode.ps1 @InstallHT

# 5. Enable CredSSP # just in case we need it.
Enable-WSManCredSSP -DelegateComputer * -Role Client -Force
Enable-WSManCredSSP -Role Server -Force
