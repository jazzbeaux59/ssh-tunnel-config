# SSH Tunnel Configurator

A simple, profile-based SSH tunnel manager that lets you define and switch between sets of tunnels for development, infrastructure access, or any remote environment.

## 📁 Configuration

All tunnel profiles are defined in a single YAML file: `config/tunnel-hosts.yaml`.

Each profile includes:

- A `jump_host` (the bastion / proxy server)
- A `jump_user` (the SSH user to log in as)
- A list of `tunnels` with `name`, `local_port`, `target_ip`, and `target_port`.

### 🔧 Example Configuration

```yaml
profiles:
  default:
    jump_host: 192.168.215.222
    jump_user: mike
    tunnels:
      - name: provisioning-server
        local_port: 2201
        target_ip: 192.168.227.69
        target_port: 22
      - name: proxmox
        local_port: 8006
        target_ip: 192.168.227.7
        target_port: 8006

  dev:
    jump_host: dev.jump.local
    jump_user: devops
    tunnels:
      - name: grafana
        local_port: 3000
        target_ip: 10.0.0.5
        target_port: 3000
      - name: ssh-builder
        local_port: 2222
        target_ip: 10.0.0.10
        target_port: 22
```

Each tunnel’s effective name is suffixed with its profile name (e.g. `proxmox_default`, `grafana_dev`) to ensure uniqueness.

---

## 🛠 Usage

Use `make` commands to manage tunnels. Requires Python 3 and SSH client.

### 🔄 Available Targets

| Make Target      | Description |
|------------------|-------------|
| `make start`     | Start all tunnels (or a specific one with `NAME=...`). Optionally specify `PROFILE=...`. |
| `make stop`      | Stop all running tunnels. |
| `make status`    | Show currently running SSH tunnel processes. |
| `make show`      | Show tunnel configuration from all profiles. |
| `make lint`      | Check if `.bashrc_tunnels.txt` is up-to-date with the config. |
| `make examples`  | Print usage examples. |
| `make switch PROFILE=name` | Switch to a profile (noop, since all profiles are merged now). |

You can override variables at the command line:

```bash
make start PROFILE=dev
make start NAME=grafana_dev
make stop
```

---

## 🧪 Examples

```bash
# Start all tunnels in the 'default' profile
make start

# Start all tunnels in a different profile
make start PROFILE=dev

# Start a specific tunnel by name
make start NAME=grafana_dev

# Stop all tunnels
make stop

# Show your current configuration
make show

# See which tunnels are active
make status

# Preview bashrc lines
make generate-stdout PROFILE=default
```

---

## ⚠️ Troubleshooting

### My machine appears in the list of tunnels unexpectedly

This usually happens when your shell environment has a lingering `NAME` variable set. You can inspect this with:

```bash
echo $NAME
```

If this prints your hostname or a tunnel name you didn’t intend to use, simply unset it:

```bash
unset NAME
```

This is especially common if you've previously run `make start NAME=...` and forgot to unset `NAME` afterward.

---

### Overlapping local ports between profiles

If multiple profiles define tunnels using the same `local_port` values, commands like `make start`, `make status`, or `make stop` may fail with messages such as:

```
❌ Overlapping local_port '2201' in profile 'exxon'
```

To avoid this:

- Ensure all `local_port` values are unique across **all profiles**, not just within a profile.
- Consider reserving a distinct range of ports for each profile (e.g., 2200–2299 for `default`, 2300–2399 for `exxon`, etc.).
- Alternatively, use the `NAME` and `PROFILE` environment variables to work with a single tunnel or profile at a time and avoid conflicts.

Use `make lint` to check whether your `.bashrc_tunnels.txt` is in sync with your configuration.

### ❌ My own machine is showing up as a tunnel host

This happens when the `NAME` environment variable is set in your shell. It can confuse the script when starting tunnels.

**Fix:**

```bash
unset NAME
```

Also added to the `Makefile` logic to clear `NAME` after use.

---

### ❌ Port already in use

This means something is already listening on the same local port (e.g., from a previous run).

**Fix:**

```bash
make stop
make start
```

---

## 📜 Generated Bashrc Snippet

To generate a list of SSH commands for `.bashrc` or manual use:

```bash
make generate
```

This creates `.bashrc_tunnels.txt` from your current profile config.

---

## ✅ Requirements

- Python 3.8+
- OpenSSH client (`ssh`)
- YAML file in `config/tunnel-hosts.yaml`

---

## 📂 Layout

```
.
├── config/
│   └── tunnel-hosts.yaml
├── scripts/
│   └── generate_bashrc.py
├── Makefile
└── .bashrc_tunnels.txt
```

---

## 🙋 Support

Feel free to add issues or request new features.

## License

This project is licensed under the [MIT License](LICENSE) © 2025 Michel J. Klein.
