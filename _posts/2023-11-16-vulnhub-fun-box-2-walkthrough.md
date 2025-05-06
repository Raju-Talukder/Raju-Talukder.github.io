---
layout: single
author_profile: true
title: Vulnhub Funbox 2 Walkthrough 
date: 2023-11-17
categories: Funbox-Series 
tags: []
header:
  overlay_image: /assets/images/funbox-2/cover.png
  overlay_filter: 0.3  # optional, darkens the image for readability
  caption: "funbox-2 Vulnhub Walkthrough"
excerpt: "Step-by-step walkthrough of the funbox-2 machine from Vulnhub."
feature_row:
  - image_path: /assets/images/funbox-2/cover.png
    alt: "funbox-2 Cover"
    title: "funbox-2 Walkthrough"
    excerpt: "A practical guide to rooting the funbox-2 Vulnhub machine."
    url: "#"
    btn_label: "Read More"
    btn_class: "btn--primary"
toc: true
toc_sticky: true
---

This box is very straightforward; there is nothing complex that we need to know about some tools. From the FTP, we obtained numerous zip files encrypted with passwords. We decrypted one user's files password and found 'id_rsa' inside the zip, allowing SSH login into the box. To escalate privileges, we need to find out the users' passwords, which are stored inside a history file.

# Information Gathering

First, I want to start with Nmap to identify the open ports and their associated services. If possible, Nmap will also provide information about the service versions and the operating system. This is a good starting point when working with any assets.

```bash
ports=$(nmap -p- --min-rate=1000 -T4 $IP | grep ^[0-9] | cut -d '/' -f 1 | tr '\n' ',' | sed s/,$//) ; nmap -p$ports -sC -sV -oN nmap/service_scan $IP

PORT   STATE SERVICE VERSION
21/tcp open  ftp     ProFTPD 1.3.5e
| ftp-anon: Anonymous FTP login allowed (FTP code 230)
| -rw-rw-r--   1 ftp      ftp          1477 Jul 25  2020 anna.zip
| -rw-rw-r--   1 ftp      ftp          1477 Jul 25  2020 ariel.zip
| -rw-rw-r--   1 ftp      ftp          1477 Jul 25  2020 bud.zip
| -rw-rw-r--   1 ftp      ftp          1477 Jul 25  2020 cathrine.zip
| -rw-rw-r--   1 ftp      ftp          1477 Jul 25  2020 homer.zip
| -rw-rw-r--   1 ftp      ftp          1477 Jul 25  2020 jessica.zip
| -rw-rw-r--   1 ftp      ftp          1477 Jul 25  2020 john.zip
| -rw-rw-r--   1 ftp      ftp          1477 Jul 25  2020 marge.zip
| -rw-rw-r--   1 ftp      ftp          1477 Jul 25  2020 miriam.zip
| -r--r--r--   1 ftp      ftp          1477 Jul 25  2020 tom.zip
| -rw-r--r--   1 ftp      ftp           170 Jan 10  2018 welcome.msg
|_-rw-rw-r--   1 ftp      ftp          1477 Jul 25  2020 zlatan.zip
22/tcp open  ssh     OpenSSH 7.6p1 Ubuntu 4ubuntu0.3 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   2048 f9:46:7d:fe:0c:4d:a9:7e:2d:77:74:0f:a2:51:72:51 (RSA)
|   256 15:00:46:67:80:9b:40:12:3a:0c:66:07:db:1d:18:47 (ECDSA)
|_  256 75:ba:66:95:bb:0f:16:de:7e:7e:a1:7b:27:3b:b0:58 (ED25519)
80/tcp open  http    Apache httpd 2.4.29 ((Ubuntu))
| http-robots.txt: 1 disallowed entry 
|_/logs/
|_http-server-header: Apache/2.4.29 (Ubuntu)
|_http-title: Apache2 Ubuntu Default Page: It works
Service Info: OSs: Unix, Linux; CPE: cpe:/o:linux:linux_kernel
```

From the Nmap output, we found three open ports. The first one is FTP, where anonymous login is allowed, and Nmap lists numerous zip files. The second and third ports are SSH and HTTP, respectively. The HTTP port displays a default Apache installation page. Let's start enumerating one by one.

## **Manual Inspection**

We already observed the anonymous login for FTP, and there are numerous files present. However, before we deep dive into that, I would like to run some backend reconnaissance. So, I will start from port 80 now.

### Port 80

![](/assets/images/funbox-2/1.png)

This is just the default Apache2 installation page; I did not find anything here. I would like to run fuzzing to find out if there are any interesting files or directories present.

### Fuzzing Directories

```bash
wfuzz -c -z file,/usr/share/seclists/Discovery/Web-Content/raft-large-directories.txt --hc 404 "$URL"

=====================================================================
ID           Response   Lines    Word       Chars       Payload                                                                                      
=====================================================================
000004227:   403        9 L      28 W       275 Ch      "server-status"                                                                              
000004255:   200        375 L    964 W      10918 Ch    "http://10.10.10.8/" 
```

### Fuzzing Files

```bash
wfuzz -c -z file,/usr/share/seclists/Discovery/Web-Content/raft-large-files.txt --hc 404 "$URL"

=====================================================================
ID           Response   Lines    Word       Chars       Payload                                                                                      
=====================================================================
000000069:   200        375 L    964 W      10918 Ch    "index.html"                                                                                 
000000157:   403        9 L      28 W       275 Ch      ".htaccess"                                                                                  
000000248:   200        1 L      2 W        17 Ch       "robots.txt"                                                                                 
000000379:   200        375 L    964 W      10918 Ch    "."                                                                                          
000000537:   403        9 L      28 W       275 Ch      ".html"                                                                                      
000000806:   403        9 L      28 W       275 Ch      ".php"                                                                                       
000001564:   403        9 L      28 W       275 Ch      ".htpasswd"                                                                                  
000001830:   403        9 L      28 W       275 Ch      ".htm"                                                                                                  
```

I didn't find anything interesting; it seems they have only installed the Apache2 service, and no application is hosted there.

### Port 21

![](/assets/images/funbox-2/2.png)

I have successfully logged in as an anonymous user through FTP, and there are many files present here.

![](/assets/images/funbox-2/3.png)

![](/assets/images/funbox-2/4.png)

I have downloaded all the files to my local machine to analyze them. There were two hidden files, and I just renamed the files to make them visible.

![](/assets/images/funbox-2/5.png)

The 'users' file and 'admin' file had the same content. However, the content of the 'admin' file was base64 encrypted, while the 'users' file's content was in plain text format. Inside the content, they provided an idea about the zipped file data, and the password for the zip file was the old password. Currently, we don't have any information about this password.

I used the Zip2John tool to create a file compatible with John the Ripper and started brute-forcing using the rockyou.txt file. Within a moment, I obtained the password for the 'tom.zip' file.

![](/assets/images/funbox-2/6.png)

Using the password, I successfully decrypted the file, and it's an 'id_rsa' file. Now, with the 'id_rsa' file in hand and the SSH port open, we can utilize the SSH port to gain a real shell on this box.

![](/assets/images/funbox-2/7.png)

# Initial Foothold

![](/assets/images/funbox-2/8.png)

As I obtained the 'id_rsa' file, I used this private key instead of the user's password. So, I passed the file and successfully logged into the machine.

# Post Enumeration & Privilege Escalation

![](/assets/images/funbox-2/9.png)

I performed the 'ls -la' command to check the content present in the current directory. Here, I found a MySQL history file and a 'sudo_as_admin_successful' file. The 'sudo_as_admin_successful' file is an indication of the user's sudo permission existence. Maybe it doesn't have full sudo permissions, but at least it has the minimal amount. I performed 'sudo -l' to find out the permissions, but it asked for the password of this user. To find another way to get root or the 'tom' user's password, I tried to open the 'mysql_history' file and encountered an error related to 'rbash'.

![](/assets/images/funbox-2/10.png)

Rbash is a restricted bash environment where the user only gets some limited permissions. However, rbash is not very reliable because there are lots of techniques and tricks already available to escape rbash. In this scenario, I would like to go for the vi editor escaping technique.

```bash
vi
:set shell=/bin/bash
:shell
```

It works every time. Now we can see the mysql_history file.

![](/assets/images/funbox-2/11.png)

inside the file i found a insert command where tom and a strings is visible so i just tried the strings a the password and it worked.

![](/assets/images/funbox-2/12.png)

We can see that the 'tom' user has full sudo permission on this box, and now that we have the user's password, we can simply switch the user to root, and we are now root.

![](/assets/images/funbox-2/13.png)