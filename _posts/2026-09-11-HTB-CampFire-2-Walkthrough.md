---
layout: single
title: "Hack The Box Campfire-2 Sherlock Walkthrough: Investigating AS-REP Roasting"
date: 2026-09-11
author_profile: true
comments: true
share: true
categories: HTB-sherlocks
tags: []
header:
  overlay_image: /assets/images/CampFire-2/cover.png
  overlay_filter: 0.3  # optional, darkens the image for readability
  caption: "CampFire-2 Sherlock Walkthrough HackTheBox"
excerpt: "Hack The Box Campfire-2 Sherlock Walkthrough | Kerberoasting Detection with Windows Event Logs and Prefetch "
feature_row:
  - image_path: /assets/images/CampFire-2/cover.png
    alt: "CampFire-2 Sherlock Cover"
    title: "CampFire-2 Sherlock Walkthrough"
    excerpt: "A practical guide to solving the CampFire-2 sherlocks from HackTheBox."
    url: "#"
    btn_label: "Read More"
    btn_class: "btn--primary"
toc: true
toc_sticky: true
---
# CampFire-2

## Sherlock Scenario

Forela's Network is constantly under attack. The security system raised an alert about an old admin account requesting a ticket from KDC on a domain controller. Inventory shows that this user account is not used as of now so you are tasked to take a look at this. This may be an AsREP roasting attack as anyone can request any user's ticket which has preauthentication disabled.

# Evidence Extraction

The provided evidence was stored inside a password-protected archive named `campfire-2.zip`. We extracted the archive using **7-Zip. After entering the required password, the archive was successfully extracted without errors.** The extracted evidence contained the following Windows Event Log file: `Security.evtx` . 

![image.png](/assets/images/CampFire-2/image.png)

We then verified the extracted files using: `ll` . The directory now contained both the original archive and the extracted `Security.evtx` file. This Security log was used as the primary artifact for the Domain Controller investigation and subsequent Kerberos/AS-REP Roasting analysis.

# Domain Controller Analysis

We started the investigation by analyzing the Windows Security event log (`Security.evtx`) collected from the Domain Controller. Since EVTX files are not convenient to inspect and filter directly from the command line, we used Chainsaw to parse the log and export all events into JSON format. The output was saved as `all_event.json`, which allowed us to use `jq` later to filter specific Event IDs, usernames, IP addresses, and other relevant fields. At this stage, all events were retained so that the complete Domain Controller activity would remain available for later correlation.

![image.png](/assets/images/CampFire-2/image%201.png)

Chainsaw successfully processed the log and identified **152 events**.

After the conversion, we verified the generated files using: `ll` . The directory contained the original `Security.evtx` file and the newly generated `all_event.json` file. The JSON file was then used for further investigation of Kerberos-related events, including the AS-REP Roasting activity.

# Initial Kerberos Activity Review

At this stage, we reviewed the Domain Controller Security logs based on the alert described in the Sherlock scenario. The alert indicated that an old, currently unused admin account had requested a Kerberos ticket from the KDC, raising the possibility of an AS-REP Roasting attack. Since AS-REP Roasting targets accounts that have Kerberos pre-authentication disabled, we focused first on Kerberos TGT request activity in the Domain Controller logs.

Rather than inspecting all 152 events individually, we filtered for **Event ID 4768**, which is generated when a Kerberos Ticket Granting Ticket (TGT) is requested from the Domain Controller. We focused on this Event ID because AS-REP Roasting occurs during the Kerberos TGT request process when a user account does not require pre-authentication. We then displayed the most relevant fields in a single table so that all TGT requests could be compared at a glance.

```bash
jq -r '
["Time", "TargetUserName", "TargetSID", "IpAddress", "PreAuthType", "TicketEncryptionType"],
(
  .[] |
  select(.Event.System.EventID == 4768) |
  [
    .Event.System.TimeCreated_attributes.SystemTime,
    .Event.EventData.TargetUserName,
    .Event.EventData.TargetSid,
    .Event.EventData.IpAddress,
    .Event.EventData.PreAuthType,
    .Event.EventData.TicketEncryptionType
  ]
) | @tsv
' all_event.json | column -t -s $'\t'
```

![image.png](/assets/images/CampFire-2/image%202.png)

The command processes each event in `all_event.json` using `.[]` and uses `select()` to keep only Event ID `4768`, which represents Kerberos TGT requests. It then extracts the timestamp, target username, SID, source IP address, pre-authentication type, and ticket encryption type. The results are converted into tab-separated values using `@tsv`, while the final `column` command aligns them into a readable table. This allows all relevant TGT requests to be compared at a glance without manually reviewing every event.

In the output, most requests came from the local address `::1` and used `PreAuthType = 2`. However, the request for `arthur.kyle` came from `::ffff:172.17.79.129` and used `PreAuthType = 0`, making it clearly different from the surrounding Kerberos activity. The `::ffff:` prefix represents an IPv4 address in IPv6 format, so the actual source IPv4 address is `172.17.79.129`.

**`Question:`** When did the ASREP Roasting attack occur, and when did the attacker request the Kerberos ticket for the vulnerable user?

**`Analysis / Investigation:`**  Event ID 4768 was reviewed because it records Kerberos TGT requests. One request stood out from the surrounding activity: a TGT request was made for `arthur.kyle` from the source IP `172.17.79.129` with `PreAuthType = 0`, meaning Kerberos pre-authentication was not used. This behavior is consistent with the suspected AS-REP Roasting activity described in the scenario. The request occurred at **2024-05-29 06:36:40 UTC**.

**`Ans:`** 2024-05-29 06:36:40

**`Question:`** Please confirm the User Account that was targeted by the attacker.

**`Analysis / Investigation:`** The suspicious Event ID 4768 showed that the Kerberos TGT request was made for the account `arthur.kyle`. Since this request had `PreAuthType = 0`, `arthur.kyle` was identified as the account targeted by the AS-REP Roasting activity.

**`Ans:`** arthur.kyle

**`Question:`**  What was the SID of the account?

**`Analysis / Investigation:`** From the same Event ID **4768**, the `TargetSid` associated with **arthur.kyle** was identified as **S-1-5-21-3239415629-1862073780-2394361899-1601**.

**`Ans:`** S-1-5-21-3239415629-1862073780-2394361899-1601

**`Question:`** It is crucial to identify the compromised user account and the workstation responsible for this attack. Please list the internal IP address of the compromised asset to assist our threat-hunting team.

**`Analysis / Investigation:`** The suspicious Kerberos request for `arthur.kyle` originated from `::ffff:172.17.79.129`. The `::ffff:` prefix indicates an IPv4-mapped IPv6 address, so the actual internal IPv4 address of the source system is **172.17.79.129**. This IP was therefore used as the source workstation for further investigation.

**`Ans:`** 172.17.79.129

**`Question:`** We do not have any artifacts from the source machine yet. Using the same DC Security logs, can you confirm the user account used to perform the ASREP Roasting attack so we can contain the compromised account/s?

**`Analysis / Investigation:`** At this point, `arthur.kyle` had been identified as the **targeted account**, but this did not necessarily mean it was the account being used by the attacker. Since no artifacts from the source workstation were available, we used the known source IP `172.17.79.129` as a pivot and searched the DC Security logs for all other activity originating from the same system.

The following query searches the entire JSON dataset for events containing the source IP `172.17.79.129`. Here, `tostring` converts each event into searchable text, while `contains("172.17.79.129")` keeps only events where the source IP appears. Unlike the earlier query, we do not filter for a specific Event ID because the goal is now to identify and correlate **all activity** originating from the same source system around the time of the AS-REP Roasting event.

```bash
jq -r '
["Time", "EventID", "TargetUserName", "SubjectUserName", "IpAddress"],
(
  .[] |
  select(tostring | contains("172.17.79.129")) |
  [
    .Event.System.TimeCreated_attributes.SystemTime,
    .Event.System.EventID,
    .Event.EventData.TargetUserName,
    .Event.EventData.SubjectUserName,
    .Event.EventData.IpAddress
  ]
) | @tsv
' all_event.json | column -t -s $'\t'
```

![image.png](/assets/images/CampFire-2/image%203.png)

The correlated events show that shortly after the AS-REP request for `arthur.kyle`, the same source IP generated **Event ID 4769**, a Kerberos service-ticket request, associated with `happy.grunwald@FORELA.LOCAL`. This was followed by multiple **Event ID 5140** events, which record network-share access, under the user `happy.grunwald`. Because these activities originated from the same source IP `172.17.79.129` during the attack sequence, `happy.grunwald` was identified as the user account being used from the compromised workstation.

**`Ans:`** happy.grunwald