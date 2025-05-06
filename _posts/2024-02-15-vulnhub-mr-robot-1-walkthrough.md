---
layout: single
author_profile: true
title: Vulnhub Mr. Robot 1 Walkthrough 
date: 2023-11-11
comments: true
share: true
categories: TJ-Null-OSCP
tags: []
header:
  overlay_image: /assets/images/mr-robot-1/cover.png
  overlay_filter: 0.3  # optional, darkens the image for readability
  caption: "five86-2 Vulnhub Walkthrough"
excerpt: "Step-by-step walkthrough of the mr-robot-1 machine from Vulnhub."
feature_row:
  - image_path: /assets/images/mr-robot-1/cover.png
    alt: "mr-robot-1 Cover"
    title: "mr-robot-1 Walkthrough"
    excerpt: "A practical guide to rooting the mr-robot-1 Vulnhub machine."
    url: "#"
    btn_label: "Read More"
    btn_class: "btn--primary"
toc: true
toc_sticky: true
---

# Mr. Robot-1

For the initial foothold, we need to discover the underlying technology of the web application. Upon checking the hidden files or directories, I found that it's a WordPress web application. Additionally, I found the robots.txt file along with two other files, one of which is a wordlist. We can scan the application through WPScan with the wordlist, which should give us valid administrative user credentials.

After logging into the account, there are two ways to get a reverse shell: by adding a reverse shell plugin or by editing existing files. The privilege escalation is pretty straightforward; we need to identify the SUID binaries, where an older version of nmap is available with an interactive mode, which can lead to root privilege.

# Information Gathering

First, I want to start with Nmap to identify the open ports and their associated services. If possible, Nmap will also provide information about the service versions and the operating system. This is a good starting point when working with any assets.

**Nmap**

```bash
ports=$(nmap -p- --min-rate=1000 -T4 $IP | grep ^[0-9] | cut -d '/' -f 1 | tr '\n' ',' | sed s/,$//) ; nmap -p$ports -sC -sV -oN nmap/service_scan $IP

PORT    STATE SERVICE  VERSION
80/tcp  open  http     Apache httpd
|_http-title: Site doesn't have a title (text/html).
|_http-server-header: Apache
443/tcp open  ssl/http Apache httpd
|_http-server-header: Apache
| ssl-cert: Subject: commonName=www.example.com
| Not valid before: 2015-09-16T10:45:03
|_Not valid after:  2025-09-13T10:45:03
|_http-title: Site doesn't have a title (text/html).
```

From the Nmap scan, we discovered only two open ports: 80 and 443, both of which are serving an Apache server. Additionally, we identified a domain name, [`www.example.com`](http://www.example.com/). We can add this domain to our host file and interact with it. Let's begin by visiting the web application through the browser.

**Manual Inspection**

Both ports are serving the same web application, which resembles a machine web console. However, the available commands are limited, and it appears to be a simulated command-line interface rather than an original one. Given the constraints, there doesn't seem to be a way to abuse this functionality.

![](/assets/images/mr-robot-1/1.png)

Alright, let's fire up Gobuster to perform directory and file fuzzing. This will help us uncover any hidden directories or files that might not be readily accessible through the web application interface. Gobuster is a powerful tool for this purpose, and it can help us gather more information about the web server and its directory structure.

```bash
gobuster dir -u http://192.168.197.146 -w /usr/share/wordlists/seclists/Discovery/Web-Content/raft-large-directories.txt
===============================================================
Gobuster v3.6
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@firefart)
===============================================================
[+] Url:                     http://192.168.197.146
[+] Method:                  GET
[+] Threads:                 10
[+] Wordlist:                /usr/share/wordlists/seclists/Discovery/Web-Content/raft-large-directories.txt
[+] Negative Status codes:   404
[+] User Agent:              gobuster/3.6
[+] Timeout:                 10s
===============================================================
Starting gobuster in directory enumeration mode
===============================================================
/images               (Status: 301) [Size: 238] [--> http://192.168.197.146/images/]
/js                   (Status: 301) [Size: 234] [--> http://192.168.197.146/js/]
/admin                (Status: 301) [Size: 237] [--> http://192.168.197.146/admin/]
/wp-content           (Status: 301) [Size: 242] [--> http://192.168.197.146/wp-content/]
/css                  (Status: 301) [Size: 235] [--> http://192.168.197.146/css/]
/wp-admin             (Status: 301) [Size: 240] [--> http://192.168.197.146/wp-admin/]
/wp-includes          (Status: 301) [Size: 243] [--> http://192.168.197.146/wp-includes/]
/xmlrpc               (Status: 405) [Size: 42]
/login                (Status: 302) [Size: 0] [--> http://192.168.197.146/wp-login.php]
/blog                 (Status: 301) [Size: 236] [--> http://192.168.197.146/blog/]
/feed                 (Status: 301) [Size: 0] [--> http://192.168.197.146/feed/]
/rss                  (Status: 301) [Size: 0] [--> http://192.168.197.146/feed/]
/video                (Status: 301) [Size: 237] [--> http://192.168.197.146/video/]
/sitemap              (Status: 200) [Size: 0]
/image                (Status: 301) [Size: 0] [--> http://192.168.197.146/image/]
/audio                (Status: 301) [Size: 237] [--> http://192.168.197.146/audio/]
/phpmyadmin           (Status: 403) [Size: 94]
/dashboard            (Status: 302) [Size: 0] [--> http://192.168.197.146/wp-admin/]
/wp-login             (Status: 200) [Size: 2761]
/0                    (Status: 301) [Size: 0] [--> http://192.168.197.146/0/]
/atom                 (Status: 301) [Size: 0] [--> http://192.168.197.146/feed/atom/]
/robots               (Status: 200) [Size: 41]
/license              (Status: 200) [Size: 19930]
/intro                (Status: 200) [Size: 516314]
/Image                (Status: 301) [Size: 0] [--> http://192.168.197.146/Image/]
/IMAGE                (Status: 301) [Size: 0] [--> http://192.168.197.146/IMAGE/]
/rss2                 (Status: 301) [Size: 0] [--> http://192.168.197.146/feed/]
/readme               (Status: 200) [Size: 7334]
/rdf                  (Status: 301) [Size: 0] [--> http://192.168.197.146/feed/rdf/]
/0000                 (Status: 301) [Size: 0] [--> http://192.168.197.146/0000/]
/wp-config            (Status: 200) [Size: 0]
```

Upon checking the Gobuster output, we discovered some interesting URLs. The most intriguing aspect is that the application is built on WordPress. Additionally, from the robots.txt file, we found two more filenames: one is `first_key`, and the other is a `wordlist`.

![](/assets/images/mr-robot-1/2.png)

WordPress responds differently during login attempts depending on whether the username and password are correct or incorrect. To ensure accuracy, I ran Hydra using the file obtained from the application as a list of usernames and a simple password. After a short while, I received a valid username response. Now that I have a valid username, I can use Hydra again, this time with the username and the file as a password list to retrieve the password.

![](/assets/images/mr-robot-1/3.png)

I utilized WPScan to discover the password for the username I found using Hydra, and I successfully retrieved the password. While WPScan can comprehensively explore WordPress installations, including usernames, passwords, and other vulnerabilities, I chose to skip that part since I already obtained the necessary information through Hydra.

![](/assets/images/mr-robot-1/4.png)

I successfully logged into an administrative account. Given its administrative privileges, there are several methods to obtain a reverse shell. One option involves uploading a reverse shell plugin to acquire a reverse shell from there. Alternatively, we can edit an existing file to incorporate the reverse shell code and obtain a reverse shell from it.

![](/assets/images/mr-robot-1/5.png)

# Initial Foothold

For now, I will edit the 404 page because it's easy to generate a 404 response. I've copied a reverse shell, updated the IP and port, and then saved the file.

![](/assets/images/mr-robot-1/6.png)

Here, I've fired up a netcat listener to catch the reverse shell. From the browser, I generated a 404 response, and I successfully received the reverse shell from the machine.

![](/assets/images/mr-robot-1/7.png)

# Post Enumeration & Privilege Escalation

I upgraded my shell using stty. From the robot user’s home directory, I obtained their username and password. The password was encrypted with MD5, as indicated in the filename. After cracking the hash, I changed the user to `robot`.

![](/assets/images/mr-robot-1/8.png)

Crackstation crack the password very easily.

![](/assets/images/mr-robot-1/8.png)

Now, I've searched for the SUID binaries and found nmap among them. The old version of nmap features an interactive mode through which we can potentially obtain a shell. Since nmap is listed as an SUID binary, there's a possibility of escalating privileges to root from here.

```bash
find / -perm -u=s -type f 2>/dev/null

/bin/ping
/bin/umount
/bin/mount
/bin/ping6
/bin/su
/usr/bin/passwd
/usr/bin/newgrp
/usr/bin/chsh
/usr/bin/chfn
/usr/bin/gpasswd
/usr/bin/sudo
/usr/local/bin/nmap
/usr/lib/openssh/ssh-keysign
/usr/lib/eject/dmcrypt-get-device
/usr/lib/vmware-tools/bin32/vmware-user-suid-wrapper
/usr/lib/vmware-tools/bin64/vmware-user-suid-wrapper
/usr/lib/pt_chown
```

I ran nmap in interactive mode and successfully received the shell with root privileges.

![](/assets/images/mr-robot-1/10.png)