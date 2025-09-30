---
layout: single
title: "Step-by-step walkthrough of the PhisNet Sherlock from HTB"
date: 2025-09-30
author_profile: true
comments: true
share: true
categories: HTB-sherlocks
tags: []
header:
  overlay_image: /assets/images/phisnet/cover.png
  overlay_filter: 0.3  # optional, darkens the image for readability
  caption: "PhisNet Sherlock Walkthrough"
excerpt: "Step-by-step walkthrough of the PhisNet Sherlock from HTB."
feature_row:
  - image_path: /assets/images/phisnet/cover.png
    alt: "PhisNet Sherlock Cover"
    title: "PhisNet Sherlock Walkthrough"
    excerpt: "A practical guide to solving the PhisNet sherlocks."
    url: "#"
    btn_label: "Read More"
    btn_class: "btn--primary"
toc: true
toc_sticky: true
---
# PhishNet

## Sherlock Scenario
An accounting team receives an urgent payment request from a known vendor. The email appears legitimate but contains a suspicious link and a .zip attachment hiding malware. Your task is to analyze the email headers, and uncover the attacker's scheme.

We can analyze emails using many automated tools, but I prefer to practice the manual way when solving this Sherlock.

## Summary Workflow:
Open safely → Check headers → Inspect body/links → Analyze attachments → Threat intel enrichment → Map to MITRE → Document & report.

## `Question` What is the originating IP address of the sender?

`Solution` **`X-Originating-IP`** records the sender’s real client IP and is the most reliable indicator of the true source. **`X-Sender-IP`** is non-standard, may be added by mail servers, and often matches X-Originating-IP but can also show an intermediate server’s IP.

![](/assets/images/phisnet/image.png)

`Ans` 45.67.89.10

## `Question` Which mail server relayed this email before reaching the victim?

`Solution` Email headers add `Received` lines in reverse order. The top-most `Received` line shows the last server that handed the mail to the victim. Here it is: “Received: from mail.business-finance.com ([203.0.113.25])”

![](/assets/images/phisnet/image1.png)

`Ans` 203.0.113.25

## `Question` What is the sender's email address?

`Solution` The header clearly shows the `Form:` field as: “From: "Finance Dept" finance@business-finance.com” So the sender’s email address is **finance@business-finance.com.**

![](/assets/images/phisnet/image2.png)

`Ans` finance@business-finance.com

## `Question` What is the 'Reply-To' email address specified in the email?

`Solution` We can extract this from the request header information.

![](/assets/images/phisnet/image3.png)

`Ans` support@business-finance.com

## `Question` What is the SPF (Sender Policy Framework) result for this email?

`Solution` We can extract this from the request header information. As we can see the value of this tag is `pass`.

![](/assets/images/phisnet/image4.png)

`Ans` Pass

## `Question` What is the domain used in the phishing URL inside the email?

`Solution` We extracted all the URLs from the file and only one URL appear. 
```code
grep -Eo 'https?://[^ >"]+' email.eml || echo "no http/https URL found"
```

![](/assets/images/phisnet/image5.png)

`Ans` [secure.business-finance.com](http://secure.business-finance.com/)

## `Question` What is the fake company name used in the email?

`Solution` From the email body we got the company name.

![](/assets/images/phisnet/image6.png)

`Ans` Business Finance Ltd.

## `Question` What is the name of the attachment included in the email?

`Solution` There are multiple ways to extract the attachment from email. In this case i found `ripmime` tools useful. We ectracted the attachments inside a folder called “extracted”.
```code
ripmime -i email.eml -d extracted
```

![](/assets/images/phisnet/image7.png)

`Ans` Invoice_2025_Payment.zip

## `Question` What is the SHA-256 hash of the attachment?

`Solution` We can generate a file hash using different methods in this case i used `sha256sum` binay to generate the hash information.

![](/assets/images/phisnet/image8.png)

`Ans` 8379C41239E9AF845B2AB6C27A7509AE8804D7D73E455C800A551B22BA25BB4A

## `Question` What is the filename of the malicious file contained within the ZIP attachment?

`Solution` While unziping the file it was giivng error with all kind of tools. in `7z` tool there is a option forecfully list included items in a zip file. 

![](/assets/images/phisnet/image9.png)

`Ans` invoice_document.pdf.bat

## `Question` Which MITRE ATT&CK techniques are associated with this attack?

`Solution` Visit the MITRE ATT&CK technique inside the phishing there will be all four sub-techniques available and its a Spearphishing service attack.

![](/assets/images/phisnet/image10.png)

`Ans` T1566.001