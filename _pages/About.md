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

<a href="/assets/files/your_resume.pdf" class="resume-button" download>📄 Download My Resume</a>

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

---

## 📚 Research Publications

<div style="line-height: 1.8; color: #ccc; font-size: 1.0rem;">

### 1. <em>“Enhancing Threat Detection Using Machine Learning in SIEM Platforms”</em>  
<strong>Author:</strong> Raju Talukder  
<strong>Published in:</strong> International Journal of Cybersecurity Research, Vol. 12, Issue 3, 2024  
<strong>Abstract:</strong> This paper explores how machine learning can be integrated into Security Information and Event Management (SIEM) systems to improve threat detection accuracy and reduce false positives.  
<a href="https://example.com/research-paper-link" target="_blank" style="color:#00bcd4; font-weight:bold;">Read Full Paper</a>

</div>

## 🛠️ Technical Skills

<div class="skills-grid">

<div>
<strong>Languages</strong><br/>
<span class="skill-tag">Python</span>
<span class="skill-tag">Bash</span>
<span class="skill-tag">Java</span>
<span class="skill-tag">C/C++</span>
<span class="skill-tag">SQL</span>
</div>

<div>
<strong>Web & Network Security</strong><br/>
<span class="skill-tag">Burp Suite</span>
<span class="skill-tag">Wireshark</span>
<span class="skill-tag">Metasploit</span>
<span class="skill-tag">Nmap</span>
<span class="skill-tag">Netcat</span>
</div>

<div>
<strong>Defensive Security</strong><br/>
<span class="skill-tag">Wazuh</span>
<span class="skill-tag">Trellix</span>
<span class="skill-tag">Suricata</span>
<span class="skill-tag">Sysmon</span>
</div>

<div>
<strong>Cloud & Infra</strong><br/>
<span class="skill-tag">AWS</span>
<span class="skill-tag">Docker</span>
<span class="skill-tag">Zabbix</span>
<span class="skill-tag">Ubuntu Server</span>
</div>

<div>
<strong>Development Tools</strong><br/>
<span class="skill-tag">Git</span>
<span class="skill-tag">VSCode</span>
<span class="skill-tag">Jekyll</span>
<span class="skill-tag">Flask</span>
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

## 📂 Featured GitHub Projects

<div id="github-projects">
  <p style="color: #ccc;">Loading GitHub repositories...</p>
</div>

<script>
  fetch("https://api.github.com/users/Raju-Talukder/repos?sort=updated&per_page=5")
    .then(response => response.json())
    .then(repos => {
      const container = document.getElementById("github-projects");
      container.innerHTML = repos.map(repo => `
        <div style="margin-bottom: 1.5rem;">
          <h4><a href="${repo.html_url}" target="_blank">${repo.name}</a></h4>
          <p>${repo.description || "No description provided."}</p>
        </div>
      `).join('');
    })
    .catch(() => {
      document.getElementById("github-projects").innerHTML = "<p style='color: #f66;'>Unable to load GitHub projects.</p>";
    });
</script>

---

## 💬 Let's Connect

I'm open to cybersecurity collaboration, freelance consulting, or technical partnerships. Reach out via 
<a href="javascript:void(0);" onclick="document.getElementById('email').style.display='inline'; this.style.display='none';">email</a> 
or any of the social media listed on this website.

<span id="email" style="display:none;">
  <a href="mailto:rajutalukder70@gmail.com">rajutalukder70@gmail.com</a>
</span>

