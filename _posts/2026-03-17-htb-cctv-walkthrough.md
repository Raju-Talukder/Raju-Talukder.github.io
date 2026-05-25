---
layout: single
title: "HackTheBox CCTV Walkthrough: Exploiting ZoneMinder SQL Injection and motionEye RCE for Root Access"
date: 2026-03-17
author_profile: true
comments: true
share: true
categories: HTB-Machine
tags: []
header:
  overlay_image: /assets/images/CCTV/cover.png
  overlay_filter: 0.3  # optional, darkens the image for readability
  caption: "HackTheBox CCTV Walkthrough: Exploiting ZoneMinder SQL Injection and motionEye RCE for Root Access"
excerpt: "HackTheBox CCTV Walkthrough: Exploiting ZoneMinder SQL Injection and motionEye RCE for Root Access"
feature_row:
  - image_path: /assets/images/CCTV/cover.png
    alt: "HackTheBox CCTV Walkthrough: Exploiting ZoneMinder SQL Injection and motionEye RCE for Root Access"
    title: "HackTheBox CCTV Walkthrough: Exploiting ZoneMinder SQL Injection and motionEye RCE for Root Access"
    excerpt: "A practical guide to solving the HTB CCTV machine."
    url: "#"
    btn_label: "Read More"
    btn_class: "btn--primary"
toc: true
toc_sticky: true
---

# CCTV


# Summary

This challenge demonstrates how multiple security weaknesses can be chained together to achieve full system compromise. Unchanged default credentials provided initial access to **ZoneMinder**, while a known **SQL injection vulnerability** enabled credential extraction. Post-exploitation enumeration revealed an internally exposed **motionEye** service, which was accessed through **SSH tunneling**. Finally, exploitation of a known **RCE vulnerability** in motionEye resulted in **root-level access**.

# Information Gathering

As always, I began with a full TCP port scan to identify exposed services on the target. The scan revealed only two open ports, indicating a relatively small attack surface. Based on the TTL values and service fingerprints, the system appears to be running a Unix/Linux-based operating system.

```bash
ports=$(nmap -p- --min-rate=1000 -T4 $IP | grep ^[0-9] | cut -d '/' -f 1 | tr '\n' ',' | sed s/,$//) ; nmap -p$ports -sC -vv -sV -oN nmap/service_scan $IP

PORT   STATE SERVICE REASON         VERSION
22/tcp open  ssh     syn-ack ttl 63 OpenSSH 9.6p1 Ubuntu 3ubuntu13.14 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   256 76:1d:73:98:fa:05:f7:0b:04:c2:3b:c4:7d:e6:db:4a (ECDSA)
|_ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBDZ15GCLPzC4gTM0nqzpUbr/2L77bM1C9sbBecivQPX/KcKvJrP88peCJXwTug7T/EORHr7M7JeHtMQJ6hYihFA=
80/tcp open  http    syn-ack ttl 63 Apache httpd 2.4.58
| http-methods: 
|_  Supported Methods: GET HEAD POST OPTIONS
|_http-title: Did not follow redirect to http://cctv.htb/
Service Info: Host: default; OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

The service running on port 22 is SSH (OpenSSH 9.6p1), which allows secure remote access to the system. However, since no valid credentials are available at this stage, it is not considered an immediate attack vector.

The web service on port 80 is powered by Apache and was observed to redirect requests to the domain `cctv.htb`, indicating the presence of a name-based virtual host. This suggests that the main web application is accessible only through the specified hostname rather than the direct IP address. To resolve this, we need to add the domain to the `/etc/hosts` file:

```sql
echo "10.129.244.156 cctv.htb" | sudo tee -a /etc/hosts
```

Once added, we can use the domain name instead of the IP address, and our browser and tools will automatically resolve it to the correct host.

To confirm that everything is working correctly, we can use the `ping` command:

![image.png](/assets/images/CCTV/image.png)

This verifies that the hostname resolves to the correct IP address. As shown above, the domain successfully resolves, confirming that the configuration is correct.

Based on these findings, the web application is the most promising entry point. Further enumeration will focus on analyzing the site, discovering hidden endpoints, and identifying potential vulnerabilities.

## Service Enumeration

After accessing the `cctv.htb` domain, I was presented with a **ZoneMinder** login page. Unfortunately, there wasn’t much information exposed on the page itself.

I attempted several enumeration techniques, including:

- Directory brute-forcing
- File discovery
- Subdomain enumeration

Additionally, I tested for **SQL authentication bypass techniques**, but none of these attempts were successful.

At this stage, it seemed like the application was fairly locked down from an external perspective.

![image.png](/assets/images/CCTV/image%201.png)

Since deeper enumeration didn’t yield any results, I decided to check for something simple but often overlooked “**default credentials”**. Given that the application is **ZoneMinder**, I searched for its default login credentials and found: `admin:admin` 

![image.png](/assets/images/CCTV/image%202.png)

Using these credentials, I attempted to log in and this time, it worked.  This confirmed that the system was running with **unchanged default credentials**, exposing the internal surveillance management interface to unauthorized access.

After gaining access to the **ZoneMinder dashboard**, we observed that the application discloses its version information: `v1.37.63`. This seemingly minor information disclosure significantly increases the attack surface, as it allows us to correlate the version with publicly known vulnerabilities.

![image.png](/assets/images/CCTV/image%203.png)

A simple Google search using the software name and version quickly identified a known SQL injection vulnerability associated with this version, tracked as **`CVE-2024-51482`**.

![image.png](/assets/images/CCTV/image%204.png)

For further details and to identify a working exploit, I searched using the CVE ID and located a publicly available PoC. However, the output from the PoC was not well structured, so I opted to use **SQLMap** for a more reliable and efficient exploitation process. Based on the CVE analysis, the following endpoint was identified as vulnerable: `http://cctv.htb/zm/index.php?view=r/equest&request=event&action=removetag&tid=1` The **`tid` parameter** is confirmed to be vulnerable.

![image.png](/assets/images/CCTV/image%205.png)

This vulnerability is an authenticated **time-based blind SQL injection**, which requires a valid session cookie for successful exploitation. As a prerequisite, I authenticated to the application using previously obtained credentials and extracted the session cookie to prepare the SQLMap payload.

![image.png](/assets/images/CCTV/image%206.png)

By exploiting the **`tid` parameter**, I was able to enumerate the database name and table structure. The final SQLMap command used for data extraction is shown below:

```sql
sqlmap -u "http://cctv.htb/zm/index.php?view=r/equest&request=event&action=removetag&tid=1" \
-D zm -T Users -C Username,Password \
--dump \
--batch \
--dbms=MySQL \
--technique=T \
--cookie="ZMSESSID=kh6sc6mf2j9jip3q76553qc754"
```

Since this is a time-based SQL injection, the exploitation process required a considerable amount of time to complete. Upon successful execution, three user credentials were extracted from the database. 

![image.png](/assets/images/CCTV/image%207.png)

# **Password Hash Cracking**

The **admin user’s password** is already known from the default ZoneMinder credentials identified earlier. The **`superadmin`** account appears to be the primary web application administrator. However, the **`mark`** user stands out as potentially more interesting for further investigation.

![image.png](/assets/images/CCTV/image%208.png)

User `mark` password hash has been identified as `bycrypt Blowfish` encrypted hash. For hashcat tools the hash mode is is `3200`. To decrypt the hash we can use this following command.

```sql
hashcat -m 3200 hash.txt /usr/share/wordlists/rockyou.txt
```

The password hash was successfully cracked using the `rockyou.txt` password file located at `/usr/share/wordlists/rockyou.txt`.

![image.png](/assets/images/CCTV/image%209.png)

# Initial Access via SSH

The recovered credentials were reused against SSH authentication. Authentication succeeded, resulting in shell access as user `mark`.

![image.png](/assets/images/CCTV/image%2010.png)

# Post Exploitation Enumeration

Enumeration of internal network services revealed several actively listening ports on the system. Among them, port **8765** stood out as an interesting target and warranted further investigation into the underlying service.

![image.png](/assets/images/CCTV/image%2011.png)

Further analysis of the service running on port **8765** was performed using a `curl` request to inspect the HTTP response headers, which revealed the application name and version: **motionEye/0.43.1b4**.

![image.png](/assets/images/CCTV/image%2012.png)

After confirming the application name, attention shifted toward identifying potentially sensitive configuration files, as they often contain credentials or other useful information. During this process, several application configuration files were identified.

![image.png](/assets/images/CCTV/image%2013.png)

Analysis of the `motion.conf` file revealed valid administrative credentials stored within the application configuration. These credentials provided a potential path for accessing the internal **motionEye** application.

![image.png](/assets/images/CCTV/image%2014.png)

# SSH Tunneling

Based on the local port enumeration results, **motionEye** was configured to listen only on the loopback interface (`127.0.0.1`), meaning the application was accessible only locally and could not be reached directly from an external system. To access the internal application from the attacker machine, SSH port forwarding was configured using the credentials previously obtained for the `mark` user.

```sql
ssh -L 9000:127.0.0.1:8765 mark@cctv.htb
```

![image.png](/assets/images/CCTV/image%2015.png)

After establishing the SSH tunnel successfully, the internal service became accessible from the attacker machine through local port **9000**. Browsing to `http://127.0.0.1:9000` presented an authentication page. Previously recovered credentials from the configuration file were then used to authenticate to the application.

![image.png](/assets/images/CCTV/image%2016.png)

![image.png](/assets/images/CCTV/image%2017.png)

# Privilege Escaltion via motionEye RCE vulnerability

Further research into **motionEye v0.43.1b4** revealed that the application is affected by a known **authenticated Remote Code Execution (RCE)** vulnerability tracked as **CVE-2025-60787**. Public exploit information was available, including an exploit published on **Exploit-DB**, confirming that the installed version was vulnerable.

![image.png](/assets/images/CCTV/image%2018.png)

To better understand the vulnerability and obtain a working proof-of-concept, additional research was conducted using the CVE identifier. This led to the discovery of a publicly available Python exploit hosted on GitHub. The exploit targets an authenticated vulnerability in **motionEye**, allowing arbitrary command execution on the target system. Since valid credentials had already been obtained during earlier enumeration, the exploit could be used directly against the application.

![image.png](/assets/images/CCTV/image%2019.png)

![image.png](/assets/images/CCTV/image%2020.png)

The proof-of-concept exploit was downloaded and executed against the target application. Simultaneously, a Netcat listener was configured on port **9001** to receive the incoming reverse shell connection. Upon successful execution of the exploit, the payload was injected successfully and a reverse shell connection was established from the target system. The shell was received with **root** privileges, resulting in complete compromise of the target machine.

![image.png](/assets/images/CCTV/image%2021.png)

Verification of the current user context confirmed that code execution had been obtained with **root** privileges. The output confirms that the shell is running with `uid=0`, indicating full administrative access to the target system.

![image.png](/assets/images/CCTV/image%2022.png)

# Lessons Learned

- **Default Credentials Exposure:** The **ZoneMinder** application was deployed with unchanged default credentials (`admin:admin`), allowing unauthorized access to the administrative interface.
- **Version Information Disclosure:** Exposed application versions enabled identification of publicly known vulnerabilities and accelerated the attack process.
- **Authenticated SQL Injection:** **CVE-2024-51482** allowed database enumeration and credential extraction through the vulnerable `tid` parameter.
- **Credential Reuse Across Services:** Credentials recovered during exploitation could be reused across different services, enabling attackers to pivot and gain additional access.
- **Sensitive Information in Configuration Files:** The `motion.conf` file contained valid application credentials, demonstrating the risks of storing sensitive information within configuration files.
- **SSH Tunneling and Pivoting:** SSH port forwarding enabled access to the internally restricted **motionEye** service, demonstrating how tunneling can be used to access otherwise unreachable internal resources.
- **Outdated Software Risks:** **motionEye v0.43.1b4** contained a known **RCE** vulnerability that ultimately resulted in **root-level access**.