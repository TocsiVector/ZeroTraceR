# 🔍 ZeroTraceR

![Linux](https://img.shields.io/badge/Platform-Linux-blue)
![Bash](https://img.shields.io/badge/Language-Bash-green)
![License](https://img.shields.io/badge/License-MIT-yellow)
![Version](https://img.shields.io/badge/Version-1.0-red)

> ⚡ Advanced Linux Reconnaissance Tool for Post-Exploitation & System Analysis

---

## 🚀 Overview

ZeroTraceR is a lightweight yet powerful **Linux enumeration tool** designed for:

* Post-exploitation reconnaissance
* System auditing
* Security analysis

It automates system data collection and presents results in a clean, structured format.

---

## 🧰 Features

* ✔ OS & Kernel Detection
* ✔ User & Privilege Enumeration
* ✔ Process & Service Discovery
* ✔ Open Port Analysis (ss / netstat / lsof)
* ✔ Network Interface Mapping
* ✔ Installed Package Enumeration
* ✔ Risk Indicators (root / sudo / exposed services)

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

## 📂 Examples

Check the `examples/` directory for:

* Basic usage commands
* Sample output
* Saved reports

---

## 🧠 How It Works

ZeroTraceR performs structured enumeration across:

* System identity
* Users & privileges
* Running processes
* Open ports and services
* Network interfaces
* Installed packages

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
* Root access (optional but recommended)

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
