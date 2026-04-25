# 🔍 ZeroTraceR — Advanced Linux Reconnaissance Tool

ZeroTraceR is a production-focused Linux system reconnaissance tool designed for **post-exploitation enumeration**, **system auditing**, and **security analysis**.

It automates critical host-level information gathering and presents it in a structured, operator-friendly format.

---

## ⚡ Features

* 🖥️ OS & Kernel Detection
* 👤 User & Privilege Enumeration
* 📂 Full User Listing (getent / passwd fallback)
* ⚙️ Running Process Analysis
* 🌐 Open Port Detection (ss → netstat → lsof fallback)
* 🔌 Network Interface Mapping
* 📦 Installed Package Enumeration (multi-distro support)
* ⚠️ Risk Indicators (root, sudo, suspicious ports)
* 📄 Report Generation with optional file output

---

## 🚀 Installation

```bash
git clone https://github.com/TocsiVector/ZeroTraceR.git
cd ZeroTraceR
chmod +x system_recon.sh
```

---

## 🧪 Usage

```bash
./system_recon.sh
```

### Save output to file:

```bash
./system_recon.sh -o report.txt
```

### Show help menu:

```bash
./system_recon.sh -h
```

---

## 🧠 How It Works

ZeroTraceR performs structured system enumeration across multiple layers:

* System identity and OS details
* User accounts and privilege context
* Active processes and services
* Open ports and network exposure
* Installed software inventory

All data is aggregated into a clean report for fast analysis.

---

## ⚠️ Important Notes

* Some features may require **root privileges** for full visibility
* Designed for:

  * Authorized penetration testing
  * Cybersecurity labs (CTF, training)
  * Internal system auditing

🚫 Do NOT use on systems without permission.

---

## 📁 Project Structure

```
ZeroTraceR/
│── system_recon.sh
│── README.md
│── LICENSE
│── examples/
│── output/
```

---

## 🔥 Example Output

```
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
⚠ User has sudo privileges
```

---

## 🛠️ Tech Stack

* Bash (POSIX Shell)
* Native Linux utilities (ps, ss, netstat, ip, etc.)

---

## 📌 Roadmap

* [ ] Privilege Escalation Detection Module
* [ ] Automated Risk Scoring
* [ ] JSON Output Mode
* [ ] Integration with other security tools

---

## 🤝 Contributing

Pull requests are welcome. For major changes, open an issue first.

---

## 📜 License

MIT License

---

## 👤 Author

**TocsiVector**

---

## ⭐ Final Note

This tool is built to bridge the gap between **manual enumeration** and **automated reconnaissance**, helping security practitioners move faster and smarter.
