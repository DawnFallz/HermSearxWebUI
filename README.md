# 🚀 HermSearxWebUI

A cross-platform installer for a complete AI + privacy-focused search stack:

- 🤖 **Hermes Agent**
- 🔎 **SearXNG**
- 🌐 **Open WebUI**

Supports **Linux, macOS, Windows (WSL2), and Termux**.

---

## 📁 Project Structure

```text
HermSearxWebUI/
├── Linux/
│   └── install.sh
├── MacOS/
│   └── install.sh
├── Termux/
│   └── install.sh
├── Windows/
│   └── install.ps1
├── LICENSE
└── README.md
```

## ⚙️ Requirements

### 🐧 Linux

- 64-bit Linux
- Internet connection
- `bash`
- `curl`
- `git`
- Python 3.10+

### 🍎 macOS

- macOS 12+
- Intel or Apple Silicon
- Internet connection
- `bash` / `zsh`
- `curl`
- `git`
- Python 3.10+

### 🪟 Windows

- Windows 10/11
- **WSL2**
- Ubuntu
- PowerShell 5.1+

Linux-based components run **inside WSL2**, not as native Windows Linux packages.

### 📱 Termux

- Android 8+
- Termux
- ARM64 recommended
- Termux:API recommended

---

## 📥 Installation

### Linux

```bash
cd Linux
chmod +x install.sh
./install.sh
```

### macOS

```bash
cd MacOS
chmod +x install.sh
./install.sh
```

### Termux

```bash
cd Termux
chmod +x install.sh
./install.sh
```

### Windows

Open PowerShell:

```powershell
cd Windows
.\install.ps1
```

The Windows installer uses:

```text
Windows
   ↓
WSL2
   ↓
Ubuntu
   ↓
Hermes + SearXNG + Open WebUI
```

---

# ✨ Features

- 🤖 Hermes Agent installation
- 🔎 SearXNG installation
- 🌐 Open WebUI installation
- 🐍 Python virtual environments
- 🧵 `tmux` service management
- ⚡ Unified `hermsearxwebui` launcher
- 🎛 Component selection
- 📁 Custom installation names
- 🖥 Platform-specific installation

---

# 🚀 Services

If all three components are installed, start the complete stack with:

```bash
hermsearxwebui
```

Individual services:

```bash
hermes
searxng
open-webui-run
```

---

# ⚠️ Notes for Termux Installations

- First installation may take 10–30 minutes depending on device speed.
- OpenWebUI runs inside a Proot Ubuntu environment.
- Some features require Termux:API for notifications and wake-lock support.

---

# 🛠 Troubleshooting

If a command is not found after installation, reload your shell:

```bash
source ~/.bashrc
```

On macOS:

```bash
source ~/.zshrc
```

---

## 📜 License

This project is licensed under the MIT License.
See the full license here: [LICENSE](LICENSE)
