---
layout: single
title: Vulnhub DC-6 Walkthrough 
date: 2023-10-23
author_profile: true
categories:
  - DC-Series
tags: []
header:
  overlay_image: /assets/images/dc-6/cover.png
  overlay_filter: 0.3  # optional, darkens the image for readability
  caption: "DC-6 Vulnhub Walkthrough"
excerpt: "Step-by-step walkthrough of the DC-6 machine from Vulnhub."
feature_row:
  - image_path: /assets/images/dc-6/cover.png
    alt: "DC-6 Cover"
    title: "DC-6 Walkthrough"
    excerpt: "A practical guide to rooting the DC-1 Vulnhub machine."
    url: "#"
    btn_label: "Read More"
    btn_class: "btn--primary"
toc: true
toc_sticky: true
---

For the initial foothold, we initiated a password brute-force attack based on a custom-generated password list, following a clue provided by the box's author. After obtaining the password, we were able to log in to the web application and discovered the activity monitor. A search on Exploit-DB revealed a publicly available exploit that facilitated the initial foothold. While exploring the file system, we discovered a user credential with read, write, and execute permissions, along with the ability to run the file as a different user. Exploiting these permissions granted another user privilege. The new user gained the ability to run 'nmap' as root. Leveraging this, we created a simple script and executed it through 'nmap' as a superuser, ultimately achieving root access to the box.

# Information Gathering
First, I want to start with Nmap to identify the open ports and their associated services. If possible, Nmap will also provide information about the service versions and the operating system. This is a good starting point when working with any assets.

```bash
ports=$(nmap -p- --min-rate=1000 -T4 $IP | grep ^[0-9] | cut -d '/' -f 1 | tr '\n' ',' | sed s/,$//) ; nmap -p$ports -sC -sV -oN nmap/service_scan $IP

PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 7.4p1 Debian 10+deb9u6 (protocol 2.0)
| ssh-hostkey: 
|   2048 3e:52:ce:ce:01:b6:94:eb:7b:03:7d:be:08:7f:5f:fd (RSA)
|   256 3c:83:65:71:dd:73:d7:23:f8:83:0d:e3:46:bc:b5:6f (ECDSA)
|_  256 41:89:9e:85:ae:30:5b:e0:8f:a4:68:71:06:b4:15:ee (ED25519)
80/tcp open  http    Apache httpd 2.4.25 ((Debian))
|_http-title: Did not follow redirect to http://wordy/
|_http-server-header: Apache/2.4.25 (Debian)
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

From the Nmap results, I found that this is a Debian-based Linux system with SSH and an Apache server installed. Apache is redirected to a domain called `wordy`. To visit the domain, you need to add an entry in the `/etc/hosts` file. 

Manual Inspection

![](/assets/images/dc-6/1.png)

Upon manual inspection of the site, I discovered it's a WordPress web application. It would be a good idea to run a WordPress scanner to thoroughly scan the application. 

```bash
wpscan --enumerate --url $URL

[+] URL: http://wordy/ [192.168.197.137]
[+] Started: Fri Oct 20 00:28:15 2023

Interesting Finding(s):
[+] WordPress version 5.1.1 identified (Insecure, released on 2019-03-13).
[+] WordPress theme in use: twentyseventeen

[i] User(s) Identified:
[+] admin
[+] mark
[+] graham
[+] sarah
[+] jens
```

From the WPScanner output, I found the WordPress version, an outdated theme, but nothing significantly critical. Some users were revealed, but no passwords were disclosed. Now, let's generate a password list with Cewl to conduct a password-based scan.

```bash
cewl -d 3 -w password.txt $URL
```

![](/assets/images/dc-6/2.png)

I generated a password and ran the password-based scan.

```bash
wpscan --url $URL --passwords password.txt

[+] Performing password attack on Xmlrpc against 5 user/s
Trying graham / here Time: 00:00:07 <=======> (445 / 445) 100.00% Time: 00:00:07

[i] No Valid Passwords Found.
```

I couldn't find any passwords. After spending a considerable amount of time, I sought some help and discovered a clue from the author on the download page, which I had missed earlier. This experience serves as a valuable lesson in the importance of thorough reconnaissance.

![](/assets/images/dc-6/3.png)

Following the clue, I generated a new password list.

```bash
cat /usr/share/wordlists/rockyou.txt| grep k01 > password.txt
```

![](/assets/images/dc-6/4.png)

Run the password scan again.

```bash
wpscan --url $URL --passwords password.txt

[+] Performing password attack on Xmlrpc against 5 user/s
[SUCCESS] - mark / helpdesk01                                                                                                                                               
Trying sarah / !lak019b Time: 00:03:55 <===> (15215 / 15215) 100.00% Time: 00:03:55

[i] Valid Combinations Found:
 | Username: mark, Password: helpdesk01
```

This time, I found one valid user credential. After logging into the portal, I discovered that this user is not an admin, so it's not possible to manage a reverse shell using this dashboard. However, there is an activity monitor. Let's try searching with this.

![](/assets/images/dc-6/5.png)

There are two exploit available, i want to use the python exploit.

![](/assets/images/dc-6/6.png)

Download the exploit to my local directory.

![](/assets/images/dc-6/7.png)


# Initial Foothold

After running the exploit, it prompted for the IP, username, and password, and then provided the shell. Now, I'm in.

![](/assets/images/dc-6/8.png)

# Privilege Escalation

After obtaining the shell as www-data, I discovered that I have access to the /home directories. Inside the 'mark' directory, I found a file named 'things_to_do' containing the username 'graham' and password.

![](/assets/images/dc-6/9.png)

As there is an SSH server, I logged into the box as 'graham' and found that 'graham' can run '/home/jens/backup.sh' as 'jens' without a password.

![](/assets/images/dc-6/10.png)

I discovered that graham also has the ability to write the file. By abusing the file permission it’s possible to get jens users privilege.

![](/assets/images/dc-6/11.png)

From the 'jens' user, I found that 'jens' can run 'nmap' with sudo privileges without entering a password. This is a very dangerous privilege that can be abused by anyone.

![](/assets/images/dc-6/12.png)

There are two types of techniques to escalate privileges with sudo access: through interactive mode and through script execution. However, the interactive mode is available only on versions 2.02 to 5.21. So, let's check the version.

![](/assets/images/dc-6/13.png)

In the updated version, the interactive mode is no longer supported, so we need to explore the other option: executing a script. Here, I created a script that will execute the '/bin/bash' command, stored it in the tmp directory as 'root.nse', and executed the script, granting me root access.

![](/assets/images/dc-6/14.png)