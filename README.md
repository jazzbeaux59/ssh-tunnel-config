# SSH Tunnel Configuration Toolkit (YAML Edition)

This project simplifies the setup and management of SSH tunnels from a local development machine to services on an airgapped network, via a designated jump server.

---

## 🔧 How It Works

You define your tunnels in a YAML config file (`config/tunnel-hosts.yaml`), and use a Python script to generate a shell helper script (`.bashrc_tunnels.txt`) with per-service SSH tunnel functions. These tunnels can be started, stopped, tested, and linted using a simple `Makefile`.

---

## 📁 File Structure

```text
.
├── .bashrc_tunnels.txt          # Auto-generated from YAML
├── config/
│   └── tunnel-hosts.yaml        # User-defined list of tunnel targets (generated or customized)
├── templates/
│   └── tunnel-hosts.sample.yaml # Sample starting config for new setups
├── scripts/
│   ├── generate_bashrc.py       # YAML → Bashrc tunnel generator
│   └── shutdown_tunnels.sh      # Graceful shutdown of known tunnels
├── Makefile                     # Automation commands
└── README.md
```

---

## ✅ Getting Started

### 1. **Initialize your configuration**

Run:

```bash
make init
```

This will:
- Create the `config/` directory if it doesn’t exist
- Copy the sample file from `templates/tunnel-hosts.sample.yaml` to `config/tunnel-hosts.yaml`
- Prompt you before overwriting if `tunnel-hosts.yaml` already exists

> 📝 **Important:** You must **edit and customize** `config/tunnel-hosts.yaml` before proceeding.  
> Define the tunnels you need by setting `name`, `local_port`, `target_ip`, and `target_port`.

---

### 2. **Generate the helper script**

Once your YAML config is customized, run:

```bash
make generate
```

This produces `.bashrc_tunnels.txt`, which defines shell functions like `start_tunnel_maas` for each configured tunnel.

---

### 3. **Start and stop tunnels**---

## 🌐 Accessing Remote Services After Tunneling

Once your tunnels are active (via `make start` or `source .bashrc_tunnels.txt && start_tunnel_<name>`), the target services are reachable locally on your machine.

---

### 🌍 Web Access Example

If your airgapped server runs a web UI (e.g., MAAS at `192.168.227.3:5240`) and your tunnel is defined like this in `tunnel-hosts.yaml`:

```yaml
- name: maas
  local_port: 15240
  target_ip: 192.168.227.3
  target_port: 5240
```

Then after running:

```bash
source .bashrc_tunnels.txt
start_tunnel_maas
```

You can visit the airgapped service using your **local browser**:

```
http://localhost:15240/
```

---

### 🪟 RDP (Remote Desktop) from Windows

If you have a Windows Server on the airgapped network with RDP enabled (e.g., `192.168.227.101:3389`) and you define a tunnel like:

```yaml
- name: windows
  local_port: 13389
  target_ip: 192.168.227.101
  target_port: 3389
```

After running:

```bash
source .bashrc_tunnels.txt
start_tunnel_windows
```

Then from a **Windows machine**, open **Remote Desktop Connection (mstsc.exe)** and connect to:

```
localhost:13389
```

> 🔐 Make sure the jump server's SSH key is trusted and the private key is loaded in your agent (`ssh-add`), especially when tunneling from Windows tools like MobaXterm or PuTTY.



Use the following to activate or deactivate all tunnel functions:
```bash
make start    # Starts all tunnels defined in .bashrc_tunnels.txt
make stop     # Runs shutdown_tunnels.sh to stop them
```

---

### 4. **Test local ports before binding**

Check for conflicts on the ports you're using:
```bash
make test
```

---

## 🧪 Linting

```bash
make lint
```

Checks that `.bashrc_tunnels.txt` appears to have been generated from YAML, not hand-edited or templated.

---

## 🛠 Available Make Targets

| Target         | Description                                                |
|----------------|------------------------------------------------------------|
| `make init`    | Initialize `config/tunnel-hosts.yaml` from sample (with prompt) |
| `make generate`| Generate `.bashrc_tunnels.txt` from YAML                   |
| `make start`   | Start all defined tunnel functions                         |
| `make stop`    | Stop SSH tunnels via `scripts/shutdown_tunnels.sh`        |
| `make test`    | Check if defined ports are available                       |
| `make lint`    | Check if `.bashrc_tunnels.txt` was generated from YAML     |
| `make reset`   | Regenerate `.bashrc_tunnels.txt` from YAML (alias)         |

---

## 🧯 Troubleshooting

### ❌ Password Prompt Fails
If `make start` prompts for an SSH password:
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
```

Ensure your jump host’s public key is authorized.

---

### ⚠️ Tunnel Port Already in Use
If you see:
```
bind [127.0.0.1]:PORT: Address already in use
```

Run:
```bash
make stop
```

Or:
```bash
lsof -i :PORT
kill <PID>
```

---

## 🙈 Git Hygiene

```gitignore
# Ignore generated tunnel script and customized config
.bashrc_tunnels.txt
config/tunnel-hosts.yaml
```

Only commit changes to:
- `templates/tunnel-hosts.sample.yaml`
- `scripts/`
- `Makefile`
- `README.md`
