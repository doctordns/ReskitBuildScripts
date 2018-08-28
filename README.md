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

### Setup Environment

On the VM host, create a d:\V6 as the location for the VMs.
Then copy the two unattended XML files \unattended XML\Unattend.xml and \unattended XML\UnAttend.DJ.xml into d:\v6 on the VM host.

### Create a Reference Disk

Use New-ReferenceVHDX.ps1 - ensure paths are correct to the ISO and output vhdx.
Do not proceed until the reference disk is created

### Create DC1 VM

Use ##New-RKVM##.
This script has a function that creates a VM and some calls to that function.
Comment out all the calls to ensure the function compiles.
Then un-comment the call to create DC1 and run the script again to create DC1 VM.

### Configure DC1 (and your host!)

Depending on the version of 2019 you use you may need to enter a Product key (or to direct setup to must move on).
So once DC1 is created,you can run Configure-DC1-1 to create DC1 system as a DC in the Reskit.Org domain.
This script also sets up the host to do CredSSP into DC1.
THen run Configure-DC1-2 to complete the setup of DC1.

### Create SRV1, SRV2

Once you have the DC created, you can create the other servers.
Use the ##New-RKVM## script to create SRV1, SRV2

### Configure SRV1 and SRV2

Use the #Configure-SRV1-1# scripts to create SRV1
Use the #Configure-SRV2-1# scripts to create SRV2

### Create other VMs

For each additional VM, use #New-RKVM# to create the VM.
For the most part, the additional VMs need no additional configuration as that work is done by the individual recipes.
IF pre-configuration of any VM is needed, additional #Configure-<SERVER>-1 files are created. 
