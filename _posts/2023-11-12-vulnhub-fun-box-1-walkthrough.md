---
layout: single
author_profile: true
title: Vulnhub Funbox 1 Walkthrough 
date: 2023-11-12
comments: true
share: true
categories: Funbox-Series
tags: []
header:
  overlay_image: /assets/images/funbox-1/cover.png
  overlay_filter: 0.3  # optional, darkens the image for readability
  caption: "funbox-1 Vulnhub Walkthrough"
excerpt: "Step-by-step walkthrough of the funbox-1 machine from Vulnhub."
feature_row:
  - image_path: /assets/images/funbox-1/cover.png
    alt: "funbox-1 Cover"
    title: "funbox-1 Walkthrough"
    excerpt: "A practical guide to rooting the funbox-1 Vulnhub machine."
    url: "#"
    btn_label: "Read More"
    btn_class: "btn--primary"
toc: true
toc_sticky: true
---

I personally found this box quite interesting. To gain the initial foothold, I ran WPScan with a password list, using `rockyou.txt` which led to the discovery of two valid user credentials for the web console. One of these users also had SSH access to the box. However, obtaining the shell wasn't enough; there was an additional step to escape the rbash shell. For root access, post-enumeration was crucial, as there were multiple ways to achieve it. Some methods were relatively straightforward, while others required additional research. 

# Information Gathering

First, I want to start with Nmap to identify the open ports and their associated services. If possible, Nmap will also provide information about the service versions and the operating system. This is a good starting point when working with any assets.


```bash
ports=$(nmap -p- --min-rate=1000 -T4 $IP | grep ^[0-9] | cut -d '/' -f 1 | tr '\n' ',' | sed s/,$//) ; nmap -p$ports -sC -sV -oN nmap/service_scan $IP

PORT      STATE SERVICE VERSION
21/tcp    open  ftp     ProFTPD
22/tcp    open  ssh     OpenSSH 8.2p1 Ubuntu 4 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   3072 d2:f6:53:1b:5a:49:7d:74:8d:44:f5:46:e3:93:29:d3 (RSA)
|   256 a6:83:6f:1b:9c:da:b4:41:8c:29:f4:ef:33:4b:20:e0 (ECDSA)
|_  256 a6:5b:80:03:50:19:91:66:b6:c3:98:b8:c4:4f:5c:bd (ED25519)
80/tcp    open  http    Apache httpd 2.4.41 ((Ubuntu))
|_http-title: Did not follow redirect to http://funbox.fritz.box/
| http-robots.txt: 1 disallowed entry 
|_/secret/
|_http-server-header: Apache/2.4.41 (Ubuntu)
33060/tcp open  mysqlx?
| fingerprint-strings: 
|   DNSStatusRequestTCP, LDAPSearchReq, NotesRPC, SSLSessionReq, TLSSessionReq, X11Probe, afp: 
|     Invalid message"
|_    HY000
```

From the Nmap results, we found that four ports are publicly accessible: 21 (FTP), 22 (SSH), 80 (HTTP), and 33060 (MySQL). The SSH and HTTP banners confirm that the operating system is Ubuntu. Additionally, the HTTP service redirects to a domain named 'funbox.fritz.box'. Let's add this to our hosts file first.

```bash
echo "10.10.10.5 funbox.fritz.box" | sudo tee -a /etc/hosts
```

Since we don't have any valid credentials, we couldn't access the SSH or MySQL servers. Therefore, I would like to proceed through the web server.

**Manual Inspection**

![](/assets/images/fun-box-1/1.png)

This is a WordPress application, and I haven't discovered any interactive elements on the web server, such as input boxes or dynamic pagination, except for the WordPress technology itself. Nmap also revealed a 'Disallow' entry in the robots.txt file; let's check it out.

![](/assets/images/fun-box-1/2.png)

The URL only displays a message: 'No secrets here. Try harder!' Since this is a WordPress web application, I plan to run WPScan. However, considering the lack of substantial content during enumeration, generating a word-list based on this application seems unlikely to be fruitful. Instead, I'll opt to run the rockyou.txt file for password brute-force attacks.

```bash
wpscan --url http://funbox.fritz.box/ --enumerate --passwords /usr/share/wordlists/rockyou.txt

[+] URL: http://funbox.fritz.box/ [10.10.10.5]
[+] Started: Sat Nov 11 23:33:29 2023

Interesting Finding(s):

[+] WordPress version 5.4.2 identified (Insecure, released on 2020-06-10).
 
[+] WordPress theme in use: twentyseventeen
 
[i] No plugins Found.

[i] No Timthumbs Found.

[i] No Config Backups Found.

[i] No DB Exports Found.

[i] No Medias Found.

[i] User(s) Identified:

[+] admin
 
[+] joe

[+] Performing password attack on Wp Login against 2 user/s
[SUCCESS] - joe / 12345                                                                                                                                        
[SUCCESS] - admin / iubire                                                                                                                                     
Trying admin / iubire Time: 00:00:09 <                                                                                 > (670 / 28689453)  0.00%  ETA: ??:??:??

[!] Valid Combinations Found:
 | Username: joe, Password: 12345
 | Username: admin, Password: iubire
```

WPScan revealed two valid user credential combinations. I tested both sets of credentials in the web console, and both were successful. Before proceeding with further enumeration on the web console, I plan to verify these credentials for both FTP and SSH access.

![](/assets/images/fun-box-1/3.png)

During the login attempt for FTP, the credentials for the 'joe' user worked successfully. However, the credentials for the 'admin' user did not grant access to the FTP service. Using the 'joe' user account, we discovered an mbox file and downloaded it to our local machine.

![](/assets/images/fun-box-1/4.png)

The mbox file appears to be a mail file, and within it, we discovered some interesting messages. One message mentioned 'funny' as a possible username, and there was also a reference to a backup script, suggesting the existence of a script for backing up certain items. Additionally, there's a warning message for Joe to change his password, with '12345' being recommended. However, we already know Joe's password. Let's attempt to SSH using the credentials for both Joe and Admin.

![](/assets/images/fun-box-1/5.png)

**Creds**

<aside>
💡 joe:12345
admin:iubire

</aside>

# Initial Foothold

The SSH login attempt with the 'admin' user was unsuccessful; however, the credentials for 'joe' were valid, providing me with the initial foothold for this box.

![](/assets/images/fun-box-1/6.png)

# Post Enumeration & Privilege Escalation

After gaining the initial foothold, I discovered that the default shell is rbash, the restricted bash shell for Joe. To progress further, we need to find a way to escape this restricted shell.

![](/assets/images/fun-box-1/7.png)

Numerous techniques exist for escaping a jailed shell, but I opted for the vi editor technique. I executed the following commands, successfully escaping the restricted rbash shell.

```bash
vi
:set shell=/bin/bash
:shell
```

After successfully escaping the rbash, I searched for the backup script and located a file owned by the 'funny' user. Interestingly, the file is readable, writable, and executable for everyone. Although I checked for a cronjob for the 'joe' user and found none, since the file is owned by the 'funny' user, I assume it is executed by the cron job of the 'funny' user.

![](/assets/images/fun-box-1/8.png)

To confirm the existence of the cron job, I transferred pspy to the victim machine and executed it to monitor all input and output operations. After a few moments, I observed a cron job running periodically, executed by both the root and funny users.

![](/assets/images/fun-box-1/9.png)

Since I have write access, I modified the file and added a reverse shell code. I then started a listener on my Kali machine to capture the reverse shell. 

![](/assets/images/fun-box-1/10.png)

After few moment i got the reverse shell as user funny. 

![](/assets/images/fun-box-1/11.png)

Both the `root` and `funny` users have a cronjob to run this file, providing us with a reverse shell if executed. At this point, by removing the cronjob for `funny`, only the `root` user will execute the file, allowing us to gain root access. So, I went ahead and removed the cronjob for `funny`.

![](/assets/images/fun-box-1/12.png)

i Just modify the file once again to change the port and start a new listener for root. Within a few moment i got the reverse connection as root.

![](/assets/images/fun-box-1/13.png)

# Bonus

While enumerating as the 'funny' user, I noticed that this user is also a member of the 'lxd' group. This discovery is quite interesting. After some research, I found a publicly available privilege escalation exploit for this scenario. We could proceed with it.

![](/assets/images/fun-box-1/14.png)

I searched in the searchsploit database and found one result with a Bash script. However, there are some prerequisites for this attack to work—specifically, the `lxd` and `lxc` components need to be installed on the machine.

![](/assets/images/fun-box-1/15.png)

The binaries are available inside the machine.

![](/assets/images/fun-box-1/16.png)

Although both binaries are present inside the box, I've decided not to pursue them since I already have root access. Skipping the 'funny' user's part, with a bit of luck, we might catch the root reverse-shell on the first attempt. There are multiple ways to achieve root on this machine. I thoroughly enjoyed working on this machine.