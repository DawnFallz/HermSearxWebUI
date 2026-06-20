# 🚀 HermSearxWebUI Installer for Termux

A Termux installer that automatically sets up a complete AI and search stack, including:

- 🤖 Hermes Agent (AI agent framework)
- 🔎 SearXNG (privacy-focused meta search engine)
- 🌐 OpenWebUI (modern AI chat interface)

All components are installed, configured, and optionally managed through a unified terminal launcher using `tmux`.

---

## ⚙️ System Requirements

Before installing, ensure your device meets the following:

**📱 Device** :
- Android 8.0 or higher
- ARM64 (recommended) or ARMv7 support

**📦 Apps Required**:
- [Termux](https://f-droid.org/en/packages/com.termux/) (from F-Droid)
- [Termux:API](https://f-droid.org/en/packages/com.termux.api/) (optional but recommended)

**💾 Storage**:
- At least 2–5 GB free storage

**🌐 Internet**:
- Stable internet connection (required for package downloads)

---

## ✨ Features

- 🧠 Automated setup of AI + search stack
- 🎛 Interactive checkbox menu for selecting components
- 🐍 Automatic Python virtual environment setup
- 📦 Dependency installation (pip, system packages, etc.)
- 🔐 Proot Ubuntu environment for OpenWebUI
- 🧵 tmux-based multi-service orchestration
- 🔔 Optional Termux notifications + wake lock support
- ⚡ One-command launcher for all services
- 🧩 Adds aliases and functions into `.bashrc`

---

## 📥 Installation

### 1. Install Termux (from F-Droid) and Termux:API (recommended)
- 👉 [Termux](https://f-droid.org/en/packages/com.termux/)
- 👉 [Termux:API](https://f-droid.org/en/packages/com.termux.api/)

### 2. Update Termux packages
``` bash
pkg update -y && pkg upgrade -y

```

### 3. Install required tools
``` bash
pkg install -y git

```

### 4. Clone the installer
``` bash
git clone https://github.com/DawnFallz/termux-hermsearxwebui.git
cd termux-hermsearxwebui

```

### 5. Run the installer
``` bash
bash install.sh

```

### 6. Reload the shell
``` bash
source ~/.bashrc

```

---

## 🧠 Components Overview

- **🤖 Hermes Agent**:
AI agent framework for automation and task handling.

- **🔎 SearXNG**:
Self-hosted privacy search engine aggregating results from multiple sources.

- **🌐 OpenWebUI**:
Modern UI forinteracting with AI models locally or remotely

---

## ⚠️ Notes

- First installation may take 10–30 minutes depending on device speed.
- OpenWebUI runs inside a Proot Ubuntu environment.
- Some features require Termux:API for notifications and wake-lock support.

---

## 🛠 Troubleshooting

### ❌ Command not found (hermsearxwebui)
Run:
``` bash
source ~/.bashrc

```

### ❌ Installation fails midway
Try:
``` bash
pkg update && pkg upgrade

```

---

## 📜 License

This project is licensed under the MIT License.
See the full license here: [LICENSE](LICENSE)
