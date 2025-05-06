---
layout: single
author_profile: true
title: Vulnhub Aragog Walkthrough 
date: 2023-11-10
categories:
  - Harry-Potter-Series
tags: []
header:
  overlay_image: /assets/images/aragog/cover.png
  overlay_filter: 0.3  # optional, darkens the image for readability
  caption: "Aragog Vulnhub Walkthrough"
excerpt: "Step-by-step walkthrough of the aragog machine from Vulnhub."
feature_row:
  - image_path: /assets/images/aragog/cover.png
    alt: "Aragog Cover"
    title: "Aragog Walkthrough"
    excerpt: "A practical guide to rooting the aragog Vulnhub machine."
    url: "#"
    btn_label: "Read More"
    btn_class: "btn--primary"
toc: true
toc_sticky: true
---


This box is pretty straightforward; nothing complex here. Enumeration is the key. We need to enumerate and use the gathered information at the perfect moment. From the Nmap scan, we found the SSH and HTTP ports open. By visiting the web server, we discovered it's a WordPress application, and there is a vulnerable plugin, wp-file-manager, which is susceptible to an Unauthenticated Arbitrary File Upload vulnerability. This vulnerability gives us the initial foothold.

For privilege escalation, the author of this box did not install WordPress in the usual place. We need to find out the configuration file, and from there, we can get the MySQL credentials. Logging into MySQL provides us with the hagrid98 user password hash. Using John, we decrypt the password and log in as the hagrid98 user. Then, we find the cronjob and modify the file to gain root access.

# Information Gathering

First, I want to begin with Nmap to identify the open ports and their associated services. If possible, Nmap will also provide information about the service versions and the operating system. This is a good starting point when working with any assets.


```bash
ports=$(nmap -p- --min-rate=1000 -T4 $IP | grep ^[0-9] | cut -d '/' -f 1 | tr '\n' ',' | sed s/,$//) ; nmap -p$ports -sC -sV -oN nmap/service_scan $IP

PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 7.9p1 Debian 10+deb10u2 (protocol 2.0)
| ssh-hostkey: 
|   2048 48:df:48:37:25:94:c4:74:6b:2c:62:73:bf:b4:9f:a9 (RSA)
|   256 1e:34:18:17:5e:17:95:8f:70:2f:80:a6:d5:b4:17:3e (ECDSA)
|_  256 3e:79:5f:55:55:3b:12:75:96:b4:3e:e3:83:7a:54:94 (ED25519)
80/tcp open  http    Apache httpd 2.4.38 ((Debian))
|_http-server-header: Apache/2.4.38 (Debian)
|_http-title: Site doesn't have a title (text/html).
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

From the Nmap scan, we found two publicly available ports: the first one being SSH, and the second one is HTTP. Both banners indicate it's a Debian box. However, we did not gather much information from the Nmap results. Let's manually check the application since we don't have any credentials to work with SSH directly.

**Manual Inspection**

![](/assets/images/aragog/1.png)

There is only a Harry Potter image available, and there's no apparent user-server communication. At this point, we can begin fuzzing for directories and files.

```bash
wfuzz -c -z file,/usr/share/seclists/Discovery/Web-Content/raft-large-files.txt --hc 404 "$URL"

=====================================================================
ID           Response   Lines    Word       Chars       Payload                                                                                        
=====================================================================

000000069:   200        5 L      11 W       97 Ch       "index.html"                                                                                   
000000157:   403        9 L      28 W       275 Ch      ".htaccess"                                                                                    
000000379:   200        5 L      11 W       97 Ch       "."                                                                                            
000000537:   403        9 L      28 W       275 Ch      ".html"                                                                                        
000000806:   403        9 L      28 W       275 Ch      ".php"                                                                                         
000001564:   403        9 L      28 W       275 Ch      ".htpasswd"                                                                                    
000001830:   403        9 L      28 W       275 Ch      ".htm"                                                                                         
000002100:   403        9 L      28 W       275 Ch      ".htpasswds"                                                                                   
000004625:   403        9 L      28 W       275 Ch      ".htgroup"                                                                                     
000005172:   403        9 L      28 W       275 Ch      "wp-forum.phps"                                                                                
000007079:   403        9 L      28 W       275 Ch      ".htaccess.bak"                                                                                
000008688:   403        9 L      28 W       275 Ch      ".htuser"                                                                                      
000011459:   403        9 L      28 W       275 Ch      ".ht"                                                                                          
000011460:   403        9 L      28 W       275 Ch      ".htc"                                                                                         
000017181:   403        9 L      28 W       275 Ch      ".htaccess.old"                                                                                
000017182:   403        9 L      28 W       275 Ch      ".htacess"
```

File fuzzing didn't yield anything interesting. However, during directory fuzzing, I discovered a 'blog' directory with a status code of 301. Let's visit the directory manually.

```bash
wfuzz -c -z file,/usr/share/seclists/Discovery/Web-Content/raft-large-directories.txt --hc 404 "$URL"

=====================================================================
ID           Response   Lines    Word       Chars       Payload                                                                                        
=====================================================================
000000050:   301        9 L      28 W       307 Ch      "blog"                                                                                         
000000139:   301        9 L      28 W       313 Ch      "javascript"                                                                                   
000004227:   403        9 L      28 W       275 Ch      "server-status"
```

The application did not load properly. When I hovered the mouse over a link, I found a domain name. Let's add this to the hosts file.

```bash
echo '10.10.10.7 wordpress.aragog.hogwarts' | sudo tee -a /etc/hosts

10.10.10.7 wordpress.aragog.hogwarts
```

Now the application is loaded properly and this is a WordPress application.

![](/assets/images/aragog/2.png)

Always running some recon in the background is better. Since it's a WordPress application, I would like to run WPScanner in the background to enumerate the themes and plugins used here.

```bash
wpscan --enumerate ap --plugins-detection aggressive --plugins-version-detection aggressive --url http://wordpress.aragog.hogwarts/blog 

[+] URL: http://wordpress.aragog.hogwarts/blog/ [10.10.10.7]
[+] Started: Tue Nov 14 20:14:07 2023

Interesting Finding(s):

[+] WordPress version 5.0.12 identified (Insecure, released on 2021-04-15).

[+] WordPress theme in use: twentynineteen
 | [!] The version is out of date, the latest version is 2.7

[i] Plugin(s) Identified:

[+] akismet
 | Location: http://wordpress.aragog.hogwarts/blog/wp-content/plugins/akismet/
 | Latest Version: 5.3

[+] wp-file-manager
 | Version: 6.0 (100% confidence)
```

WPScanner found the default themes and plugins, and it identified the presence of the wp-file-manager plugin. At this point, I would like to search for publicly available exploits. The Exploit Database has a cross-site scripting vulnerability exploit for the Akismet plugin and an unauthenticated arbitrary file upload leading to RCE exploit for wp-file-manager plugins.

![](/assets/images/aragog/3.png)

I copied the exploit into my current directory and ran it. Fortunately, it successfully exploited the vulnerability. It's confirmed now that there is a file upload vulnerability leading to RCE. I attempted to take a reverse shell through RCE, but unfortunately, I failed.

![](/assets/images/aragog/4.png)

So, I planned to upload a reverse shell file. This payload helped me successfully upload the file to the server.

![](/assets/images/aragog/5.png)

# Initial Foothold

I uploaded a PHP reverse shell payload file from PentesterMonkey.

![](/assets/images/aragog/6.png)

After successfully uploaded the file i just visited this URl with a listener on to catch the revers shell.

```jsx
http://wordpress.aragog.hogwarts//blog/wp-content/plugins/wp-file-manager/lib/files/exp.php
```

It gave me the initial foothold into the box by providing a reverse shell.

![](/assets/images/aragog/7.png)

# Post Enumeration & Privilege Escalation

After obtaining the shell as www-data, I explored the file system and discovered the '.backup.sh' file inside the '/opt' directory. I only have execute and read permissions, and the owner of this file, 'hagrid98,' has full authority. Given the file name 'backup' and its function of copying files from the web server's upload directory to the 'tmp' folder, there is a possibility of a cronjob. Since this is a WordPress installation, the config file may contain the MySQL credentials. Let's find that.

![](/assets/images/aragog/8.png)

From the backup script, we observed that the WordPress folder is not present inside '/var/www/html.' They configured this in a different way. I want to find all folders named 'wordpress' first and will check each one for critical information.

```bash
www-data@Aragog:/var/www$ find / -type d -name wordpress 2> /dev/null
/var/lib/wordpress
/var/lib/mysql/wordpress
/usr/share/doc/wordpress
/usr/share/wordpress
/usr/share/wordpress/wp-includes/js/tinymce/skins/wordpress
/usr/share/wordpress/wp-includes/js/tinymce/plugins/wordpress
/etc/wordpress
```

However, from the 'find' command output, the first directory that caught my eye was the '/etc/wordpress' folder. Inside the directory, I found the 'config-default.php' file containing the credentials.

![](/assets/images/aragog/9.png)

Inside the database i found hagrid98 user and password hash.

![](/assets/images/aragog/10.png)

John was so kind to decrypt the hash within a moment.

![](/assets/images/aragog/11.png)

Now that I have the credentials, I tried to log in through SSH, and it succeeded. I now have a proper SSH connection into the box.

![](/assets/images/aragog/12.png)

As the previous confusion about the cronjob persisted, I transferred pspy64 into the box and ran it to observe all the input and output activities inside the machine. Within a few moments, I got a hit from root to the '[backup.sh](http://backup.sh/)' file. Now, as the hagrid98 user, I have the ability to modify the file—I can put anything I want, and root will execute whatever I write into that file. Getting root is now just a piece of cake.

![](/assets/images/aragog/13.png)

I modified the file and added a reverse shell script. When the root user executes the file, I will get a reverse shell as root.

![](/assets/images/aragog/14.png)

I opened the listener and waited for root to execute the file. Within a minute, I got the shell, and I am now root.

![](/assets/images/aragog/15.png)