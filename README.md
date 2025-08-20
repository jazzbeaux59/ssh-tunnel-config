# SSH Tunnel Project

This project simplifies the creation of persistent SSH tunnels through a jump server to access services inside an airgapped network.

## Features

- Centralized configuration of tunnel destinations
- Template-driven generation of startup scripts
- One-command startup via Makefile
- Supports web, RDP, and SSH access to remote airgapped hosts
- Lint check to verify `.bashrc_tunnels.txt` is up-to-date
- Python-only (no shell script dependencies)

## Directory Structure

```
.
├── config/
│   └── tunnel-hosts.yaml
├── templates/
│   └── tunnel-hosts.sample.yaml
│   └── .bashrc_tunnels.txt.j2
├── scripts/
│   └── generate_bashrc.py
├── .bashrc_tunnels.txt
├── Makefile
└── README.md
```

## Usage

### 1. Initialize

```bash
make init
```

- Copies `tunnel-hosts.sample.yaml` to `config/tunnel-hosts.yaml`
- If the file already exists, prompts before overwriting
- **Reminder:** Edit `config/tunnel-hosts.yaml` to match your environment

### 2. Generate tunnel script

```bash
make generate
```

Generates `.bashrc_tunnels.txt` based on the current YAML config.

### 3. Start tunnels

```bash
make start
```

Starts all defined SSH tunnels in the background.

To start a single tunnel:

```bash
make start NAME=maas
```

### 4. Stop tunnels

```bash
make stop
```

Stops all SSH tunnels.

To stop a single tunnel:

```bash
make stop NAME=maas
```

### 5. Show configured tunnels

```bash
make show
```

Displays the parsed configuration and jump host.

### 6. Test tunnel availability

```bash
make test
```

Checks whether tunnels are reachable locally.

### 7. Check status

```bash
make status
```

Verifies which SSH tunnels are currently running.

### 8. Lint

```bash
make lint
```

Checks if `.bashrc_tunnels.txt` matches the current YAML config.
**Does not fail the Makefile**.

---

## Examples

### Web Interface Access

To access an internal web UI (e.g. MAAS or Proxmox):

- Define the tunnel in `tunnel-hosts.yaml`:

```yaml
- name: maas
  local_port: 5240
  target_ip: 192.168.227.3
  target_port: 5240
```

- Visit `https://localhost:5240` in your browser.

### Windows Remote Desktop (RDP)

To access a Windows VM via RDP:

```yaml
- name: eng-ws
  local_port: 13389
  target_ip: 192.168.227.53
  target_port: 3389
```

- From your Windows machine, open Remote Desktop Connection
- Connect to `localhost:13389`

### SSH into Remote Linux Host

To SSH into a Linux VM behind the jump host:

```yaml
- name: remote-dev
  local_port: 2222
  target_ip: 192.168.227.44
  target_port: 22
```

- Then use:

```bash
ssh -p 2222 user@localhost
```

---

## Troubleshooting

### Jump Host Rejects SSH Key and Prompts for Password

If `make start` prompts for a password (e.g., `mike@192.168.215.222`), it's likely that:

- Your **SSH key isn't present or authorized** on the jump host
- Your **SSH config is incorrect**
- The **key is being rejected by the server**

#### ✅ Fix Instructions

1. **Check if your key is being offered**:

   ```bash
   ssh -vv mike@192.168.215.222
   ```

2. **Add your public key to the jump host**:

   ```bash
   ssh mike@192.168.215.222 'mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'
   cat ~/.ssh/id_ed25519.pub | ssh mike@192.168.215.222 'cat >> ~/.ssh/authorized_keys'
   ```

3. **Set up your SSH config**:

   ```ssh
   Host jump
     HostName 192.168.215.222
     User mike
     IdentityFile ~/.ssh/id_ed25519
     IdentitiesOnly yes
   ```

Then use `jump` as your `jump_host` in `tunnel-hosts.yaml`.
