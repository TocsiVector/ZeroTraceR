<p align="center">
  <img src="https://readme-typing-svg.herokuapp.com?color=00FF9C&size=35&center=true&vCenter=true&width=900&lines=ZeroTraceR+v3.0.1;Linux+Reconnaissance+Tool;Post-Exploitation+Automation" />
</p>

<h1 align="center">🔍 ZeroTraceR</h1>

<p align="center">
Advanced Linux Reconnaissance Tool for Post-Exploitation & System Analysis
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Linux-blue"/>
  <img src="https://img.shields.io/badge/Language-Bash-green"/>
  <img src="https://img.shields.io/badge/Version-3.0.1-red"/>
  <img src="https://img.shields.io/badge/License-MIT-yellow"/>
</p>

---

## 🚀 Overview

ZeroTraceR is a **lightweight yet powerful Linux enumeration tool** built for:

* Post-exploitation reconnaissance
* System auditing
* Security analysis

It automates system information gathering and presents results in a structured, operator-friendly format.

---

## 🧰 Features

* ✔ OS & Kernel Detection
* ✔ User & Privilege Enumeration
* ✔ Process & Service Discovery
* ✔ Open Port Analysis (ss / netstat / lsof fallback)
* ✔ Network Interface Mapping
* ✔ Installed Package Enumeration
* ✔ Risk Indicators (root / sudo / exposed services)
* ✔ Structured Output Reporting

---

## ⚙️ Installation

```bash
git clone https://github.com/TocsiVector/ZeroTraceR.git
cd ZeroTraceR
chmod +x system_recon.sh
```

---

## ▶️ Usage

```bash
./system_recon.sh
```

### Save Output

```bash
./system_recon.sh -o report.txt
```

### Help Menu

```bash
./system_recon.sh -h
```
---

## 📊 Output Preview

```bash
[OS DETAILS]
Hostname: kali
Kernel: 6.x.x
IP: 192.168.x.x

[CURRENT USER]
User: kali
Privileges: standard user

[OPEN PORTS]
22/tcp  ssh
80/tcp  http

[RISK]
⚠ Sudo privileges detected
```

---

## ⚠️ Requirements

* Linux-based system
* Bash shell
* Root access (recommended for full visibility)

---

## 🛠️ Roadmap

* [ ] Privilege Escalation Detection
* [ ] Risk Scoring System
* [ ] JSON Output Mode
* [ ] Multi-tool Integration

---

## 📜 License

MIT License

---

## 👤 Author

**TocsiVector**

---

## ⭐ Support

If you find this project useful, give it a ⭐ on GitHub.

---

## ⚠️ Disclaimer

This tool is intended for **educational purposes and authorized security testing only**.
Do not use on systems without permission.
