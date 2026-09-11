---
layout: single
title: "Hack The Box Campfire-1 Sherlock Walkthrough | Kerberoasting Detection with Windows Event Logs and Prefetch "
date: 2026-09-11
author_profile: true
comments: true
share: true
categories: HTB-sherlocks
tags: []
header:
  overlay_image: /assets/images/CampFire-1/cover.png
  overlay_filter: 0.3  # optional, darkens the image for readability
  caption: "CampFire-1 Sherlock Walkthrough HackTheBox"
excerpt: "Hack The Box Campfire-1 Sherlock Walkthrough | Kerberoasting Detection with Windows Event Logs and Prefetch "
feature_row:
  - image_path: /assets/images/CampFire-1/cover.png
    alt: "CampFire-1 Sherlock Cover"
    title: "CampFire-1 Sherlock Walkthrough"
    excerpt: "A practical guide to solving the CampFire-1 sherlocks from HackTheBox."
    url: "#"
    btn_label: "Read More"
    btn_class: "btn--primary"
toc: true
toc_sticky: true
---

# CampFire-1

## Sherlock Scenario

Alonzo Spotted Weird files on his computer and informed the newly assembled SOC Team. Assessing the situation it is believed a Kerberoasting attack may have occurred in the network. It is your job to confirm the findings by analyzing the provided evidence.

You are provided with:

1- Security Logs from the Domain Controller

2- PowerShell-Operational Logs from the affected workstation

3- Prefetch Files from the affected workstation

# Evidence Extraction

The downloaded archive was password-protected, so I extracted it using `7z` . After entering the provided password, the archive was successfully extracted. The extracted evidence was stored inside the `Triage` directory.

![image.png](/assets/images/CampFire-1/image.png)

The investigation was then divided into two main phases. First, the **Domain Controller Security logs** were analyzed to identify the Kerberoasting activity. After identifying the affected workstation, the **PowerShell logs and Prefetch artifacts** from that endpoint were examined to understand how the attack was performed.

# Domain Controller Analysis

The Domain Controller evidence contained the `SECURITY-DC.evtx` Security log. To make the Windows Event Log easier to analyze, I used **Chainsaw** to parse the `.evtx` file and export all events into JSON format. 

![image.png](/assets/images/CampFire-1/image%201.png)

Chainsaw successfully processed the Security log and generated `all_events.json` file. This JSON file was then analyzed with `jq` to filter specific Windows events and extract the fields relevant to the investigation.

**`Question:`** Analyzing Domain Controller Security Logs, can you confirm the UTC date & time when the kerberoasting activity occurred?

**`Analysis / Investigation:`**  To identify potential Kerberoasting activity, the Domain Controller’s Security log was examined for **Event ID 4769**, which records **Kerberos Service Ticket (TGS) requests**.

Kerberoasting typically involves requesting service tickets for service accounts, and tickets encrypted with **RC4-HMAC** are an important indicator during such investigations. In Windows Event Logs, RC4-HMAC is represented by the encryption type **`0x17`**.

Therefore, the `all_events.json` file was first filtered for **Event ID 4769**, and then further narrowed down to events where the `TicketEncryptionType` was **`0x17`**. This allowed the suspicious Kerberos ticket request associated with the Kerberoasting activity to be identified.

```bash
jq -r '.[] | select(.Event.System.EventID == 4769) | select(.Event.EventData.TicketEncryptionType == "0x17") | .Event.System.TimeCreated_attributes.SystemTime' all_events.json
```

**`Ans:`** 2024-05-21 03:18:09

**`Question:`** What is the Service Name that was targeted?

**`Analysis / Investigation:`** To identify the **Service Name targeted during the Kerberoasting activity**, the same suspicious Kerberos event was examined. Previously, we extracted the **creation time** of the event to determine when the activity occurred. This time, we extracted the **ServiceName** field instead. The filtering criteria remain the same; only the field being displayed is different.

```bash
jq -r '.[] | select(.Event.System.EventID == 4769) | select(.Event.EventData.TicketEncryptionType == "0x17") | .Event.EventData.ServiceName' all_events.json
```

**`Ans:`** MSSQLService

**`Question:`**  It is really important to identify the Workstation from which this activity occurred. What is the IP Address of the workstation?

**`Analysis / Investigation:`** To identify the **IP address of the workstation from which the Kerberoasting activity originated**, the same suspicious Kerberos event was examined again. Previously, we extracted fields such as the **creation time** and **Service Name** from this event. This time, we extracted the **IpAddress** field.

The filtering criteria remain unchanged: **Event ID 4769** is used to identify Kerberos Service Ticket requests, and `TicketEncryptionType` **`0x17`** is used to isolate the suspicious RC4-HMAC ticket request. The only difference is that the `IpAddress` field is displayed to determine the source workstation involved in the activity.

```bash
jq -r '.[] | select(.Event.System.EventID == 4769) | select(.Event.EventData.TicketEncryptionType == "0x17") | .Event.EventData.IpAddress' all_events.json
```

**`Ans:`** 172.17.79.129

# Workstation Analysis

After identifying the source workstation as **172.17.79.129**, the investigation moved from the Domain Controller to the endpoint artifacts. The provided workstation triage contains both **PowerShell Operational logs** and **Prefetch files**, which can help reconstruct how the Kerberoasting activity was carried out.

To begin the endpoint investigation, the PowerShell Operational log was parsed with Chainsaw and exported to JSON:

![image.png](/assets/images/CampFire-1/image%202.png)

This produced `powershell.json`, allowing the PowerShell events to be searched and filtered more easily using `jq`.

**`Question:`** Now that we have identified the workstation, a triage including PowerShell logs and Prefetch files are provided to you for some deeper insights so we can understand how this activity occurred on the endpoint. What is the name of the file used to Enumerate Active directory objects and possibly find Kerberoastable accounts in the network?

**`Analysis / Investigation:`** After identifying the affected workstation, the investigation moved to the **PowerShell Operational logs** to determine which script had been used for Active Directory enumeration.

Since the exact script name was not known beforehand, all available `Path` values were extracted from the PowerShell events using the following command:

```bash
jq -r '.[] | .Event.EventData.Path? // empty' powershell.json | sort -u
```

The `.Event.EventData.Path` field contains the path of a PowerShell script when that information is recorded in the event. The `// empty` portion ignores events where no path is present, while `sort -u` removes duplicate entries and displays only unique script paths.

The output revealed the script `powerview.ps1`. PowerView is a PowerShell-based Active Directory reconnaissance tool that can be used to enumerate domain objects, users, groups, computers, and service accounts. It can also help identify accounts associated with Service Principal Names (SPNs), which may be targeted during Kerberoasting.

**`Ans:`** powerview.ps1

**`Question:`**  When was this script executed? (UTC)

**`Analysis / Investigation:`** After identifying `powerview.ps1` as the script used for Active Directory enumeration, the next step was to determine **when it was executed**.

The same PowerShell Operational log was filtered for Event ID 4104 records PowerShell Script Block Logging events, providing visibility into PowerShell code that was executed. The `SystemTime` associated with the matching `powerview.ps1` event was extracted to determine when the script activity was recorded.

```bash
jq -r '.[] | select(.Event.System.EventID == 4104) | select((.Event.EventData.Path // "") | ascii_downcase | contains("powerview.ps1")) | .Event.System.TimeCreated_attributes.SystemTime' powershell.json | sort -u
```

Here, `EventID == 4104` isolates PowerShell script block events, while the second filter ensures that only events related to `powerview.ps1` are selected. Finally, `SystemTime` provides the execution timestamp recorded in the event log.

**`Ans:`** 2024-05-21 03:16:32

**`Question:`** What is the full path of the tool used to perform the actual kerberoasting attack?

**`Analysis / Investigation:`** After identifying `powerview.ps1` as the script used for Active Directory enumeration, the investigation moved to the **Prefetch files** collected from the affected workstation to determine which executable was used to perform the actual Kerberoasting attack.

Windows Prefetch files are created when applications are executed and can provide useful forensic evidence such as the **executable name, execution timestamps, and files or paths referenced by the program**.

While reviewing the available Prefetch artifacts, the following file stood out: [`RUBEUS.EXE-5873E24B.pf`]. The presence of the `RUBEUS.EXE-5873E24B.pf` Prefetch artifact provides strong evidence that `RUBEUS.EXE` was executed on the workstation. This was significant because **Rubeus** is a well-known Windows tool for interacting with and abusing Kerberos authentication, including performing Kerberoasting operations. Therefore, this Prefetch file became the primary artifact for identifying the tool used in the attack.

The `sccainfo` utility was then used to parse the Prefetch file, and the output was filtered for references to `RUBEUS`:

```bash
sccainfo RUBEUS.EXE-5873E24B.pf | grep -i "RUBEUS"
```

The parsed Prefetch data revealed the executable's full path: `C:\Users\Alonzo.spire\Downloads\Rubeus.exe` This confirms that `Rubeus.exe` was present in the user's Downloads directory and was executed on the affected workstation, making it consistent with the tool used to perform the Kerberoasting activity.

**`Ans:`** C:\Users\Alonzo.spire\Downloads\Rubeus.exe

**`Question:`** When was the tool executed to dump credentials? (UTC)

**`Analysis / Investigation:`** After identifying `Rubeus.exe` as the tool used to perform the Kerberoasting attack, the next step was to determine **when it was executed** on the affected workstation.

Since Windows Prefetch files record application execution information, the same `RUBEUS.EXE-5873E24B.pf` artifact was analyzed again. This time, instead of looking for the executable path, the output was filtered for the **run time** information:

```bash
sccainfo RUBEUS.EXE-5873E24B.pf | grep -i "run time"
```

The Prefetch data showed the execution timestamp for `Rubeus.exe` as: `2024-05-21 03:18:08` This timestamp closely aligns with the Kerberos service ticket request observed on the Domain Controller at approximately `03:18:09 UTC`, providing additional correlation between the endpoint activity and the Kerberoasting event.

**`Ans:`** 2024-05-21 03:18:08