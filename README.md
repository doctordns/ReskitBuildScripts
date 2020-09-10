# ReskitBuildScripts

## Introduction

This repository holds the build scripts for the Reskit.org domain.
I use this domain and the VMs in my books, speaking, and training.
These scripts are not a fully baked automation solution but allows you to create just the VMs you need
In advanced PowerShell class, students run and then dissect these scripts

These scripts work for me, in my environment and on my systems.
I make no promises other than they should work if you are careful.
I have used variables widely to hold the names of things that DO vary (eg iso files, output folders, etc).
PLEASE review before using.

These scripts are a work in progress.  I am constantly updating them - so beware!

If you find issues, please file an issue on GitHub.

## General Approach

The scripts create a set of Hyper-V Vms that might make up a corporate data centre.
The VMs are used as the basis for the scripts in my PowerShell books.
The VMs includes domain controllers, DNS/DHCP servers, plus a whole lot more.
The scripts create the base VMS and configure them.

You first create a master VHDX, using New-ReferenceDisk. This script creates a VM, and uses DISM to copy the installation media for WIndows Server 20XX onto the VHDX.
Then you use New-RKVM to create the specific VM. This script copies the reference VHXX, copies a XML setup file onto the copied VHDX, then creates an starts a VM based on this new VHDX. 
When Hyper-V starts the VM, the WIndowds setup runs and you have a VM of that name, IP address, etc.

If you are in my PowerShell master classes, you build the VMs using the Configure-* scripts are used.
If you are reading my book, the scripts in the book are used to configure the VMs, eg creating a DC, creating a cluster, etc.

## Building the Reskit.Org VM Farm

This is a pretty straightforward process.
Please take a moment to read the rest of this document before diving in to create VMs!
This process is based on using Hyper-V differencing disks to save disk space on the VM host.

### Setup Your Working Environment

Create your VM host. Ypu want either Server 20XX or Windows 10 Enterprise/Pro.
Ensure the host has Hyper-V feature added and that you have virtualization and SLAT enabled in the BIOS
On your VM host, create a **D:\V8** as the location for the VMs.
You can change this folder name - but you would then need to update the variables used to hold this folder name. 

Copy the two unattended XML files **\unattended XML\Unattend.xml* and **\unattended XML\UnAttend.DJ.xml** into **D:\v8** on the VM host.
These XML files are used to build a Windows Server somewhat pre-configured (eg with credentials, machine name, IP address, etc all pre-assigned).
All the values (domain name, administrator password) are easy to change. 
Finally, you need to obtain the ISO image for Windows Server 20XX (left as an exercise for the reader)

### Create a Reference Disk

The first step is for you to use **New-ReferenceVHDX.ps1** to create a reference VHDx.
This script requires the ISO image of Windows Server 20XX DataCentre and outputs the reference VHDX that is used later.
Some ISO images you get contain multiple configurations (Standard, Data Center) depending on the source.
The created VHDX is essentially a copy of Windows server copied from the ISO image.

Before running this script, ensure paths are correct and point the ISO image and where you want to store the reference disk.

### Create Initial VM
Depending on which book you are reading, the VM in the first chapter will vary:

. For my 1st two Packt booka nd my Wiley Book, create DC1 first.
. For my Packt PowerShell 7 Book, create SRV1 first

Use **New-RKVM.ps1** to create the first VM. 
This is a generic script that you use to create all the Reskit VMs.
At the top of the script you can see a function that creates a VM. 
Then you see a number of invocations of that function which individually create the relevant domain joined or non-domian joined servers.

If you you download this script from GitHub you _should_ see all the calls to the function commented out.
Since this repo is a work in progress, you may find that some calls are NOT commented out.
So before running the script for the first time make sure **all** calls o NEW-VM are commented out.
If you run it this way, you can see that the function compiles OK, even with no VMs actually created.
Once this works, you can un-comment the call to create DC1 and run the script again to create DC1 VM.

Each VM you create spins up and goes through the installation process. 
At the end of the process, you have a working VM.
 

### Configure Your Server

After the previous step, you need to wait a few minutes for WIndows to install itself in the VM.
This is likely to take 10-15 minutes depending on your hardware specification of your VM host.

There are likely to be numerous ISO images you can download from Microsoft for Server 2019.
Depending on the specific version of 2019 you use. you may need to enter a Product key (or to direct setup to ignore and just move on).
This is the case for all the VMs you create.
You can edit the unattend.xml files to contain the product key if you choose.

Once the first VM is up, it is running as an un-configured server in the Reskit work group.
Login and ensure the VM is created properly and check the IP address for the NICs in the VM.

### Create Further servers

Once you have the DC created, you can create the other servers.
Use the **New-RKVM.ps1** script to create each server.
Be careful to spcify the correct unattend XML file when you create the VM.

## NOTE

The scripts in the repo have been used extensively in author testing and writing.
The scripts were designed to be used in a classroom or for use in examining PowerShell code.
But be clear: **This is a work in progress.**

Enjoy!
