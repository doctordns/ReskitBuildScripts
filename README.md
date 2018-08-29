# ReskitBuildScripts

## Introduction

This repo holds the build scripts for the Reskit.org domain.
I use this domain and the VMs in my books, speaking, and training.
These scripts are not a fully baked automation solution but allows you to create just the VMs you need
In my advanced class, I also get the students to run these scripts during class as a learning exercise.

These scripts work for me, in my environment and on my systems.
I make no promises other than they should work if you are careful.
I have used variables widely to hold the names of things that DO vary (eg iso files, output folders, etc).
PLEASE review before using.

If you find issues, please file an issue on GitHub.

## General Approach

The scripts create a set of Hyper-V Vms that might make up a corporate data centre.
These VMs are based on a difference disk for all servers.
At present Reskit.Org client systems are manually installed
That includes DCs, DNS/DHCP services, and a variety of other servers.
The scripts first create the differencing disk, and then create a Domain Controller and a few core servers.
Other servers are created but are configure solely by a recipe or set of recipes.

## Building the Reskit.Org VM Farm

This is a pretty straightforward process.
Please take a moment to read the rest of this document before diving in to create VMs!

### Setup Your Working Environment

Create your VM host. Ypu want either Server 2019 or WIndows 10 Enterprise/Pro.
Ensure the host has Hyper-V feature added.
On your VM host, create a **D:\V6** as the location for the VMs.
Then copy the two unattended XML files **\unattended XML\Unattend.xml* and **\unattended XML\UnAttend.DJ.xml** into **D:\v6** on the VM host.
Finally, you need to obtain the ISO image for Server 2019 (left as an exercise for the reader)

### Create a Reference Disk

The first step is for you to use **New-ReferenceVHDX.ps1** to create a reference VHDx.
As mentioned, the VMs in Reskit.Org farm are based on using a single reference VHDx to save disk space.
This script requires the ISO image of WIndows Server 2019 DataCentre and outputs the reference VHDX that is used in all the following recipes.

Before running this script, ensure paths are correct to the ISO and output vhdx.
If this is the first time you've run these scripts, you may want to to test the reference disk more completely.
To do that, copy the file and create a VM using that copy.
If the installation of Windows Server 2019 on that copied VHDx is successful, you should be good to move forward (and you can delete the copied file and the test virtual machine)

### Create DC1 VM

Use **New-RKVM.ps1** to create the first VM.
This script contains, at the top, a function that creates a VM which is then followed by calls to that function.
The script you download from GitHub _should_ have all the calls to the function commented out.
Since this repo is a work in progress, you may find that some calls are NOT commented out.
So before running the script for the first time make sure all calls are commented out.
This enables the function to compile and results in no VMs being created.
Once this works, you can un-comment the call to create DC1 and run the script again to create DC1 VM.

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
