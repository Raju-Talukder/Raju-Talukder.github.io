---
layout: single
title: "Hack The Box Noxious Sherlock Walkthrough: LLMNR Poisoning, Responder & NetNTLMv2 Analysis"
date: 2026-09-15
author_profile: true
comments: true
share: true
categories: HTB-sherlocks
tags: []
header:
  overlay_image: /assets/images/noxious/cover.png
  overlay_filter: 0.3  # optional, darkens the image for readability
  caption: "noxious Sherlock Walkthrough HackTheBox"
excerpt: "Hack The Box noxious Sherlock Walkthrough | Kerberoasting Detection with Windows Event Logs and Prefetch "
feature_row:
  - image_path: /assets/images/noxious/cover.png
    alt: "noxious Sherlock Cover"
    title: "noxious Sherlock Walkthrough"
    excerpt: "A practical guide to solving the noxious sherlocks from HackTheBox."
    url: "#"
    btn_label: "Read More"
    btn_class: "btn--primary"
toc: true
toc_sticky: true
---

# Noxious

## Sherlock Scenario

The IDS device alerted us to a possible rogue device in the internal Active Directory network. The Intrusion Detection System also indicated signs of LLMNR traffic, which is unusual. It is suspected that an LLMNR poisoning attack occurred. The LLMNR traffic was directed towards Forela-WKstn002, which has the IP address 172.17.79.136. A limited packet capture from the surrounding time is provided to you, our Network Forensics expert. Since this occurred in the Active Directory VLAN, it is suggested that we perform network threat hunting with the Active Directory attack vector in mind, specifically focusing on LLMNR poisoning.

# Evidence Extraction

![image.png](/assets/images/noxious/image.png)

**`Question:`** Its suspected by the security team that there was a rogue device in Forela's internal network running responder tool to perform an LLMNR Poisoning attack. Please find the malicious IP Address of the machine

**`Analysis / Investigation:`**  The packet capture was filtered for NTLMSSP traffic to examine the NTLM authentication sequence. The NTLMSSP_CHALLENGE packet immediately preceding the victim's first NTLMSSP_AUTH request was selected. Within the SMB2 Session Setup Response, the NTLM Secure Service Provider details revealed the server challenge value 601019d191f054f1. This server challenge must be paired with the NTProofStr and NTLMv2 blob from the corresponding NTLMSSP_AUTH message to reconstruct the captured NetNTLMv2 authentication material.

![image.png](/assets/images/noxious/image%201.png)

**`Ans:`** 172.17.79.135

**`Question:`** What is the hostname of the rogue machine?

**`Analysis / Investigation:`** After identifying `172.17.79.135` as the rogue host, its MAC address was obtained from the Ethernet header and used to correlate its DHCP traffic. A DHCP Discover packet originating from the same device was examined, and DHCP Option 12 revealed the host name of the machine. Therefore, the value contained in the DHCP Host Name option was identified as the hostname of the rogue device.

![image.png](/assets/images/noxious/image%202.png)

![image.png](/assets/images/noxious/image%203.png)

**`Ans:`**  kali

**`Question:`**  Now we need to confirm whether the attacker captured the user's hash and it is crackable!! What is the username whose hash was captured?

**`Analysis / Investigation:`**  The packet capture was filtered using: `tcp contains "NTLMSSP"` .

![image.png](/assets/images/noxious/image%204.png)

Multiple SMB2 authentication attempts containing NTLMSSP_AUTH messages were identified. Upon inspecting the authentication traffic, the packet details revealed the domain FORELA, the username john.deacon, the workstation FORELA-WKSTN002, and an NTLM authentication response. This confirms that john.deacon's NetNTLMv2 challenge-response authentication material was transmitted to the rogue host during the SMB authentication attempt.

**`Ans:`** john.deacon

**`Question:`** IIn NTLM traffic we can see that the victim credentials were relayed multiple times to the attacker's machine. When were the hashes captured the First time?

**`Analysis / Investigation:` The packet capture was filtered using the following Wireshark display filter to isolate NTLM authentication attempts associated with the compromised user: `ntlmssp.auth.username == "john.deacon"`**

![image.png](/assets/images/noxious/image%205.png)

Multiple NTLMSSP_AUTH SMB2 Session Setup requests were observed from the victim host to the rogue machine, showing that the victim's NTLM authentication material was transmitted multiple times. By reviewing the packets in chronological order, the earliest authentication attempt was identified at 2024-06-24 11:18:30.922052Z. Therefore, the first NetNTLMv2 authentication response was captured at approximately 2024-06-24 11:18:30 UTC.

**`Ans:`** 2024-06-24 11:18:30

**`Question:`** What was the typo made by the victim when navigating to the file share that caused his credentials to be leaked?

**`Analysis / Investigation:`** First, the packet capture was filtered for **LLMNR traffic**. The victim host `172.17.79.136` was observed repeatedly querying for the hostname `DCC01`, while the rogue host `172.17.79.135` responded to those requests and resolved `DCC01` to its own IP address. This shows that the mistyped hostname triggered LLMNR name resolution.

![image.png](/assets/images/noxious/image%206.png)

Next, the victim’s SMB2 traffic was analyzed using the filter `ip.src == 172.17.79.136 && smb2`. The victim was observed accessing the legitimate server `DC01`, including the shares `\\DC01\IPC$` and `\\DC01\DC-Confidential`. This confirms that the intended hostname was `DC01`.

![image.png](/assets/images/noxious/image%207.png)

Comparing the LLMNR query `DCC01` with the legitimate SMB hostname `DC01` confirms that the victim accidentally added an extra **`C`**. This typo caused the failed name resolution and allowed the rogue Responder host to answer the LLMNR request.

**`Ans:`** DCC01

**`Question:`** To get the actual credentials of the victim user we need to stitch together multiple values from the ntlm negotiation packets. What is the NTLM server challenge value?

**`Analysis / Investigation:`** The packet capture was filtered for `ntlmssp` traffic to examine the NTLM authentication sequence. The `NTLMSSP_CHALLENGE` packet immediately preceding the victim's first `NTLMSSP_AUTH` request was selected. Within the SMB2 Session Setup Response, the NTLM Secure Service Provider details revealed the server challenge value **`601019d191f054f1`**. This challenge forms part of the NetNTLMv2 challenge-response data required to reconstruct the captured credential material.

![image.png](/assets/images/noxious/image%208.png)

**`Ans:`** 601019d191f054f1

**`Question:`** Now doing something similar find the NTProofStr value.

**`Analysis / Investigation:`** First, filter the NTLM authentication traffic associated with the compromised user: `ntlmssp.auth.username == "john.deacon"` . This displays the **NTLMSSP_AUTH SMB2 Session Setup Requests** generated for the `john.deacon` account.

Select the NTLMSSP_AUTH packet corresponding to the same authentication exchange from which the server challenge was obtained. This ensures that the server challenge, NTProofStr, and NTLMv2 blob all belong to the same NTLM authentication sequence.

```
NTLM Secure Service Provider
└── NTLM Response
    └── NTLMv2 Response
        └── NTProofStr
```

Within the corresponding NTLMv2 response structure, Wireshark identifies the following NTProofStr value: `c0cc803a6d9fb5a9082253a04dbd4cd4`

![image.png](/assets/images/noxious/image%209.png)

**`Ans:`** c0cc803a6d9fb5a9082253a04dbd4cd4

**`Question:`** To test the password complexity, try recovering the password from the information found from packet capture. This is a crucial step as this way we can find whether the attacker was able to crack this and how quickly.

**`Analysis / Investigation:`** 

The packet capture was filtered using `ntlmssp.auth.username == "john.deacon"` to identify NTLM authentication attempts associated with john.deacon. The SMB2 Session Setup traffic contained the NTLM authentication exchange, including the server challenge and the client's NetNTLMv2 response. These values were extracted from the same authentication sequence to reconstruct the captured authentication material. 

For **Hashcat mode 5600 (NetNTLMv2)**, the captured values must be arranged in the following format: `USERNAME::DOMAIN:SERVER_CHALLENGE:NT_PROOF_STRING:NTLMv2_BLOB` 

The required values had already been identified during the previous investigation tasks, so those values were reused to construct the Hashcat-compatible NetNTLMv2 hash:

```bash
User name: john.deacon
Domain name: FORELA
SERVER_CHALLENGE: 601019d191f054f1
NT_PROOF_STRING: c0cc803a6d9fb5a9082253a04dbd4cd4
NTLMv2_BLOB: 010100000000000080e4d59406c6da01cc3dcfc0de9b5f2600000000020008004e0042004600590001001e00570049004e002d00360036004100530035004c003100470052005700540004003400570049004e002d00360036004100530035004c00310047005200570054002e004e004200460059002e004c004f00430041004c00030014004e004200460059002e004c004f00430041004c00050014004e004200460059002e004c004f00430041004c000700080080e4d59406c6da0106000400020000000800300030000000000000000000000000200000eb2ecbc5200a40b89ad5831abf821f4f20a2c7f352283a35600377e1f294f1c90a001000000000000000000000000000000000000900140063006900660073002f00440043004300300031000000000000000000
```

These values were then placed into the required Hashcat format:

```bash
john.deacon::FORELA:601019d191f054f1:c0cc803a6d9fb5a9082253a04dbd4cd4:010100000000000080e4d59406c6da01cc3dcfc0de9b5f2600000000020008004e0042004600590001001e00570049004e002d00360036004100530035004c003100470052005700540004003400570049004e002d00360036004100530035004c00310047005200570054002e004e004200460059002e004c004f00430041004c00030014004e004200460059002e004c004f00430041004c00050014004e004200460059002e004c004f00430041004c000700080080e4d59406c6da0106000400020000000800300030000000000000000000000000200000eb2ecbc5200a40b89ad5831abf821f4f20a2c7f352283a35600377e1f294f1c90a001000000000000000000000000000000000000900140063006900660073002f00440043004300300031000000000000000000
```

The structure can be understood as:

```bash
john.deacon :: FORELA : 601019d191f054f1 : c0cc803a6d9fb5a9082253a04dbd4cd4 : 010100000000000080e4d59406c6da01cc3dcfc0de9b5f2600000000020008004e0042004600590001001e00570049004e002d00360036004100530035004c003100470052005700540004003400570049004e002d00360036004100530035004c00310047005200570054002e004e004200460059002e004c004f00430041004c00030014004e004200460059002e004c004f00430041004c00050014004e004200460059002e004c004f00430041004c000700080080e4d59406c6da0106000400020000000800300030000000000000000000000000200000eb2ecbc5200a40b89ad5831abf821f4f20a2c7f352283a35600377e1f294f1c90a001000000000000000000000000000000000000900140063006900660073002f00440043004300300031000000000000000000
     │           │           │                         │                         │
     │           │           │                         │                         └─ NTLMv2 Blob
     │           │           │                         └─ NT Proof String
     │           │           └─ Server Challenge
     │           └─ Domain
     └─ Username
```

> The spaces above are only used to make the structure easier to understand. The actual hash supplied to Hashcat must not contain those spaces.
> 

The generated NetNTLMv2 hash was saved to the `hash` file and tested using **Hashcat mode 5600**. After the cracking process, the recovered credential was displayed using:

![image.png](/assets/images/noxious/image%2010.png)

The output confirmed that the captured NetNTLMv2 authentication material was successfully cracked, revealing the password associated with john.deacon. This demonstrates that the captured credential material was crackable using the tested wordlist and Hashcat mode 5600. 

**`Ans:`** NotMyPassword0k?

**`Question:`** Just to get more context surrounding the incident, what is the actual file share that the victim was trying to navigate to

**`Analysis / Investigation:`** We can identify the requested file share in **two different ways**.

**`Option 1 – Using Wireshark`** 

Filter the SMB2 traffic originating from the victim host: `ip.src == 172.17.79.136 && smb2` . Reviewing the SMB2 traffic shows that the victim first connects to `\\DC01\IPC$` and sends a **NetShareEnumAll** request to enumerate the available network shares.

Shortly afterward, an **SMB2 Tree Connect Request** appears for: `\\DC01\DC-Confidential` . This reveals the actual file share the victim was attempting to access.

![image.png](/assets/images/noxious/image%207.png)

#### **`Option 2 – Using TShark`**

Instead of manually reviewing the packets in Wireshark, we can filter the **SMB2 Tree Connect requests** directly from the command line:

```bash
tshark -r capture.pcap \
-Y "ip.src == 172.17.79.136 && smb2.cmd == 3" \
-T fields \
-e frame.number \
-e ip.src \
-e ip.dst \
-e _ws.col.Info
```

Here, `smb2.cmd == 3` filters for **SMB2 Tree Connect** operations. The output directly reveals the requested share: `\\DC01\DC-Confidential` .

![image.png](/assets/images/noxious/image%2011.png)

**`Ans:`** \\DC01\DC-Confidential
