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

1. Create a reference disk
Use New-ReferenceVHDX.ps1

2. Create DC1 VM

3. Configure DC1 (and your host!)

4. Create SRV1, SRV2

5. Configure SRV1

6. Configure SRV2

7. Create other VMs as needed - with configuration being done by recipes.
