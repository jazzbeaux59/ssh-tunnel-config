# SSH Tunneling via Jump Server

This repository documents a clean and flexible SSH tunneling system to access services behind a jump server. It supports RDP, WinRM, web interfaces (Proxmox, MAAS), and provides automation scripts for starting/stopping tunnels.

## 📦 Directory Structure

```
ssh-tunnel-config/
├── README.md
├── .bashrc_tunnels.txt
├── config/
│   ├── sample.env
│   └── tunnel-hosts.yaml
├── scripts/
│   ├── launch_all.sh
│   ├── kill_all.sh
│   └── tunnel_one.sh
└── extras/
    └── systemd-tunnel-winrm.service
```

## 🚀 Quick Start

1. Copy `.bashrc_tunnels.txt` into your `~/.bashrc` or source it:
   ```bash
   cat .bashrc_tunnels.txt >> ~/.bashrc
   source ~/.bashrc
   ```

2. Start all tunnels:
   ```bash
   ./scripts/launch_all.sh
   ```

3. Stop all tunnels:
   ```bash
   ./scripts/kill_all.sh
   ```

## 🔐 Customization

Edit `config/sample.env` with your actual jump host and IPs.

## 📑 License

MIT

# 🚀 Deployment Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/ssh-tunnel-config.git
cd ssh-tunnel-config
```

### 2. Customize Environment Variables

Edit `config/sample.env`:

```bash
USERNAME=your_ssh_user
JUMP_IP=your_jump_host_ip
PROXMOX_IP=internal_proxmox_ip
MAAS_IP=internal_maas_ip
WIN_IP=internal_windows_ip
```

### 3. Source Tunnel Aliases

```bash
source .bashrc_tunnels.txt
```

To make them persistent, add to your `~/.bashrc`:

```bash
cat .bashrc_tunnels.txt >> ~/.bashrc
source ~/.bashrc
```

### 4. Launch and Test Tunnels

```bash
make start   # Launch all tunnels
make test    # Verify tunnel connectivity
```

### 5. Kill Tunnels

```bash
make stop
```