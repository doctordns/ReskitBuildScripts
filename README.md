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

If you find issues, please file an issue on GitHub.

## General Approach

The scripts create a set of Hyper-V Vms that might make up a corporate data centre.
These VMs are based on a difference disk for all servers.
That includes DCs, DNS/DHCP services, and a variety of other servers.
You first create a base differencing disk, and then create a Domain Controller and go from there
Other servers are created but are configure solely by a recipe or set of recipes.
At present You manually install any Reskit.Org client system and join it to the domain.

There are two broad ways to use these scripts. 
First, you can build the differencing disk, create DC1 VM. You can then make that a DC in the Reskit domain, and create the other VMs as and when needed.  There are scripts to build the DC, with DHCP/DNS, a SQL server and a couple of general puprpose servers hosting other roles. 
This is good for the classroom where we want the DC up and running, etc. You can run just those scripts you need to in order to build from scratch a full domain as the basis for teaching or lecturing.
Second, use the scripts here to create the VMs, but use the scripts in my PowerShell books to configure your many VMs. I hope the scripts enable you to build your basic VMs and go from there.
Of course, you can do both!

## Building the Reskit.Org VM Farm

This is a pretty straightforward process.
Please take a moment to read the rest of this document before diving in to create VMs!
This process is based on using Hyper-V differencing disks to save disk space on the VM host.

### Setup Your Working Environment

Create your VM host. Ypu want either Server 2019 or WIndows 10 Enterprise/Pro.
Ensure the host has Hyper-V feature added.
On your VM host, create a **D:\V7** as the location for the VMs.
You can change this folder - but you need to upate the variables used to hold this folder name. 
Then copy the two unattended XML files **\unattended XML\Unattend.xml* and **\unattended XML\UnAttend.DJ.xml** into **D:\v7** on the VM host.
These XML files are used to build a Wondows Server somewhat pre-configured (eg with credentials, machine name, IP address, etc all pre-assigned).
All the values (domain name, administrator password) are easy to change. 
Finally, you need to obtain the ISO image for Windows Server 2019 (left as an exercise for the reader)

### Create a Reference Disk

The first step is for you to use **New-ReferenceVHDX.ps1** to create a reference VHDx.
As mentioned, the VMs in Reskit.Org farm are based on using a single reference VHDx to save disk space.
This script requires the ISO image of Windows Server 2019 DataCentre and outputs the reference VHDX that is used in all the following recipes.
Some ISO images you get contain multiple configurations (Standard, Data Center) depending on the source.
The created VHDX is essentially a copy of Windows server copied from the ISO image.

Before running this script, ensure paths are correct and point the ISO image and where you want to store the reference disk.
If this is the first time you've run these scripts, you can to to test the reference disk more completely.
To do that, copy the file and create a VM using that copy.
When you start the VM, Windows runs the setup process using the values in the unattended XML file.
If the installation of Windows Server 2019 on that copied VHDx is successful, you should be good to move forward (and you can delete the copied file and the test virtual machine)

### Create DC1 VM

Use **New-RKVM.ps1** to create the first VM.
This is a generic script that you use to create all the Riskit VMs.
At the top of the script you can see a function that creates a VM. 
Then you see a number of invocations of that function which individually create the relevant domain joined or non-domian joined servers.

If you you download this script from GitHub you _should_ see all the calls to the function commented out.
Since this repo is a work in progress, you may find that some calls are NOT commented out.
So before running the script for the first time make sure **all** calls o NEW-VM are commented out.
If you run it this way, you can see that the function compiles OK, even with no VMs actually created.
Once this works, you can un-comment the call to create DC1 and run the script again to create DC1 VM.

Each VM you create spins up and goes through the installation process. 
At the end of the process, 
 

### Configure DC1 (and your host!)

After the previous step, you need to wait a few minutes for WIndows to install itself in the VM.
This is likely to take 10-15 minutes depending on your hardware specification of your VM host.

There are likely to be numerous ISO images you can download from Microsoft for Server 2019.
Depending on the specific version of 2019 you use. you may need to enter a Product key (or to direct setup to ignore and just move on).
This is the case for all the VMs you create.

Once the DC1 VM is up and running as an un-configured server in a work group, login and ensure the VM is created properly.
Check the IP address for the NICs in the VM.

Run **Configure-DC1-1.ps1** to create DC1 as the first DC in the Reskit.Org domain.
This script also sets up the host to do CredSSP into DC1 and setup DC1 for credentials delegation.
Once the DC has been created, the host needs to be rebooted (as a domain controller)
Once the reboot has finished, run **Configure-DC1-2.ps1** to complete the setup of DC1.

### Create SRV1, SRV2

Once you have the DC created, you can create the other servers.
Use the **New-RKVM.ps1** script to create SRV1, SRV2 first.

### Configure SRV1 and SRV2

Use the **Configure-SRV1-1.ps1** scripts to configure SRV1.
Then use the **Configure-SRV2-1.ps1** scripts to configure SRV2

### Create other VMs

For each additional VM, use **New-RKVM.ps1** to create the VM itself.
Those VMs which need addition pre-recipe configuration have scripts that take the basic VM and configure it ready for each chapter.
Most of the additional VMs are probably NOT going to need additional configuration as that work is done by the individual recipes.

## NOTE

The scripts in the repo have been used extensively in author testing and writing.
The scripts were designed to be used in a classroom or for use in examining PowerShell code.
But be clear: **This is a work in progress.**
Enjoy!
