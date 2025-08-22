# SSH Tunnel Configurator

This project manages SSH tunnels using a YAML configuration file. It can generate bash functions for tunnels, start/stop tunnels, test them, and check status. Multiple profiles are supported (e.g., `dev`, `prod`).

---

## 🔧 Requirements

- Python 3.6+
- `yaml` module (`pip install pyyaml`)
- Linux/macOS
- SSH key-based login to jump hosts

---

## 📁 Configuration File

Located at `config/ssh_config.yml`.

### Example structure

```yaml
default_profile: dev

profiles:
  prod:
    jump_host: 192.168.10.222
    jump_user: mike
    tunnels:
      - name: service1
        local_port: 5000
        target_ip: 10.0.0.1
        target_port: 80
  dev:
    jump_host: 192.168.10.226
    jump_user: mike
    tunnels:
      - name: vault
        local_port: 8200
        target_ip: 10.2.10.11
        target_port: 8200
```

---

## 🛠 Makefile Usage

```bash
make help         # Show all supported targets
make generate     # Generate .bashrc_tunnels.txt from YAML
make lint         # Check if .bashrc_tunnels.txt is up-to-date
make show         # Show config for selected profile
make status       # Show which tunnel ports are open
make test         # Test if tunnel ports are responsive
make start        # Start all tunnels for the selected profile
make stop         # Stop all tunnels for the selected profile
make switch PROFILE=exxon  # Switch profile and restart tunnels
```

---

## 🔑 Passwordless SSH Setup

To avoid password prompts:

1. Ensure you have an SSH key (generate with `ssh-keygen` if needed).
2. Copy your public key to the jump host:

```bash
ssh-copy-id -i /path/to/your/key.pub username@remote_host
```

3. Confirm `~/.ssh/config` has appropriate entries:

```bash
Host default
    HostName 10.2.10.200
    User user
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    PubkeyAuthentication yes

Host exxon
    HostName 10.2.10.222
    User user
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    PubkeyAuthentication yes
```

---

## 🧪 Usage Examples

Assuming the tunnels have already been started (e.g., with `make start`), you can now use them like so:

### 🔐 SSH into a tunneled host

```bash
ssh user@localhost -p 2222
```

> Replace `user` with your remote username. The `2222` is your local forwarded port to the remote SSH service.

---

### 🖥️ RDP to Linux Host (Using Remote Desktop Connection on Windows)

**Tunnel definition**:

```yaml
- name: linux-gui
  local_port: 3390
  target_ip: 192.168.100.42
  target_port: 3389
```

#### Steps to Connect

1. **Start the tunnel** (you’ve already done this via `make start PROFILE=...`).
2. **Open Remote Desktop Connection** on Windows:
   - Press `Win + R`, type `mstsc`, and press Enter.
3. In the **Computer** field, enter:

   ```txt
   localhost:3390
   ```

4. Click **Connect**.
5. Enter your Linux **username** and **password** when prompted.

> 💡 **Ensure `xrdp` is installed and running on the Linux host:**

```bash
sudo apt install xrdp
sudo systemctl enable --now xrdp
```

You can connect using any RDP client, such as:

- **Remote Desktop Connection (`mstsc`)** on Windows
- **Remmina** on Linux
- **xfreerdp** on macOS/Linux

> 📌 The default RDP port is `3389`.

---

### 💻 Run Windows command line over SSH tunnel

```bash
ssh Administrator@localhost -p 2222 powershell.exe
```

> Starts a remote PowerShell session over the tunnel.

---

### 🌐 Open a web app on an airgapped VM

Open this URL in your web browser: `http://localhost:4253`

> This opens a web application (e.g., Grafana, Keycloak, etc.) running on the remote machine, tunneled to local port 4253.

---

## 📂 Output

- `.bashrc_tunnels.txt` — shell functions for launching SSH tunnels.

---

## 📂 Project Structure

```txt
.
├── config/                 # YAML config files
├── scripts/                # Python scripts (e.g., generate_bashrc.py)
├── .bashrc_tunnels.txt     # Generated tunnel launcher functions
├── Makefile                # Task automation interface
└── README.md               # This documentation
```

---

## 📄 License

This project is licensed under the terms of the [MIT License](LICENSE).

---

## 🆘 Support

For questions, feedback, or bug reports, please contact:

📧 **mklein.ccs@gmail.com**
