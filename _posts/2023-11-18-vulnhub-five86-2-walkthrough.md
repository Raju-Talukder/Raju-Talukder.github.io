---
layout: post
cover:  assets/images/five86-2/cover.png
title: Vulnhub Five86 2 Walkthrough 
date: 2023-11-11
categories: Five86-Series
author: raju
featured: false
---


This is the last machine so far from this five86 series. This series proved to be interesting, offering numerous learning opportunities. Among the publicly available ports, FTP and the web server were present. However, the FTP was well-configured, with nothing initially available. The web application, when scanned using WPScanner, revealed some users and two valid user credential combinations. Upon obtaining the user credentials, logging into the web console and exploiting a simple file upload functionality provided the initial foothold. Password re-use granted the first user privilege. Achieving the second user privilege required executing an ARP poisoning attack. Finally, the third and last step to gain root access involved exploiting a misconfiguration in file super permissions.

# Information Gathering

First, I want to start with Nmap to identify the open ports and their associated services. If possible, Nmap will also provide information about the service versions and the operating system. This is a good starting point when working with any assets.

```bash
ports=$(nmap -p- --min-rate=1000 -T4 $IP | grep ^[0-9] | cut -d '/' -f 1 | tr '\n' ',' | sed s/,$//) ; nmap -p$ports -sC -sV -oN nmap_service_scan $IP

PORT   STATE SERVICE VERSION
21/tcp open  ftp     ProFTPD 1.3.5e
80/tcp open  http    Apache httpd 2.4.41 ((Ubuntu))
|_http-title: Five86-2 &#8211; Just another WordPress site
|_http-server-header: Apache/2.4.41 (Ubuntu)
|_http-generator: WordPress 5.1.4
Service Info: OS: Unix
```

According to the Nmap results, there are only two open ports on the system. Port 21 hosts an FTP service running ProFTPD version 1.3.5e, while port 80 serves a WordPress web application with WordPress version 5.1.4. The banners from both ports indicate that the operating system is Ubuntu.

## Manual Inspection

First i would like to check the FTP servers with default credentials.

![](/assets/images/five86-2/1.png)

The anonymous login did not worked. So, let’s move forward with the web application.

![](/assets/images/five86-2/2.png)

When I visited the IP address, I noticed issues with the CSS not rendering properly. Additionally, hovering over a link displayed the domain name as 'five86-2'. To address this, I plan to add the corresponding entry to the hosts file.

```bash
echo "192.168.197.136 five86-2" | sudo tee -a /etc/hosts
```

After adding the domain name to the hosts file, accessing the web application resulted in proper loading. However, I observed two additional links that, upon clicking, initiated the download of XML files.

![](/assets/images/five86-2/3.png)

The downloaded files turned out to be XML files with templates, which didn't pique my interest. Consequently, I opted to skip these files and continue exploring.

![](/assets/images/five86-2/4.png)

Given that it's a WordPress site, I decided to leverage WPScanner, which offers a password attack feature. To enhance the effectiveness of the attack, I attempted to generate a wordlist tailored to the web application. For this task, I employed the `cewl` tool.

```bash
cewl -d 3 -w password.txt http://five86-2
```

The generated word list isn't extensive, and I'm uncertain if it will yield any valid credentials. In case it doesn't produce any results, I plan to run the `rockyou` word list for a more comprehensive attempt.

```bash
wpscan --enumerate --passwords password.txt --url five86-2

[+] URL: http://five86-2/ [192.168.197.136]
[+] Started: Fri Nov 10 22:11:22 2023

Interesting Finding(s):

[+] WordPress version 5.1.4 identified (Insecure, released on 2019-12-12).

[+] WordPress theme in use: twentynineteen

[+] Enumerating Vulnerable Plugins (via Passive Methods)

[i] No plugins Found.

[i] No themes Found.

[i] No Timthumbs Found.

[i] No Config Backups Found.

[i] No DB Exports Found.

[i] No Medias Found.

[i] User(s) Identified:

[+] admin
[+] barney
[+] gillian
[+] peter
[+] stephen

[i] No Valid Passwords Found.
```

As anticipated, WPScanner provided valid usernames, but unfortunately, no corresponding passwords. To address this, I intend to rerun WPScanner, this time utilizing the `rockyou` file.

```bash
wpscan --url five86-2 --passwords /usr/share/wordlists/rockyou.txt
---snip---
[+] Valid Combinations Found:
 | Username: barney, Password: spooky1
 | Username: stephen, Password: apollo1
```

This time, WPScanner yielded two valid credential combinations. I proceeded to attempt the login with the first set, using 'barney' as the username, and it successfully granted access.

![](/assets/images/five86-2/5.png)

After a few examination i have discovered that there is a functionality of adding post where i can upload files as well. however we need to submit a zip file inside the zip there should be one html file.

![](/assets/images/five86-2/6.png)

Following the specified criteria, I generated a PHP file containing malicious code, along with an empty HTML file, and compiled them into a zip archive.

![](/assets/images/five86-2/7.png)

I uploaded the file using the default options, selecting 'iFrame,' and it provided me with the file path of the HTML file.

![](/assets/images/five86-2/8.png)

Since my HTML file is located here, I expect that my PHP file should also be present in the same location.

**Creds**

<aside>
💡 barney:spooky1
stephen:apollo1                                                                                                         paul:esomepasswford

</aside>

# Initial Foothold

With knowledge of the PHP file path, I initiated a netcat listener to capture the reverse shell and visited the corresponding URL.

```bash
http://five86-2//wp-content/uploads/articulate_uploads/shell3/shell.php
```

![](/assets/images/five86-2/9.png)

And i got the reverse shell as www-data.

# Post Enumeration & Privilege Escalation

Since we obtained two valid user credentials from WPScanner, we can now proceed with a password re-use attack.

![](/assets/images/five86-2/10.png)

I attempted to use Barney's credentials, but they were unsuccessful. However, Stephen's credentials worked, granting me Stephen's privileges. Upon checking sudo permissions for these users, it appears that the user is not permitted to run sudo. To gather more information, I examined the groups Stephen belongs to, and an interesting detail emerged: the 'pcap' group.

![](/assets/images/five86-2/11.png)

> What is this 1009(pcap) ?                                                                                             Regarding `1009(pcap)`, it indicates that the user is a member of a group with the group ID (GID) of 1009, and the group name is "pcap." The "pcap" group is often associated with network packet capture permissions, and members of this group may have elevated privileges for capturing network traffic.
> 

So i tried to find out all the interesting files capabilities and found the g `tcpdump` file.

```bash
getcap -r / 2>/dev/null
```

![](/assets/images/five86-2/12.png)

I've identified all the running interfaces and aim to conduct an ARP poisoning attack to intercept data transmitted over any non-secure protocols. From the earlier Nmap results, I observed that the FTP port is open, and FTP is a non-secure protocol. There's a possibility that if someone attempts to log in to the FTP protocol, we could capture their credentials in plain text.

```bash
tcpdump -D
```

![](/assets/images/five86-2/13.png)

I want to first dump the first interface.

```bash
tcpdump -i br-eca3858d86bf
```

![](/assets/images/five86-2/14.png)

I discovered the credentials for the user 'paul' during the ARP poisoning attack. In this controlled scenario, there might be a script performing these login requests. However, in a real environment, we would need to wait for a genuine user to initiate such actions. With the 'paul' user credentials in hand, I attempted to switch users, and the process succeeded.

![](/assets/images/five86-2/15.png)

After obtaining the shell as 'paul,' I checked the sudo privileges and discovered that he can execute the service binary with sudo without entering a password.

![](/assets/images/five86-2/16.png)

While the primary purpose of the service binary is to manage services, including starting, stopping, restarting, and checking their status, I exploited it to launch /bin/bash. This action granted me the 'peter' privilege.

![](/assets/images/five86-2/17.png)

Upon inspecting Peter's sudo permissions, I discovered that he can execute the passwd command as root without requiring a password. Exploiting this, I changed the root user's password and successfully logged in as root with the updated credentials.

![](/assets/images/five86-2/18.png)