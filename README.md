# ssh-tunnel-config

Manages SSH port-forward tunnels to remote lab environments through a jump host. Tunnels are defined per profile in `config/ssh_config.yml` and controlled via `make` targets.

---

## Requirements

- Python 3.8+
- `pip` (`sudo apt install python3-pip` on Ubuntu/Debian)
- OpenSSH client (`ssh`)
- Linux, macOS, or WSL
- SSH key-based auth to your jump host(s)
- RDP client for Windows targets (`mstsc.exe` on Windows, `xfreerdp` on Linux)
- For linting: `ruff` and `yamllint` (`pip install ruff yamllint`)

---

## Quick Start

```bash
# 1) Create a virtual environment
python3 -m venv .venv && source .venv/bin/activate

# 2) Install dependencies
pip install -r requirements.txt

# 3) Edit your config
$EDITOR config/ssh_config.yml

# 4) Switch to a profile (persists to .last_profile)
make switch PROFILE=prod-test-01

# 5) Day-to-day usage (uses saved profile automatically)
make start
make status
make stop
```

---

## Make Targets

| Target | Description |
|---|---|
| `make start` | Start tunnels for the active profile |
| `make stop` | Stop tunnels for the active profile |
| `make stop-all` | Kill all SSH tunnel processes (hard reset) |
| `make status` | Show which tunnels are up/down |
| `make switch PROFILE=<name>` | Set active profile, stop old tunnels, start new ones |
| `make current` | Print the currently saved profile |
| `make reload` | Stop and restart tunnels for the active profile |
| `make configs` | List all profiles with SSH, RDP, and web connection examples |
| `make lint` | Check config and generated files for issues |

Profile can always be overridden inline: `make start PROFILE=eval1`

---

## Config File

Config lives at `config/ssh_config.yml`. Top-level keys:

```yaml
default_profile: prod-test-01

profiles:
  prod-test-01:
    jump_host: 192.168.215.222
    jump_user: mike
    identity_file: ~/.ssh/id_ed25519
    use_autossh: false
    tunnels:
      - name: provisioning-server
        local_port: 22201
        target_ip: 10.3.4.60
        target_port: 22
      - name: vscode-provisioning
        local_port: 22202
        target_ip: 10.3.4.60
        target_port: 22
```

Each tunnel forwards `localhost:<local_port>` through the jump host to `<target_ip>:<target_port>`.

Current profiles: `prod-test-01`, `eval1`, `petrobras`, `wood-lab-2`

---

## Connecting with VS Code Remote-SSH

Each profile includes a `vscode-provisioning` tunnel on a dedicated port to avoid conflicts with direct SSH sessions.

After starting tunnels, add this to `~/.ssh/config`:

```
Host provisioning-prod-test-01
    HostName localhost
    Port 22202
    User ubuntu
    IdentityFile ~/.ssh/id_ed25519
```

Then in VS Code: **Remote-SSH: Connect to Host** → `provisioning-prod-test-01`

Port reference for `vscode-provisioning` by profile:

| Profile | Local Port |
|---|---|
| `prod-test-01` | 22202 |
| `eval1` | 22202 |
| `petrobras` | 32202 |
| `wood-lab-2` | 22202 |

---

## SSH and RDP Examples

Run `make configs` to print connection examples for every profile. Sample output:

```
  - prod-test-01
    switch:  make switch PROFILE=prod-test-01
    ssh:     ssh -p 22201 ubuntu@localhost
    scp:     scp -P 22201 ./file ubuntu@localhost:/home/ubuntu/
    rdp(win): mstsc.exe /v:localhost:23389
    rdp(*nix): xfreerdp /v:localhost:23389
    web:     https://localhost:28006
    web:     http://localhost:25240
```
