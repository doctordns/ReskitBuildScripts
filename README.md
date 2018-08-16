# ReskitBuildScripts

## Introduction

This repo holds the build scripts for my reskit.org domain. 
I use this domain and the VMs in my books, speaking, and training. 
These scripts are not a fully baked automation solution, but a more workmanlike set.
In my advanced class, I get the students to run these scripts - one at a time - as a learning exercise.

These scripts work for me, in my enviornment and on my systems. 
I make no promises other than they should work if you are careful.
I have used variables widely to hold the names of things that DO vary (eg iso files, output folders, etc).
PLEASE review before using.

## General appoach
The scripts create a set of Hyper-V Vms that make up a corporate data centre.
These VMs are based on a differencing disk for all servers.
At present Reskit.Org client systems are manually installed (to do!)
That includes DCs, a CA hierarchy, DNS/DHCP services, and more.
Depending on the version of Windows Server in use (and what license keys you may or may not have) there is some manual intervention needed.

## Steps

1. Setup Environment


On the VM host, create a d:\V6 as the location for the VMs.
Then copy the two unattended XML files \unattended XML\Unattend.xml and \unattended XML\UnAttend.DJ.xml into d:\v6 on the VM host.

2. Create a reference disk

Use New-ReferenceVHDX.ps1 - ensure paths are correct to the ISO and output vhdx.
Do not proceed until the reference disk is created

3. Create DC1 VM

Use New-RKVM. This script has a function that creates a VM and some calls to that function.
First, comment out all the calls to ensure the function compiles.
Then uncomment the relevant calls and create VMs. 
Create DC1 VM first, and get if fully configured.
Then come back and create more.


4. Configure DC1 (and your host!)
Run Configure-DC1-1 to create DC1 system as a DC in the Reskit.Org domain.
This script also sets up the host to do CredSSP into DC1.

4. Create SRV1, SRV25

6. Configure SRV1


7. Configure SRV2

8. Create other VMs as needed - with configuration being done by recipes.
