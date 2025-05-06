---
layout: single
author_profile: true
title: Vulnhub Funbox 3 Walkthrough 
date: 2023-11-17
comments: true
share: true
categories: Funbox-Series
tags: []
header:
  overlay_image: /assets/images/funbox-3/cover.png
  overlay_filter: 0.3  # optional, darkens the image for readability
  caption: "funbox-3 Vulnhub Walkthrough"
excerpt: "Step-by-step walkthrough of the funbox-3 machine from Vulnhub."
feature_row:
  - image_path: /assets/images/funbox-3/cover.png
    alt: "funbox-3 Cover"
    title: "funbox-3 Walkthrough"
    excerpt: "A practical guide to rooting the funbox-3 Vulnhub machine."
    url: "#"
    btn_label: "Read More"
    btn_class: "btn--primary"
toc: true
toc_sticky: true
---

This box was quite interesting to me. I found lots of rabbit holes here. Initially, we discovered three applications. The admin application was vulnerable to SQL injection (SQLi), and we successfully bypassed the authentication, but I could not find any way to access the box from there. In the gym application, I did not find anything exploitable. However, the store application was also vulnerable to SQLi, and we successfully dumped the admin credentials and logged into the application.

The file upload vulnerability was not working for me, so I searched for publicly available exploits and found a Remote Code Execution (RCE) vulnerability. Using the RCE, I obtained credentials for SSH, which led to the initial foothold. Privilege escalation was very straightforward, involving the misuse of permissions. However, we can also obtain root access using the SUID binary.

# Information Gathering

First, I want to start with Nmap to identify the open ports and their associated services. If possible, Nmap will also provide information about the service versions and the operating system. This is a good starting point when working with any assets.

```bash
ports=$(nmap -p- --min-rate=1000 -T4 $IP | grep ^[0-9] | cut -d '/' -f 1 | tr '\n' ',' | sed s/,$//) ; nmap -p$ports -sC -sV -oN nmap/service_scan $IP

PORT      STATE SERVICE VERSION
22/tcp    open  ssh     OpenSSH 8.2p1 Ubuntu 4ubuntu0.1 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   3072 b2:d8:51:6e:c5:84:05:19:08:eb:c8:58:27:13:13:2f (RSA)
|   256 b0:de:97:03:a7:2f:f4:e2:ab:4a:9c:d9:43:9b:8a:48 (ECDSA)
|_  256 9d:0f:9a:26:38:4f:01:80:a7:a6:80:9d:d1:d4:cf:ec (ED25519)
80/tcp    open  http    Apache httpd 2.4.41 ((Ubuntu))
|_http-title: Apache2 Ubuntu Default Page: It works
| http-robots.txt: 1 disallowed entry 
|_gym
|_http-server-header: Apache/2.4.41 (Ubuntu)
33060/tcp open  mysqlx?
| fingerprint-strings: 
|   DNSStatusRequestTCP, LDAPSearchReq, NotesRPC, SSLSessionReq, TLSSessionReq, X11Probe, afp: 
|     Invalid message"
|_    HY000
```

From the Nmap output, we found three open ports. The first one is SSH, and the second and third are web server and MySQL server, respectively. Both service banners confirmed that this is an Ubuntu machine. We can see a message from the web server; it's a default page, and there is one disallowed entry available. Before we move on, I would like to run a directory brute force on it.

```bash
gobuster dir -u http://10.10.10.11/ -w /usr/share/seclists/Discovery/Web-Content/raft-large-directories.txt 

===============================================================
Gobuster v3.6
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@firefart)
===============================================================
[+] Url:                     http://10.10.10.11/
[+] Method:                  GET
[+] Threads:                 10
[+] Wordlist:                /usr/share/seclists/Discovery/Web-Content/raft-large-directories.txt
[+] Negative Status codes:   404
[+] User Agent:              gobuster/3.6
[+] Timeout:                 10s
===============================================================
Starting gobuster in directory enumeration mode
===============================================================
/admin                (Status: 301) [Size: 310] [--> http://10.10.10.11/admin/]
/store                (Status: 301) [Size: 310] [--> http://10.10.10.11/store/]
/secret               (Status: 301) [Size: 311] [--> http://10.10.10.11/secret/]
/server-status        (Status: 403) [Size: 276]
Progress: 23186 / 62285 (37.23%)[ERROR] parse "http://10.10.10.11/error\x1f_log": net/url: invalid control character in URL
/gym                  (Status: 301) [Size: 308] [--> http://10.10.10.11/gym/]
Progress: 62284 / 62285 (100.00%)
===============================================================
Finished
===============================================================
```

From the directory fuzzing, we found three more interesting directories: admin, store, and secret. Let's manually inspect each directory one by one.

![](/assets/images/funbox-3/1.png)

From the secret i did not found anything interesting. From the admin i found the login page and i tried the basic authentication bypass SQLi payload here.

![](/assets/images/funbox-3/2.png)

The login panel is vulnerable to SQL injection (SQLi), and we successfully bypassed the authentication. However, after spending a good amount of time, I understand that there is no way to obtain a shell, maybe this is a rabbit hole. 

![](/assets/images/funbox-3/3.png)

I moved on to the gym application and found nothing interesting here as well. I didn't want to invest a lot of time here, so I decided to move on to the store application.

![](/assets/images/funbox-3/4.png)

In the store application, I found lots of books present, and the title is 'CSE Bookstore.' I also noticed that this application is powered by ProjectWorld. I will look for publicly available exploits.

![](/assets/images/funbox-3/5.png)

First, I clicked on a book image and added a single quote at the end of the URL to generate a SQL syntax error, checking if the application is vulnerable to SQL injection. It did indeed generate the error.

![](/assets/images/funbox-3/6.png)

So, I ran SQLmap and dumped the admin password from the admin table.

![](/assets/images/funbox-3/7.png)

I logged in as an admin, and there is a feature for adding a book where we can upload PHP files as well. Unfortunately, I could not add any books; there was a SQL error for me. So, I searched for publicly available exploits and found this remote code execution exploit on ExploitDB.

![](/assets/images/funbox-3/8.png)

i just search through the terminal and download it to my current folder.

![](/assets/images/funbox-3/9.png)

# Initial foothold

![](/assets/images/funbox-3/10.png)

By running the payload, I got the Remote Code Execution (RCE). However, this shell is not a reverse shell; it's just a remote code execution. So, I was poking around with the file system inside the home directory. We found a user, and inside the user's directory, we found a password file.

![](/assets/images/funbox-3/11.png)

As the SSH port is open and the SSH password is mentioned, we can SSH into the box using these credentials. And now, we are in.

![](/assets/images/funbox-3/12.png)

# Post Enumeration & Privilege Escalation

![](/assets/images/funbox-3/13.png)

First, I checked the sudo permissions and found the 'time' binary here, which seems exotic to me. So, I searched in GTFOBins and found two privilege escalation techniques using sudo and the SUID method.

![](/assets/images/funbox-3/14.png)

i just tried the sudo technique and it works.

![](/assets/images/funbox-3/15.png)

When I ran the 'id' command, I found that this user is also a member of the 'lxd' group. The 'lxd' group has a publicly available exploit, but the prerequisite is that we need to run the 'lxd' and 'lxc' binaries. So, I tried to run them to check if they are present or not, but I received a 'permission denied' error.

![](/assets/images/funbox-3/16.png)

I was curious enough, so I tried to find the SUID binaries and found 'time' here as well. 

```bash
find / -perm -u=s -type f 2>/dev/null

/usr/lib/dbus-1.0/dbus-daemon-launch-helper
/usr/lib/policykit-1/polkit-agent-helper-1
/usr/lib/openssh/ssh-keysign
/usr/lib/snapd/snap-confine
/usr/lib/eject/dmcrypt-get-device
/usr/bin/umount
/usr/bin/sudo
/usr/bin/time
/usr/bin/chfn
/usr/bin/mount
/usr/bin/gpasswd
/usr/bin/newgrp
/usr/bin/pkexec
/usr/bin/passwd
/usr/bin/su
/usr/bin/at
/usr/bin/chsh
/usr/bin/fusermount
```

And this technique also worked. The 'id' command shows that I am still Tony; however, the effective UID is root, so I can perform every task as root.

![](/assets/images/funbox-3/17.png)