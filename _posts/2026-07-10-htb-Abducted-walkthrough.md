---
layout: single
title: "HackTheBox Abducted Walkthrough: From Anonymous Samba Printer RCE to Root"
date: 2026-07-10
author_profile: true
comments: true
share: true
categories: HTB-Machine
tags: [CVE-2026-4480]
header:
  overlay_image: /assets/images/abducted/cover.png
  overlay_filter: 0.3  # optional, darkens the image for readability
  caption: "HackTheBox Abducted Walkthrough: From Anonymous Samba Printer RCE to Root"
excerpt: "HackTheBox Abducted Walkthrough: From Anonymous Samba Printer RCE to Root"
feature_row:
  - image_path: /assets/images/abducted/cover.png
    alt: "HackTheBox Abducted Walkthrough: From Anonymous Samba Printer RCE to Root"
    title: "HackTheBox Abducted Walkthrough: From Anonymous Samba Printer RCE to Root"
    excerpt: "A practical guide to solving the HTB Abducted machine."
    url: "#"
    btn_label: "Read More"
    btn_class: "btn--primary"
toc: true
toc_sticky: true
---
# Abducted


# Summary

Abducted demonstrates a full compromise through chained Samba misconfigurations. Enumeration showed only SSH and SMB were exposed, with protected disk shares but an anonymous-accessible printer share, `HP-Reception`. Since guest users could submit print jobs, the attack path led to Samba printer vulnerabilities, matching **CVE-2026-4480**, which provided an initial shell as `nobody`.

Post-exploitation revealed Samba configurations that allowed pivoting from `scott` to `marcus` using `force user`, `wide links`, and SSH key placement through the `transfer` share. Finally, `marcus` belonged to the `operators` group, which could write to the `smbd` systemd drop-in directory and reload/restart the service via polkit. This allowed root command execution through `ExecStartPre`, resulting in a SUID bash binary and full root access.

# Information Gathering

To begin the assessment, I performed a full TCP port scan using Nmap. Instead of scanning only the default top ports, I used `-p-` to check all 65,535 TCP ports. 

```bash
ports=$(nmap -p- --min-rate=1000 -T4 $IP | grep ^[0-9] | cut -d '/' -f 1 | tr '\n' ',' | sed s/,$//) ; nmap -p$ports -sC -sV -vv -oN nmap/service_scan $IP

PORT    STATE SERVICE     REASON         VERSION                                                                                                           
22/tcp  open  ssh         syn-ack ttl 63 OpenSSH 9.6p1 Ubuntu 3ubuntu13.16 (Ubuntu Linux; protocol 2.0)                                                    
| ssh-hostkey:                                                                                                                                             
|   256 0c:4b:d2:76:ab:10:06:92:05:dc:f7:55:94:7f:18:df (ECDSA)                                                                                            
| ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBN9Ju3bTZsFozwXY1B2KIlEY4BA+RcNM57w4C5EjOw1QegUUyCJoO4TVOKfzy/9kd3WrPEj/FYKT2agja
9/PM44=                                                                                                                                                    
|   256 2d:6d:4a:4c:ee:2e:11:b6:c8:90:e6:83:e9:df:38:b0 (ED25519)                                                                                          
|_ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH9qI0OvMyp03dAGXR0UPdxw7hjSwMR773Yb9Sne+7vD                                                                         
139/tcp open  netbios-ssn syn-ack ttl 63 Samba smbd 4                                                                                                      
445/tcp open  netbios-ssn syn-ack ttl 63 Samba smbd 4                                                                                                      
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel                                                                                                    
                                                                                                                                                           
Host script results:                                                                                                                                       
|_clock-skew: 5m11s                                                                                                                                        
| nbstat: NetBIOS name: ABDUCTED, NetBIOS user: <unknown>, NetBIOS MAC: <unknown> (unknown)
| Names:
|   ABDUCTED<00>         Flags: <unique><active>
|   ABDUCTED<03>         Flags: <unique><active>
|   ABDUCTED<20>         Flags: <unique><active>
|   WORKGROUP<00>        Flags: <group><active>
|   WORKGROUP<1e>        Flags: <group><active>
| Statistics:
|   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
|   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
|_  00 00 00 00 00 00 00 00 00 00 00 00 00 00
| smb2-time: 
|   date: 2026-06-22T08:35:26
|_  start_date: N/A
| p2p-conficker: 
|   Checking for Conficker.C or higher...
|   Check 1 (port 43781/tcp): CLEAN (Couldn't connect)
|   Check 2 (port 39974/tcp): CLEAN (Couldn't connect)
|   Check 3 (port 10554/udp): CLEAN (Failed to receive data)
|   Check 4 (port 36732/udp): CLEAN (Failed to receive data)
|_  0/4 checks are positive: Host is CLEAN or ports are blocked
| smb2-security-mode: 
|   3.1.1: 
|_    Message signing enabled but not required

```

The scan identified only three open ports. There was no web or FTP service running on the target. SSH was open, but it required valid credentials, so it was not useful for initial access. This left SMB/Samba on ports `139` and `445` as the main attack surface.

Nmap only identified the service as `Samba smbd 4`, which was too generic to directly map to a specific vulnerability. Therefore, instead of searching for a random Samba exploit, I continued enumerating what SMB functionality was actually exposed.

## **SMB Enumeration**

I first checked whether anonymous users could list SMB shares.

The server allowed anonymous share listing and returned the following shares:

![image.png](/assets/images/abducted/image.png)

This showed two disk shares and one printer share. Since anonymous listing was allowed, I tested whether the disk shares could also be accessed without credentials.

![image.png](/assets/images/abducted/image%201.png)

Both shares returned:

> tree connect failed: NT_STATUS_ACCESS_DENIED
> 

This confirmed that anonymous users could see the `projects` and `transfer` shares but could not access their contents. Therefore, these shares were not immediately useful for initial access.

The remaining interesting share was the printer share. I connected to it anonymously and tried submitting a small test file.

![image.png](/assets/images/abducted/image%202.png)

The server accepted the file. However, running `ls` returned: `NT_STATUS_NO_SUCH_FILE listing \*` This behavior confirmed that `HP-Reception` was not a normal writable file share. Instead, the uploaded file was accepted as a **print job**. This was an important finding because it proved that anonymous users could interact with the Samba printing service.

## RPC Enumeration

Next, I used `rpcclient` to check whether anonymous RPC enumeration was also allowed. **The server returned:**

![image.png](/assets/images/abducted/image%203.png)

The `os version: 6.1` value was not treated as the real operating system version because Samba can report Windows-like values for compatibility. The useful information was the server comment:

> Hartley Group Document Services
> 

This matched the exposed SMB shares and supported the idea that the service was related to document handling and printing.

I also enumerated users through RPC. This revealed one local user: `scott` 

![image.png](/assets/images/abducted/image%204.png)

This gave me a valid username, but no password. Since SSH and the disk shares still required credentials, the `scott` user was useful information for later but did not provide immediate access.

# **Identifying the Vulnerability**

At this stage, the enumeration result was very specific:

> 
> 
> 1. Samba was exposed.
> 2. Disk shares denied anonymous access.
> 3. RPC leaked a username but no password.
> 4. The printer share accepted guest print jobs.

The only unauthenticated action I could perform was submitting a print job to the Samba printer share. Because of that, I focused my research on Samba printing vulnerabilities instead of general Samba vulnerabilities. I searched Google using behavior-based keywords such as samba print job vulnerability 

![image.png](/assets/images/abducted/image%205.png)

This search led to **CVE-2026-4480**, a Samba printing subsystem vulnerability. The issue occurs when Samba passes a client-controlled print job description to the configured `print command` through the `%J` substitution, which can lead to command injection if the print command is vulnerable.

This matched the target behavior because the machine allowed anonymous users to submit print jobs to `HP-Reception`. The exact Samba build could not be confirmed from Nmap, but the exposed functionality matched the vulnerable attack surface.

# Initial Foothold

After identifying the likely vulnerability, I searched for a public proof of concept.

![image.png](/assets/images/abducted/image%206.png)

A public PoC was available, so I cloned it and executed it against the `HP-Reception` printer share. The exploit abuses the Samba `spoolss` printing interface, where the print job name reaches the vulnerable `%J` handling path. HTB’s technical writeup also explains that the vulnerable path is reached through `spoolss` rather than normal `smbclient` printing.

On my attacker machine, I started a Netcat listener. Then I executed the exploit and it returned a reverse shell as the `nobody` user inside `/var/spool/samba`, which makes sense because the command execution came through the Samba printing service.

![image.png](/assets/images/abducted/image%207.png)

At this point, initial access was achieved through the unauthenticated Samba printer share.

# Privilege Escalation

## `nobody` to `scott`

After getting the reverse shell through the Samba printer exploit, the shell landed as the low-privileged `nobody` user. Since this user had very limited access, I started checking common application and backup locations. Inside `/opt`, I found an interesting directory named `offsite-backup`.

![image.png](/assets/images/abducted/image%208.png)

Inside the directory, there were two files rclone.conf & [sync.sh](http://sync.sh/). The `rclone.conf` file was interesting because Rclone configuration files often contain remote backup credentials.

![image.png](/assets/images/abducted/image%209.png)

The password value was not plaintext, but Rclone stores passwords in a reversible obfuscated format. Since the `rclone` binary was available on the machine, I used `rclone reveal` to decode it.

Earlier RPC enumeration had already revealed a valid local user named `scott`, so I tested this password against SSH.

![image.png](/assets/images/abducted/image%2010.png)

This confirmed credential reuse between the backup configuration and the local SSH account. At this point, I moved from the restricted `nobody` shell to a proper user shell as `scott`.

## `scott` to `marcus`

After getting access as `scott`, I started checking the Samba configuration because the machine’s main attack surface was SMB.

![image.png](/assets/images/abducted/image%2011.png)

Before focusing on the transfer share, this configuration also confirmed the earlier CVE-2026-4480 assumption. The HP-Reception printer share used print command = /usr/local/bin/printaudit %J %s, where %J is the client-controlled print job name. This matched the vulnerable condition described in CVE-2026-4480 and confirmed why the printer exploit worked.

This configuration means scott is allowed to authenticate to the transfer share, but any file operation through this share is forced to run as marcus.

I also checked the global Samba settings:

![image.png](/assets/images/abducted/image%2012.png)

This made the share more dangerous. `wide links = yes` allows Samba to follow symbolic links outside the shared directory, and `allow insecure wide links = yes` permits this behavior even when it points outside `/srv/transfer`.

So the abuse path became clear:

> 
> 
> 1. scott can write to /srv/transfer.
> 2. Samba follows symlinks outside /srv/transfer.
> 3. File operations through the share run as marcus.
> 4. Therefore, scott can write into marcus's home directory through a symlink.

I generated an SSH key and created a symlink from the transfer share to Marcus’s home directory.

![image.png](/assets/images/abducted/image%2013.png)

![image.png](/assets/images/abducted/image%2014.png)

Then I connected to the `transfer` share as `scott` and wrote my public key into Marcus’s SSH authorized keys file through the symlink.

![image.png](/assets/images/abducted/image%2015.png)

The file upload went through the SMB share, so it was created as `marcus` because of:

> force user = marcus
> 

The authorized_keys file was written as marcus, allowing SSH login as that user.

![image.png](/assets/images/abducted/image%2016.png)

At this point, privilege escalation from `scott` to `marcus` was successful.

## `marcus` to `root`

After logging in as `marcus`, I noticed that the user was a member of the `operators` group.

![image.png](/assets/images/abducted/image%2017.png)

Since custom groups often indicate delegated administrative access, I searched for files and directories writable by the `operators` group.

![image.png](/assets/images/abducted/image%2018.png)

One result stood out:

![image.png](/assets/images/abducted/image%2019.png)

This directory is a systemd drop-in directory for the `smbd` service. Any `.conf` file placed here is merged into the `smbd.service` configuration when systemd reloads the unit.

The permission is important:

> 
> 
> 
> root:operators owns the directory.
> operators has write permission.
> marcus is in operators.
> 

So `marcus` can create a systemd override file for `smbd`.

However, writing the override file alone is not enough. Systemd must reload the unit configuration, and the `smbd` service must restart for the new directives to execute.

I checked what polkit actions the current user could perform without a password.

![image.png](/assets/images/abducted/image%2020.png)

The important allowed action was:

> ALLOWED: org.freedesktop.systemd1.reload-daemon
> 

This meant `marcus` could reload the systemd manager. The restart permission for `smbd` was also delegated through a unit-specific polkit rule, so restarting `smbd` did not require the root password.

At this point, the attack chain became clear.

> 
> 
> 
> marcus can write a drop-in file for smbd.service.
> marcus can reload systemd.
> marcus can restart smbd.
> smbd runs as root.
> ExecStartPre commands in the drop-in run as root.
> 

I created a systemd override that copies `/bin/bash` to `/tmp/.rb` and sets the SUID bit.

![image.png](/assets/images/abducted/image%2021.png)

Then I reloaded systemd and restarted `smbd` to trigger the `ExecStartPre` commands. After the restart, the SUID bash binary was created.

![image.png](/assets/images/abducted/image%2022.png)

Finally, I executed it with `-p` to preserve the effective root privileges.

![image.png](/assets/images/abducted/image%2023.png)

The effective UID was now `0`, which confirmed root-level execution.