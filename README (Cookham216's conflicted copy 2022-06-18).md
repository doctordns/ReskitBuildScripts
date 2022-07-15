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

These scripts are a work in progress.  
I am constantly updating them - so beware!

If you find issues, please file an issue on GitHub.

## REPO Contents

* `New-ReferenceVHDX.ps1` - creates a reference disk you use later
* `New-RKVM.ps1` - copies the reference disk and creates a new VM based on the copied disk
* `Update-RKVM.ps1` - after installation, adds a 2nd NIC bound to external and improves hardware.
* **Unattended XML** - this folder contains two XML files. One for creating a work group host the other for a domain joined server.
* **Classroom scripts** - scripts for use in configuring VMs for the classroom.
* ReskitNetwork.MD - details of the Reskit network.
* Readme.md - this document which sets out how to build the Reskit forest

## Using These Scripts

The scripts create a set of Hyper-V Vms that might make up a corporate data centre.
The VMs are used as the basis for the scripts in my PowerShell books and my training classes.
The VMs includes domain controllers, DNS/DHCP servers, plus a whole lot more.
The scripts create the base VMS and configure them.

For classroom use, you create VMs then use the `classroom scripts` folder to configure the VMs.
For book use, you create VMs as you need them.

As part of your setup - create a new folder to hold the VMs.
By Default this folder is D:\V9, but that can be reconfigured.
Copy the two unattended XML files from the **Unattended XML** folder into your folder.

Next obtain a Server 2022 ISO image.
You can use an evaluation version or a fully licensed version.
As written these scripts do not add a license key - but you can update the XML to do so.

Once you have your host running Hyper-V, you create a reference VHDX, using ```New-ReferenceDisk```.
This script creates a VHDX and uses DISM to copy the installation media for Windows Server 20XX onto the VHDX.
Once created, this VHDX is as fully bootable VM Hard drive. 

To create individual VMs, you use ```New-RKVM``` to create the specific VM.

Please note that this script contains a function (at the top of the file) and several calls to the function below.
BE CAREFUL!

The function in this second script copies your previously created reference VHDX.
Then the function mounts the copied VHDX, and copies a XML setup file to the root of the drive.onto the copied VHDX
The function modifies the XML to customise it in terms of host name, IP configuraion, etc. 
Finally the function creates and starts a new VM using this this new VHDX. 
After Hyper-V starts the VM, the Windows setup runs and you have a VM created.

If you are in my PowerShell master classes, you build the VMs then configure them  using the Configure-* scripts are used.
If you are reading my book, the scripts in the book itself are used to configure the VMs, eg creating a DC, creating a cluster, etc.

### Building the Reskit.Org VM Farm

This is a pretty straightforward process based on the scrips in this repo.
But let's look at some more details.
Please take a moment to read the rest of this document before diving in to create VMs!

### Setup Your Working Environment

You start by creating your VM host.
You want either Server 2022 or Windows 10/11 Enterprise/Pro as your physical host
To run the full set of VMs requires a fair bit of RAM and disk.
For RAM, you need 32GB.
As an alternative, you can reduce the virtual memory for each vm to say 1gb and run most of the VMs at the same time.
In that case, startup will be slow (and noisy if you have spinning disks).
But once the VMs are up and running, performance should be OK.

As for disks, each VM uses up at least 10GB. Some VMs use more - DC1 takes up over 25GB for example.
And if you use snapshots prior to performing some recipes, you may use more.
To complete the full set of VMs in the latest PowerShell book, you will need around 1TB of disk space

After picking our host, ensure the host has Hyper-V feature added and that you have virtualization and SLAT enabled in the BIOS.
Of course, you should have PowerShell 7 and VS Code installed too.
You may be able to use other hypervisor products to create the VMs but I do not support this.

On your VM host, create a **D:\V9** as the location for the VMs.
You can change this folder name and drive - but if you do so, update the variables used to hold this folder name in the `New-ReferenceVHDX.ps1` and `New-RKVM.ps1` scripts. 
This folder stores one folder for each VM you create using my build scripts.

Next copy the two unattended XML files (**\unattended XML\Unattend.xml*** and **\unattended XML\UnAttend.DJ.xml**) into **D:\v9** on your VM host.
The setup scripts use these XML files to build a Windows Server somewhat pre-configured (eg with credentials, machine name, IP address, etc all pre-assigned).
All the values (domain name, administrator password) are easy to change.
And you can also add a section with the OS installation key to speed the creation of a new VM.
But be careful!

Before creating your first VM, you you need to obtain the ISO image for Windows Server(left as an exercise for the reader).
This can be an eval version, MSDN/VS, or any other retail/VL edition

### Create a Reference Disk

The first step is for you to use **New-ReferenceVHDX.ps1** to create a reference VHDx.
This script requires the ISO image of Windows Server 20XX DataCentre and outputs the reference VHDX that is used later.
Some ISO images you get contain multiple configurations (Standard, Data Center) depending on the source.
The created VHDX is essentially a copy of Windows server copied from the ISO image.
This script uses the Data Center edition with the full desktop - but you can change this default.

Before running this script, ensure paths are correct and point the ISO image and where you want to store the reference disk.

### Create Initial VM

Depending on which book you are reading, the VM in the first chapter will vary:

. For my 1st two Packt books, and my Wiley Book, create DC1 first.
. For my Packt PowerShell 7 Books, create SRV1 first

Use **New-RKVM.ps1** to create the first VM.
You can use either the ISE or more likely VS code on the VM host to run this script.
Note that this is a generic script that you use to create all the Reskit VMs.
The top of the script is the function that does all the work, with the bottom a number of calls fo the function.

Take a look at this script before running it the first time.
At the top of the script you can see a function that creates a VM.
This function takes a number of parameters that dictate vam details.

Then you see a number of invocations of that function which individually create the relevant domain joined or non-domain joined servers.
I have tried to setup all the needed default values for each VM.
Just comment out the calls you do NOT want to make, and un-comment the call yoiu DO want to make then run the whole file.

If you you download this script from GitHub you _should_ see all the calls to the function commented out.
Since this repo is a work in progress, you may find that some calls are NOT commented out.
So before running the script for the first time make sure **all** calls o NEW-VM are commented out.
If you run it this way, you can see that the function compiles OK, even with no VMs actually created.
Once this works, you can un-comment the call to create DC1 and run the script again to create DC1 VM.

Each VM you create spins up and goes through the installation process.
At the end of the process, you have a working VM.

### Configure Your VM

After the previous step, you need to wait a few minutes for Windows to install itself in the VM.
This is likely to take 4-5 minutes depending on your hardware specification of your VM host.
You also need to enter a license code manually at the end of Windows Setup.
You can alter the unattended XML file to contain a valid license key, which would speed up the creation of the new VM.

There are likely to be numerous ISO images you can download from Microsoft for Windows Server.
Depending on the specific version of Windows Server you use, you have different license keys.
Enter your key when directed. 
For evaluation, you can direct setup to ignore and just move on (but the VM times out after 180 days)
Unlicensed VMs do time out, but you can always rebuild.

As an alternative to entering a key for each VM, you can edit the unattend.xml files to contain the product key if you choose.

Once the first VM is up, it runs as an un-configured server in the Reskit work group.
Login and ensure the VM is created properly and check the IP address for the NICs in the VM.

For my Packt 7 book, you use the workgroup server for the first few chapters and then create your first DC.
From that point you create more domain joined VMs.


### Create Further servers

Once you have the DC created, you can create the other servers.
Use the **New-RKVM.ps1** script to create each server.
Be careful to specify the correct unattended XML file when you create the VM.

### Some More Tips

You should ensure that the **Internal** Hyper-V network s labeled as private.
You may need to use Get-NetConnectionProfile and Set-NetConnectionProfile to do this.

On the host, adding the **Internal** virtual switch creates a NIC for this switch. 
Configure this NIC to have a static IP address of **10.10.10.252**.

TO help interoperate with the Reskit servers, add all the servers from the hosts.txt file to the hosts file on your hyper-V host.

## NOTE

The scripts in the repo have been used extensively in author testing and writing.
The scripts were designed to be used in a classroom, for use in examining PowerShell code, or as part of a book project.
But be clear: **This is a work in permanent progress.**
If you have problems, file and issue in this repo and I will help.

Enjoy!
