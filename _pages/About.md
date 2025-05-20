---
title: "About Me"
permalink: /about/
layout: single
author_profile: true
toc: true
toc_sticky: true
header:
  overlay_color: "#000"
  overlay_filter: "0.5"
  overlay_image: https://images.pexels.com/photos/3184291/pexels-photo-3184291.jpeg
---

<style>
  h2 {
    color: #00bcd4 !important;
  }
  .skills-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    grid-gap: 2rem;
    margin-top: 2rem;
  }
  .skill-tag {
    background-color: #333;
    color: #eee;
    padding: 0.4rem 0.8rem;
    margin: 0.2rem;
    border-radius: 1.5rem;
    font-size: 0.85rem;
    display: inline-block;
  }
  .resume-button {
    display: inline-block;
    margin-top: 1.5rem;
    padding: 0.6rem 1.2rem;
    background-color: #00bcd4;
    color: white;
    border-radius: 5px;
    text-decoration: none;
    font-weight: bold;
    transition: background-color 0.3s ease;
  }
  .resume-button:hover {
    background-color: #0097a7;
  }
  .certifications-container {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 1.5rem;
    margin-top: 1.5rem;
  }

  .cert-card {
    display: flex;
    align-items: center;
    gap: 1rem;
    background: rgba(255, 255, 255, 0.05);
    padding: 1rem;
    border-radius: 10px;
    transition: all 0.3s ease-in-out;
    box-shadow: 0 0 0 transparent;
  }

  .cert-card:hover {
    transform: scale(1.02);
    background: rgba(0, 191, 255, 0.1);
    box-shadow: 0 0 10px rgba(0, 191, 255, 0.2);
  }

  .cert-logo {
    width: 48px;
    height: 48px;
    background: white;
    border-radius: 8px;
    padding: 6px;
    display: flex;
    justify-content: center;
    align-items: center;
  }

  .cert-name {
    font-size: 1rem;
    font-weight: 600;
    color: #eee;
  }

  @media (max-width: 500px) {
    .cert-card {
      flex-direction: column;
      align-items: flex-start;
    }

    .cert-logo {
      margin-bottom: 0.5rem;
    }
  }

  .publication-container {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
  gap: 1.5rem;
  margin-top: 1.5rem;
}

.pub-card {
  background: rgba(255, 255, 255, 0.05);
  padding: 1.2rem;
  border-radius: 10px;
  color: #ccc;
  transition: transform 0.3s ease, background-color 0.3s ease;
  box-shadow: 0 0 0 transparent;
}

.pub-card:hover {
  background-color: rgba(0, 191, 255, 0.1);
  transform: scale(1.02);
  box-shadow: 0 0 10px rgba(0, 191, 255, 0.2);
}

.pub-title {
  font-size: 1.1rem;
  font-weight: bold;
  color: #00bcd4;
  margin-bottom: 0.5rem;
}

.pub-meta {
  font-size: 0.9rem;
  margin-bottom: 0.8rem;
}

.pub-abstract {
  font-size: 0.9rem;
  margin-bottom: 1rem;
  color: #aaa;
  line-height: 1.5;
}

.pub-link a {
  color: #00bcd4;
  font-weight: bold;
  text-decoration: none;
}

.pub-link a:hover {
  text-decoration: underline;
}
</style>

## 👨‍💻 About Me

<div style="color: #ddd; line-height: 1.8; font-size: 1.0rem;">

<h2 style="color:#00bfff;">Cybersecurity Engineer</h2>

<p style="text-align: justify;">
  I’m a <strong>Cybersecurity Engineer</strong> with over <strong>4 years of experience</strong> securing enterprise systems through <strong>vulnerability assessment</strong>, <strong>penetration testing</strong>, and <strong>hybrid red and blue teaming</strong>. My unique strength lies in combining an attacker mindset with defensive strategies to help organizations proactively reduce risk and build resilient infrastructures.
</p>


<h3 style="color:#00bfff;">✅ Areas of Expertise</h3>

<ul>
  <li><strong>Offensive Security:</strong> Network and web application pentesting, social engineering, and business logic exploitation</li>
  <li><strong>Defensive Security:</strong> Threat detection, EDR/SIEM monitoring, behavioral analytics, and incident triage</li>
  <li><strong>Threat Intelligence:</strong> Malware analysis, threat hunting, and adversary emulation</li>
  <li><strong>Source Code Analysis:</strong> Manual and automated secure code review during SDLC</li>
  <li><strong>Secure Architecture:</strong> Hardening Linux/Windows systems, Active Directory defenses, Zero Trust</li>
  <li><strong>Log Analysis:</strong> Deep insights into system and security logs to detect anomalies</li>
  <li><strong>Compliance:</strong> PCI DSS, ISO/IEC 27001, secure development frameworks</li>
</ul>

<a href="{{ '/assets/images/author/Raju_Talukder_CV.pdf' | relative_url }}" class="resume-button" download>📄 Download My Resume</a>

</div>

---

## 🔧 Core Expertise

<ul>
  <li>Red Teaming & Blue Teaming</li>
  <li>SIEM, EDR & Incident Response</li>
  <li>Malware & Threat Analysis</li>
  <li>Log Correlation & Threat Hunting</li>
  <li>CVE Research & Source Code Audit</li>
  <li>Reverse Engineering & Forensics</li>
  <li>PCI-DSS, ISO 27001, SOC2 Compliance</li>
  <li>Fintech Security & Data Protection</li>
</ul>

---

## 📜 Certifications

<div class="certifications-container">
  <div class="cert-card">
    <div class="cert-logo">
      <img src="{{ '/assets/images/certification/oscp.png' | relative_url }}" alt="OSCP" width="36" height="36">
    </div>
    <div class="cert-name">OSCP+</div>
  </div>

  <div class="cert-card">
    <div class="cert-logo">
      <img src="{{ '/assets/images/certification/la.png' | relative_url }}" alt="ISO LA" width="36" height="36">
    </div>
    <div class="cert-name">ISO 27001 Lead Auditor</div>
  </div>

  <div class="cert-card">
    <div class="cert-logo">
      <img src="{{ '/assets/images/certification/ceh.png' | relative_url }}" alt="CEH" width="36" height="36">
    </div>
    <div class="cert-name">CEH – Certified Ethical Hacker</div>
  </div>

  <div class="cert-card">
    <div class="cert-logo">
      <img src="{{ '/assets/images/certification/cva.png' | relative_url }}" alt="CVA" width="36" height="36">
    </div>
    <div class="cert-name">CVA1 Certified</div>
  </div>
</div>

---

## 📚 Research Publications

<div class="publication-container">

  <div class="pub-card">
    <div class="pub-title">
      “Car makes and model recognition using convolutional neural network: fine-tune AlexNet architecture”
    </div>
    <div class="pub-meta">
      <strong>Published in:</strong> The Indonesian Journal of Electrical Engineering and Computer Science (IJEECS) · Jan 12, 2024
    </div>
    <div class="pub-abstract">
      Artificial intelligence (AI) has significantly contributed to car make and model recognition in this current era of intelligent technology. By using AI, it is much easier to identify car models from any picture or video. This paper introduces a new model by fine-tuning the AlexNet architecture to determine the car model from images. First of all, our car image dataset has been created. 
    </div>
    <div class="pub-link">
      <a href="https://www.researchgate.net/publication/377340576_Car_make_and_model_recognition_using_convolutional_neural_network_fine-tune_AlexNet_architecture" target="_blank">Read Full Paper</a>
    </div>
  </div>

</div>

## 🛠️ Technical Skills

<div class="skills-grid">
<!-- Scripting & Automation -->
<div>
  <strong>Scripting & Automation</strong><br/>
  <span class="skill-tag">Python</span>
  <span class="skill-tag">PowerShell</span>
  <span class="skill-tag">Bash</span>
  <span class="skill-tag">Ansible</span>
  <span class="skill-tag">Java</span>
  <span class="skill-tag">C/C++</span>
  <span class="skill-tag">YAML</span>
</div>
<!-- Offensive Security -->
<div>
  <strong>Offensive Security</strong><br/>
  <span class="skill-tag">Burp Suite</span>
  <span class="skill-tag">Metasploit</span>
  <span class="skill-tag">Nmap</span>
  <span class="skill-tag">Netcat</span>
  <span class="skill-tag">Hydra</span>
  <span class="skill-tag">Nikto</span>
  <span class="skill-tag">Responder</span>
  <span class="skill-tag">CrackMapExec</span>
  <span class="skill-tag">Impacket</span>
  <span class="skill-tag">BloodHound</span>
  <span class="skill-tag">Empire</span>
</div>
<!-- Defensive Security -->
<div>
  <strong>Defensive Security</strong><br/>
  <span class="skill-tag">Wazuh</span>
  <span class="skill-tag">Splunk</span>
  <span class="skill-tag">Trellix</span>
  <span class="skill-tag">Suricata</span>
  <span class="skill-tag">Sysmon</span>
  <span class="skill-tag">Sigma</span>
  <span class="skill-tag">OSQuery</span>
  <span class="skill-tag">Velociraptor</span>
  <span class="skill-tag">ELK Stack</span>
  <span class="skill-tag">AlienVault OSSIM</span>
</div>
<!-- Security Frameworks -->
<div>
  <strong>Security Frameworks</strong><br/>
  <span class="skill-tag">MITRE ATT&CK</span>
  <span class="skill-tag">NIST 800-53</span>
  <span class="skill-tag">OWASP Top 10</span>
  <span class="skill-tag">CIS Benchmarks</span>
  <span class="skill-tag">PCI-DSS</span>
</div>

</div>

---

## 🔍 What I Do

- **Defend**: Actively monitor and respond to security incidents using EDR and SIEM.  
- **Offend**: Simulate real-world attacks to assess and improve organizational security.  
- **Analyze**: Correlate logs, uncover anomalies, and hunt threats across systems.  
- **Automate**: Build security tools and scripts to streamline detection and response.  
- **Educate**: Share insights through blogs and research on CVE discoveries.

---

## 💬 Let's Connect

I'm open to cybersecurity collaboration, freelance consulting, or technical partnerships. Reach out via 
<a href="javascript:void(0);" onclick="document.getElementById('email').style.display='inline'; this.style.display='none';">email</a> 
or any of the social media listed on this website.

<span id="email" style="display:none;">
  <a href="mailto:rajutalukder70@gmail.com">rajutalukder70@gmail.com</a>
</span>

