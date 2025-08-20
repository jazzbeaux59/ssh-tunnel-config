#!/usr/bin/env python3

import os
import yaml
import textwrap

CONFIG_PATH = "config/tunnel-hosts.yaml"
OUTPUT_PATH = ".bashrc_tunnels.txt"
JUMP_HOST = "ubuntu@192.168.215.222"  # adjust if needed

def main():
    if not os.path.exists(CONFIG_PATH):
        print(f"❌ Config not found: {CONFIG_PATH}")
        exit(1)

    with open(CONFIG_PATH, "r") as f:
        config = yaml.safe_load(f)

    tunnels = config.get("tunnels", [])
    if not tunnels:
        print("⚠️ No tunnels defined.")
        return

    output = "# Generated from config/tunnel-hosts.yaml\n\n"
    output += textwrap.dedent("""    start_ssh_tunnel() {
      local local_port="$1"
      local target_host="$2"
      local remote_port="$3"
      local dest="$4"

      echo "🔗 Starting tunnel: localhost:$local_port -> $target_host:$remote_port via $dest"
      ssh -f -N -L "${local_port}:${target_host}:${remote_port}" "$dest"
    }

    """)

    for t in tunnels:
        name = t["name"]
        local_port = t["local_port"]
        target_ip = t["target_ip"]
        target_port = t["target_port"]
        output += f"start_tunnel_{name}() {{\n"
        output += f"  start_ssh_tunnel {local_port} {target_ip} {target_port} {JUMP_HOST}\n"
        output += "}\n\n"

    with open(OUTPUT_PATH, "w") as f:
        f.write(output.strip() + "\n")

    print(f"✅ Wrote {OUTPUT_PATH}")

if __name__ == "__main__":
    main()
