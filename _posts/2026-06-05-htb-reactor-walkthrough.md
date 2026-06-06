---
layout: single
title: "HackTheBox Reactor Walkthrough: From Next.js RCE to Root via Node.js Inspector Abuse"
date: 2026-06-05
author_profile: true
comments: true
share: true
categories: HTB-Machine
tags: []
header:
  overlay_image: /assets/images/reactor/cover.png
  overlay_filter: 0.3  # optional, darkens the image for readability
  caption: "HackTheBox Reactor Walkthrough: From Next.js RCE to Root via Node.js Inspector Abuse"
excerpt: "HHackTheBox Reactor Walkthrough: From Next.js RCE to Root via Node.js Inspector Abuse"
feature_row:
  - image_path: /assets/images/reactor/cover.png
    alt: "HHackTheBox Reactor Walkthrough: From Next.js RCE to Root via Node.js Inspector Abuse"
    title: "HackTheBox Reactor Walkthrough: From Next.js RCE to Root via Node.js Inspector Abuse"
    excerpt: "A practical guide to solving the HTB Reactor machine."
    url: "#"
    btn_label: "Read More"
    btn_class: "btn--primary"
toc: true
toc_sticky: true
---

# Reactor

# Summary

Reactor is a Linux-based Hack The Box machine that focuses on modern web application exploitation and privilege escalation. Initial enumeration identified a Next.js application running on port 3000. Further investigation revealed the application was vulnerable to **CVE-2025-55182 (React Server Components Remote Code Execution)**, allowing arbitrary command execution and the acquisition of an initial shell as the `node` user. During post-exploitation enumeration, a SQLite database containing user credentials was discovered, leading to SSH access as the `engineer` user. Finally, privilege escalation was achieved by abusing a root-owned Node.js process running with the **Inspector Debugger** enabled on localhost, resulting in full root compromise of the target system.

# Information Gathering

The assessment began with a comprehensive network reconnaissance scan using Nmap to identify exposed services and potential attack surfaces on the target host. A full TCP port scan followed by service enumeration revealed two open ports: SSH (22/tcp) and a web application running on port 3000/tcp. Additionally, the TTL value of 63 observed in the responses strongly suggested that the underlying operating system was Linux-based.

```bash
ports=$(nmap -p- --min-rate=1000 -T4 $IP | grep ^[0-9] | cut -d '/' -f 1 | tr '\n' ',' | sed s/,$//) ; nmap -p$ports -sC -sV -vv -oN nmap/service_scan $IP

PORT     STATE SERVICE REASON         VERSION                                                                                                               
22/tcp   open  ssh     syn-ack ttl 63 OpenSSH 9.6p1 Ubuntu 3ubuntu13.16 (Ubuntu Linux; protocol 2.0)                                                        
| ssh-hostkey:                                                                                                                                              
|   256 ce:fd:0d:82:c0:23:ed:6e:4b:ea:13:fa:4f:ea:ef:b7 (ECDSA)                                                                                             
| ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBIoh32XcLYi0Kdad12SajqVyUVXfkDPaB7zZCDCMIJc+fv8JUJwyQRoqX/91+p6uD75Ggdp4VNzA7WasIk
yo/4U=                                                                                                                                                      
|   256 f8:44:c6:46:58:7a:39:21:ef:16:44:e9:58:c2:f3:62 (ED25519)                                                                                           
|_ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPws9RyzoCW2cXzOFxeZCCt8rWcNu2umX2kqLLK6T+7H                                                                          
3000/tcp open  ppp?    syn-ack ttl 63                                                                                                                       
| fingerprint-strings:                                                                                                                                      
|   GetRequest:                                                                                                                                             
|     HTTP/1.1 200 OK                                                                                                                                       
|     Vary: RSC, Next-Router-State-Tree, Next-Router-Prefetch, Next-Router-Segment-Prefetch, Accept-Encoding                                                
|     x-nextjs-cache: HIT                                                                                                                                   
|     x-nextjs-prerender: 1                                                                                                                                 
|     x-nextjs-stale-time: 4294967294                                                                                                                       
|     X-Powered-By: Next.js                                                                                                                                 
|     Cache-Control: s-maxage=31536000,                                                                                                                     
|     ETag: "p02u6gnhufd8t"                                                                                                                                 
|     Content-Type: text/html; charset=utf-8                                                                                                                
|     Content-Length: 17175                                                                                                                                 
|     Date: Mon, 01 Jun 2026 09:46:08 GMT                                                                                                                   
|     Connection: close                                                                                                                                     
|     <!DOCTYPE html><html lang="en"><head><meta charSet="utf-8"/><meta name="viewport" content="width=device-width, initial-scale=1"/><link rel="stylesheet
" href="/_next/static/css/414e1be982bc8557.css" data-precedence="next"/><link rel="preload" as="script" fetchPriority="low" href="/_next/static/chunks/webpa
ck-db0a529a99835594.js"/><script src="/_next/static/chunks/4bd1b696-80bcaf75e1b4285e.js" async=""></script><script src="/_next/static/chunks/517-d083b552e04
dead1.js" async=""></script><script s                                                                                                                       
|   HTTPOptions, RTSPRequest:                                                                                                                               
|     HTTP/1.1 400 Bad Request                                                                                                                              
|     vary: RSC, Next-Router-State-Tree, Next-Router-Prefetch, Next-Router-Segment-Prefetch                                                                 
|     Allow: GET                                                                                                                                            
|     Allow: HEAD                                                                                                                                           
|     Cache-Control: private, no-cache, no-store, max-age=0, must-revalidate                                                                                
|     Date: Mon, 01 Jun 2026 09:46:12 GMT                                                                                                                   
|     Connection: close                                                                                                                                     
|   Help, NCP: 
|     HTTP/1.1 400 Bad Request
|_    Connection: close
```

The first exposed service was SSH running on port 22, identified as OpenSSH 9.6p1 on Ubuntu Linux. Since SSH requires valid credentials for access, it was noted for potential future use but was not considered an immediate attack vector.

The second service was a web application hosted on port 3000. Nmap's service fingerprinting revealed several HTTP response headers that immediately stood out, including the presence of the `X-Powered-By: Next.js` header. This indicated that the application was built using the Next.js framework, a popular React-based web development platform. Additional headers such as `Vary: RSC` and `Next-Router-State-Tree` suggested that the application utilized React Server Components (RSC), a modern feature introduced in recent versions of Next.js.

The HTTP response also exposed several static resources located under the `/_next/static/` directory, further confirming the use of Next.js. Since modern JavaScript frameworks occasionally introduce unique attack surfaces and implementation-specific vulnerabilities, the web application became the primary focus of the assessment.

# Web Enumeration

Accessing the web application on port 3000 revealed a dashboard named **ReactorWatch**, a simulated nuclear reactor monitoring system displaying operational metrics.

![image.png](/assets/images/reactor/image.png)

To identify any hidden content or undisclosed endpoints, directory enumeration was performed using Gobuster.

```sql
kali:~/Documents/HTB/reactor$ gobuster dir -w /usr/share/wordlists/seclists/Discovery/Web-Content/raft-large-directories.txt -u http://$IP:3000/         
===============================================================
Gobuster v3.8.2
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@firefart)
===============================================================
[+] Url:                     http://10.129.103.19:3000/
[+] Method:                  GET
[+] Threads:                 10
[+] Wordlist:                /usr/share/wordlists/seclists/Discovery/Web-Content/raft-large-directories.txt
[+] Negative Status codes:   404
[+] User Agent:              gobuster/3.8.2
[+] Timeout:                 10s
===============================================================
Starting gobuster in directory enumeration mode
===============================================================
Progress: 62281 / 62281 (100.00%)
===============================================================
Finished
===============================================================

```

The scan completed successfully but did not reveal any additional directories or resources of interest.

The application exposed only a single dashboard page, and directory enumeration with Gobuster did not reveal any additional content. Since the target was identified as a Next.js application during the Nmap phase, further assessment focused on framework-specific attack surfaces. Unlike traditional web applications, modern React-based applications often rely on client-side routing and dynamically generated content, making conventional directory brute-forcing less effective.

## Next.js Framework Analysis

Since traditional web enumeration did not reveal any useful attack surface, attention shifted to the underlying Next.js framework identified during the Nmap reconnaissance phase. The presence of the `X-Powered-By: Next.js` header, along with React Server Component (RSC) related headers, suggested that the application might expose framework-specific attack vectors worthy of further investigation.

Reviewing the application source code revealed multiple references to Next.js static resources located under the `/_next/static/` directory, along with React Server Component (RSC) related functionality. The presence of headers such as `Vary: RSC` and `Next-Router-State-Tree` confirmed that the application was utilizing React Server Components and the React Flight protocol.

Research into recently disclosed vulnerabilities affecting React Server Components identified CVE-2025-55182, a remote code execution vulnerability impacting vulnerable Next.js deployments utilizing the React Flight protocol.

A publicly available proof-of-concept exploit was obtained and used to verify whether the target application was affected.

[GitHub - iksanwkk/CVE-2025-55182-exp: 🚨 Exploit CVE-2025-55182, a critical RCE vulnerability in React Server Components for Next.js apps; enables testing for prototype pollution risks.](https://github.com/iksanwkk/CVE-2025-55182-exp)

## Confirming the Vulnerability

The exploit was executed in verification mode to determine whether remote command execution was possible.

![image.png](/assets/images/reactor/image%201.png)

The exploit successfully confirmed command execution on the target system and reported the application as vulnerable.

## Obtaining Initial Access

A Netcat listener was started on the attacker's machine to receive an incoming connection. The public exploit was then used to trigger a reverse shell back to the attacker's host. Shortly after execution, a reverse shell connection was received, providing command execution on the target as the **node** user. With initial access established, local enumeration was performed to identify sensitive files, application data, and potential privilege escalation vectors.

![image.png](/assets/images/reactor/image%202.png)

## File system Enumeration & Database Analysis

After obtaining a reverse shell as the `node` user, local enumeration was performed to identify sensitive files within the application directory. The web application was located under `/opt/reactor-app`, where a SQLite database file named `reactor.db` was discovered. The `file` command confirmed that `reactor.db` was a valid SQLite database. The database was then opened using `sqlite3`.  After listing the available tables, three tables were identified: `sensors`, `logs`, and `users`.  The `users` table was queried to inspect stored user information.

![image.png](/assets/images/reactor/image%203.png)

The output revealed two user records, including an account for `engineer@reactor.htb`. The password value associated with this account appeared to be an MD5 hash. The extracted hash was submitted for cracking and successfully resolved to the plaintext password. 

![image.png](/assets/images/reactor/image%204.png)

These credentials provided a valid authentication path for the `engineer` user over SSH, which had already been identified as open during the initial Nmap scan.

## SSH Access to the Machine

The credentials recovered from the SQLite database were used to authenticate to the target over SSH.

![image.png](/assets/images/reactor/image%205.png)

After successfully logging in as the `engineer` user, access to the user flag was obtained.

With a stable SSH session established, the focus shifted toward privilege escalation and identifying potential misconfigurations that could provide elevated access.

# Privilege Escalation via Exposed Node.js Debugger

Process enumeration revealed an unusual Node.js process running as the `root` user with the debugger interface enabled.

![image.png](/assets/images/reactor/image%206.png)

The `--inspect` parameter indicated that the Node.js debugging service was listening locally on TCP port `9229`. Since the service was bound to the loopback interface (`127.0.0.1`), it was not accessible remotely but could be reached from the compromised host.

The debugger was accessed using the built-in Node.js inspector client. To verify the privilege level of the monitored process, JavaScript code was executed through the debugger.

The returned value was `0`, confirming that the target process was running with root privileges.

Next, arbitrary command execution was achieved by leveraging the `child_process` module. As proof of access, the root flag was read directly from the filesystem.

Since command execution was possible within the context of the root-owned Node.js process, a reverse shell payload was executed to obtain a fully interactive root shell.

![image.png](/assets/images/reactor/image%207.png)

After catching the connection with Netcat, a root shell was obtained. The privilege escalation path relied on an exposed Node.js debugging interface running as root. By connecting to the local debugger and executing arbitrary JavaScript, it was possible to achieve command execution as root and fully compromise the system.

# Key Takeaways

1. Framework fingerprinting can reveal attack paths that traditional directory enumeration misses.
2. React Server Components introduced a critical attack surface that led directly to remote code execution.
3. Sensitive application data should never be stored using weak hashing algorithms such as MD5.
4. Credentials recovered from application databases frequently enable lateral movement or privilege escalation.
5. Debugging interfaces such as Node.js Inspector should never be exposed on production systems, especially when running with elevated privileges.