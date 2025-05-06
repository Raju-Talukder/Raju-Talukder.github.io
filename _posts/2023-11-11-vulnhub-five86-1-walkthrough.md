---
layout: post
author_profile: true
title: Vulnhub Five86 1 Walkthrough 
date: 2023-11-11
categories: Five86-Series
tags: []
header:
  overlay_image: /assets/images/five86-1/cover.png
  overlay_filter: 0.3  # optional, darkens the image for readability
  caption: "five86-1 Vulnhub Walkthrough"
excerpt: "Step-by-step walkthrough of the five86-1 machine from Vulnhub."
feature_row:
  - image_path: /assets/images/five86-1/cover.png
    alt: "five86-1 Cover"
    title: "five86-1 Walkthrough"
    excerpt: "A practical guide to rooting the five86-1 Vulnhub machine."
    url: "#"
    btn_label: "Read More"
    btn_class: "btn--primary"
toc: true
toc_sticky: true

---

There are two enabled HTTP services and one SSH service. One of the HTTP services, called 'opennetadmin,' is outdated and has a publicly available exploit that provides the initial foothold. To escalate privileges for the first user access, find the '.htpassword' file, which contains the username and password hash with a clue. Abusing the misconfigured 'copy' binary gives us the second user access. For the third user access, check the mailbox where you will find the last user's credentials. At this point, we only need to find the secret game directory and execute a SUID binary to gain root access.

# Information Gathering

First, I want to start with Nmap to identify the open ports and their associated services. If possible, Nmap will also provide information about the service versions and the operating system. This is a good starting point when working with any assets.

```bash
ports=$(nmap -p- --min-rate=1000 -T4 $IP | grep ^[0-9] | cut -d '/' -f 1 | tr '\n' ',' | sed s/,$//) ; nmap -p$ports -sC -sV -oN nmap_service_scan $IP
PORT      STATE SERVICE VERSION
22/tcp    open  ssh     OpenSSH 7.9p1 Debian 10+deb10u1 (protocol 2.0)
| ssh-hostkey: 
|   2048 69:e6:3c:bf:72:f7:a0:00:f9:d9:f4:1d:68:e2:3c:bd (RSA)
|   256 45:9e:c7:1e:9f:5b:d3:ce:fc:17:56:f2:f6:42:ab:dc (ECDSA)
|_  256 ae:0a:9e:92:64:5f:86:20:c4:11:44:e0:58:32:e5:05 (ED25519)
80/tcp    open  http    Apache httpd 2.4.38 ((Debian))
|_http-server-header: Apache/2.4.38 (Debian)
|_http-title: Site doesn't have a title (text/html).
| http-robots.txt: 1 disallowed entry 
|_/ona
10000/tcp open  http    MiniServ 1.920 (Webmin httpd)
|_http-title: Site doesn't have a title (text/html; Charset=iso-8859-1).
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

From the Nmap scan, we identified three open ports: SSH and two web servers. Port 80 has the 'robots.txt' file available, with a disallow entry. Port 10000 is also open, hosting Miniserv 1.920. Additionally, ports 22 and 80 confirmed that it's a Debian-based Linux system. I would like to begin by exploring the web servers, so let's dive into those.

## Manual Inspection

![](/assets/images/five86-1/1.png)

Port 80 hosts a Webmin login panel, and as of now, I don't have any credentials. I attempted the default credentials, but they did not work. Let's visit port 80 to explore further.

![](/assets/images/five86-1/2.png)

Here, we've encountered a control panel that is displaying an outdated version warning. Let's search for publicly available exploits for this specific version, if any are available.

![](/assets/images/five86-1/3.png)

Through Searchsploit, I discovered three exploits, and two of them match the version number. One of the exploits is available in the Metasploit framework. While I attempted the other bash file, the shell proved to be unstable. As a result, I'm opting to try the Metasploit framework.

![](/assets/images/five86-1/4.png)

From the metasploit i found only one command injection exploit.

**Creds**

<aside>
💡 douglas:$apr1$9fgG/hiM$BtsL9qpNHUlylaLxk81qY1

</aside>

# Initial Foothold

I configured the 'rhosts' and 'lhosts,' then executed the exploit. After a few moments, it provided me with a shell as 'www-data'.

![](/assets/images/five86-1/5.png)

# Post Enumeration & Privilege Escalation

After obtaining the shell, I explored the file system, and within '/var/www/html,' I discovered the hidden '.htaccess' file. This file contained a clue about the existence of a '.htpasswd' file inside the '/var/www' directory. Upon examining the '.htpasswd' file, I found the 'douglas' user and his password MD5 hash, along with a clue on how to generate the password list for brute-force attacks.

![](/assets/images/five86-1/6.png)

Following the clue, I generated a wordlist using Crunch.

```bash
crunch 10 10 aefhrt > wordlist.txt
```

The wordlist is so big.

![](/assets/images/five86-1/7.png)

While searching for ideas to optimize the wordlist due to its size and the potential time it would take, I came across a blog post. From the walkthrough, I got the idea to make the wordlist shorter. Observing that not every character from the clue was present in each line, I revised the wordlist to ensure that every character appeared in every line.

![](/assets/images/five86-1/8.png)

I initially ran John using the smaller wordlist. If I didn't obtain any passwords, my plan was to then run it with the larger one. During that attempt, I would exclude the passwords containing characters I had already tried. This approach eliminates the need to check passwords that have already been tested. However, the password has already been decrypted using the small wordlist.

![](/assets/images/five86-1/9.png)

As the ssh port is available using this credential i just tried to login and it succeed.

![](/assets/images/five86-1/10.png)

Inside the Douglas user's home directory, there is nothing but a .ssh directory. However, when I tried checking the sudo permissions for this user, I discovered that the user can run the 'copy' command with sudo privileges as the 'jen' user. Exploiting this misconfiguration allows us to copy anything we want. The challenge lies in not knowing the exact file location since the 'copy' command doesn't provide that information. However, since there is SSH open, we can copy an authorized key into the 'jen' user's home directory, allowing us to obtain an SSH shell as 'jen'.

![](/assets/images/five86-1/11.png)

Here i have copied the id_rsa.pub key inside the /tmp folder.

![](/assets/images/five86-1/12.png)

Here, I executed the command to transfer the RSA file into the 'jen' user's 'home/.ssh' directory as 'authorized_keys' and attempted to SSH as 'jen.' The operation succeeded, and I now have a shell as 'jen'.

![](/assets/images/five86-1/13.png)

When I established the SSH connection, I noticed a message stating 'You have mail.' Directly navigating to the mail directory, I discovered a mail file named 'jen.' Inside the mail, I found the password for the 'moss' user.

![](/assets/images/five86-1/14.png)

I just changed the user as moss using the password found from the mail and found a hidden directory inside the moss users home directory called games.

![](/assets/images/five86-1/15.png)

Here are lots of games available but one of them has the SUID which could be the way for the root.

![](/assets/images/five86-1/16.png)

I just run the games and tried with random inputs but it gives me the root access every time so i assume there is nothing based on the input. And i’m root now.

![](/assets/images/five86-1/17.png)