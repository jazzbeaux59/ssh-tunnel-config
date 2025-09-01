
---

## 🔧 Requirements

- Python 3.8+
- Python package manager `pip` (install with `sudo apt install python3-pip` on Ubuntu/Debian)
- Python virtual environment (`.venv`) is recommended. Most Makefile targets expect `.venv` to exist and be activated. See Quick Start below.
- OpenSSH client (`ssh`)
- Linux/macOS/WSL (Windows works via Git Bash or WSL)
- SSH key-based auth to your jump host(s)
- RDP client (mstsc.exe on Windows, Remmina/FreeRDP on Linux)

- For linting: `ruff` and `yamllint` (install with `pip install ruff yamllint`)

---

## 🚀 Quick start

```bash
# 1) Create a Python virtual environment (required for Makefile targets)
python3 -m venv .venv && source .venv/bin/activate

# 2) Install deps
pip install -r requirements.txt

# 3) Edit your config
Then$EDITOR [ssh_config.yml](http://_vscodecontentref_/3)

# 4) Choose a profile (persist as last used)
make switch PROFILE=exxon

# 5) Everyday operations (uses saved .last_profile)
make start
make status
make stop
