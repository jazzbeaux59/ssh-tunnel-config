#!/usr/bin/env python3
import subprocess
import yaml
import os

CONFIG_FILE = "config/ssh_config.yml"


def load_ports_from_yaml(config_path):
    with open(config_path, "r") as f:
        config = yaml.safe_load(f)
    return [t.get("local_port") for t in config.get("tunnels", []) if t.get("local_port")]

def find_pid_on_port(port):
    try:
        result = subprocess.run(
            ["lsof", "-i", f"TCP:{port}", "-sTCP:LISTEN", "-t"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError:
        return None

def stop_tunnels():
    if not os.path.exists(CONFIG_FILE):
        print(f"❌ Config file not found: {CONFIG_FILE}")
        return

    print("🛑 Stopping SSH tunnels...")
    ports = load_ports_from_yaml(CONFIG_FILE)

    for port in ports:
        print(f"🔍 Checking port {port}...")
        pid = find_pid_on_port(port)
        if pid:
            print(f"💀 Killing process {pid} for tunnel on port {port}")
            subprocess.run(["kill", pid])
        else:
            print(f"⚠️  No active tunnel found on port {port}")

    print("✅ All tunnels stopped (if any were active).")

if __name__ == "__main__":
    stop_tunnels()

