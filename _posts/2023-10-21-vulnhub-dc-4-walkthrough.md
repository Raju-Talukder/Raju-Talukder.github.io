---
layout: single
author_profile: true
cover:  assets/images/dc-4/cover.png
title: Vulnhub DC-4 Walkthrough 
date: 2023-10-21
categories: DC-Series
featured: false
---

This box was so easy. There are only two ports open: SSH and the HTTP server. For the initial foothold, we need to attempt a brute force attack on the login form of the web application. After logging into the application, we can intercept the request and modify the commands. The lack of input validation will give us the command injection vulnerability, allowing us to gain the initial foothold into the box. The privilege escalation is also straightforward. We found a stored password list, and there was a valid password for one user, which allowed SSH login. Checking the mail revealed another user's password who has some super permissions on a file editor. Using these super permissions, we can edit any file, leading to root access.

# Information Gathering

First, I want to start with Nmap to identify the open ports and their associated services. If possible, Nmap will also provide information about the service versions and the operating system. This is a good starting point when working with any assets.

```bash
nmap -p22,80 -sC -sV 192.168.197.136

PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 7.4p1 Debian 10+deb9u6 (protocol 2.0)
| ssh-hostkey: 
|   2048 8d:60:57:06:6c:27:e0:2f:76:2c:e6:42:c0:01:ba:25 (RSA)
|   256 e7:83:8c:d7:bb:84:f3:2e:e8:a2:5f:79:6f:8e:19:30 (ECDSA)
|_  256 fd:39:47:8a:5e:58:33:99:73:73:9e:22:7f:90:4f:4b (ED25519)
80/tcp open  http    nginx 1.15.10
|_http-title: System Tools
|_http-server-header: nginx/1.15.10
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

From the Nmap scan, I found only two open ports: SSH and the web server. Since there are no credentials, port 22 is not relevant for now. Let's start hunting through the web server.

**Manual Inspection**

![](/assets/images/dc-4/1.png)

There is also nothing except the login form. I tried SQL injection, but it did not work. Default passwords did not work, and username enumeration was not successful. So, I tried a brute-force attack with the default admin username, given that it's a vulnerable box. If it were a real application, I don't think this would have worked so far. We may need to create a different username and password list to run a more effective brute-force attack.

```bash
hydra -l admin -P /usr/share/wordlists/rockyou.txt 192.168.197.136 http-post-form '/login.php:username=^USER^&password=^PASS^:S=command'

[DATA] attacking http-post-form://192.168.197.136:80/login.php:username=^USER^&password=^PASS^:S=command
[80][http-post-form] host: 192.168.197.136   login: admin   password: happy
1 of 1 target successfully completed, 1 valid password found
```

I’m lucky enough for now, i got the password for the admin user.

![](/assets/images/dc-4/2.png)

There is nothing only command and logout option. So, i go for command.

![](/assets/images/dc-4/3.png)

There is some functionality to run system commands. I plan to intercept the request and try to modify the default command they send. If I can manage to send my own commands, I will find the command injection vulnerability.   

![](/assets/images/dc-4/4.png)

They just send plain text commands here, and the server also accepts the modified commands. The command injection vulnerability is confirmed, and we can send a reverse shell command through this vulnerable parameter to get a reverse shell.  


# Initial Foothold

![](/assets/images/dc-4/5.png)

Earlier, I verified the command injection. Then I attempted a bash TCP one-line reverse shell, but it didn't work for me. After searching for different ways to get a shell, I found that netcat is present inside the box. Now, it's a piece of cake to get the initial foothold.  

# Privilege Escalation

![](/assets/images/dc-4/6.png)

After getting the shell as www-data, I searched for the real users on this machine and found 4 users, including root. So, I started looking for files inside the users' directories.

![](/assets/images/dc-4/7.png)

All the users' home directories were empty except for Jim's. There is a directory called 'backup' and two files, 'mbox,' which is not readable as www-data. The '[test.sh](http://test.sh/)' file has full access, and it is an SUID file. I can abuse this file since I have write access to it. However, I saw a password file, and I have three valid users, so it's better to run an SSH brute force attack now.

```bash
hydra -L users.txt -P old_password.bak 192.168.197.136 ssh

[STATUS] 120.33 tries/min, 361 tries in 00:03h, 397 to do in 00:04h, 14 active
[22][ssh] host: 192.168.197.136   login: jim   password: jibril04
```

SSH brute force successfully manage jim password. so now we can login through ssh as jim.

![](/assets/images/dc-4/8.png)

Now i’m jim through SSH.

![](/assets/images/dc-4/9.png)

Now I can read the 'mbox' file; it's an email. Let's visit the mail folder for more information. Here is an email from Charles regarding his password. So, now I have Charles' password as well.

![](/assets/images/dc-4/10.png)

I can normally change the user as chales and i done it here.

![](/assets/images/dc-4/11.png)

Before doing anything, I want to check Charles' sudo permissions here. I found he has sudo access with no password in the Teehee editor. So, as we have sudo access with a file editor, we can modify any file we want. The very easy way to get root is to add a user with UID and GID 0. 

![](/assets/images/dc-4/12.png)

Here i add raaj user with UID and GI 0 means its root user.

```bash
echo "raaj::0:0:::/bin/bash" | sudo teehee -a /etc/passwd
```

![](/assets/images/dc-4/13.png)

Now, just change the user to `raaj` and we are root because we set the UID and GID for the `raaj` user as 0. In the Linux file system, the UID and GID 0 are always reserved for the root.