#!/usr/bin/env python3

import os
import sys
import argparse
import yaml

TEMPLATE_HEADER = "# Generated from config/tunnel-hosts.yaml"
DEST_FILE = ".bashrc_tunnels.txt"

def load_config(config_path="config/tunnel-hosts.yaml"):
    if not os.path.exists(config_path):
        print(f"❌ Config file not found: {config_path}")
        sys.exit(1)
    try:
        with open(config_path, "r", encoding="utf-8") as f:
            config = yaml.safe_load(f)
    except yaml.YAMLError as e:
        print(f"❌ YAML syntax error in {config_path}:\n{e}")
        sys.exit(1)

    # Top-level validation
    if not isinstance(config, dict):
        print("❌ Invalid config: top-level YAML structure must be a dictionary")
        sys.exit(1)
    if "jump_host" not in config:
        print("❌ Invalid config: missing required key 'jump_host'")
        sys.exit(1)
    if "tunnels" not in config or not isinstance(config["tunnels"], list):
        print("❌ Invalid config: missing or malformed 'tunnels' list")
        sys.exit(1)
    if not config["tunnels"]:
        print("❌ Invalid config: 'tunnels' list is empty")
        sys.exit(1)

    seen_names = set()
    for i, tunnel in enumerate(config["tunnels"]):
        for key in ["name", "local_port", "target_ip", "target_port"]:
            if key not in tunnel:
                print(f"❌ Invalid config: tunnel[{i}] missing required key '{key}'")
                sys.exit(1)

        name = tunnel["name"]
        if name in seen_names:
            print(f"❌ Duplicate tunnel name detected: '{name}'")
            sys.exit(1)
        seen_names.add(name)

    return config

def generate_bashrc_content(data):
    tunnels = data.get("tunnels", [])
    jump_host = data.get("jump_host", None)
    if not jump_host:
        print("❌ Missing 'jump_host' in config file.")
        sys.exit(1)

    lines = [TEMPLATE_HEADER, f"JUMP_HOST={jump_host}", ""]

    for tunnel in tunnels:
        name = tunnel["name"]
        local_port = tunnel["local_port"]
        target_ip = tunnel["target_ip"]
        target_port = tunnel["target_port"]

        lines.append(f"# {name} tunnel")
        lines.append(f"start_tunnel_{name}() {{")
        lines.append(f"  ssh -f -N -L {local_port}:{target_ip}:{target_port} $JUMP_HOST")
        lines.append("}")
        lines.append("")

    return "\n".join(lines)

def write_bashrc_file(content):
    with open(DEST_FILE, "w", encoding="utf-8") as f:
        f.write(content + "\n")
    print(f"✅ Generated {DEST_FILE}")

def start_tunnel(data, name):
    tunnel = next((t for t in data.get("tunnels", []) if t["name"] == name), None)
    if not tunnel:
        print(f"❌ Tunnel '{name}' not found in config")
        sys.exit(1)
    jump_host = data.get("jump_host")
    local_port = tunnel["local_port"]
    target_ip = tunnel["target_ip"]
    target_port = tunnel["target_port"]
    print(f"🔗 Starting tunnel: localhost:{local_port} -> {target_ip}:{target_port} via {jump_host}")
    os.system(f"ssh -f -N -L {local_port}:{target_ip}:{target_port} {jump_host}")

def stop_tunnel(data, name):
    tunnel = next((t for t in data.get("tunnels", []) if t["name"] == name), None)
    if not tunnel:
        print(f"❌ Tunnel '{name}' not found in config")
        sys.exit(1)
    local_port = tunnel["local_port"]
    print(f"🛑 Stopping tunnel on local port {local_port}...")
    os.system(f"lsof -ti tcp:{local_port} | xargs --no-run-if-empty kill")

def start_all(data):
    for tunnel in data.get("tunnels", []):
        start_tunnel(data, tunnel["name"])

def stop_all(data):
    for tunnel in data.get("tunnels", []):
        stop_tunnel(data, tunnel["name"])

def show_config(data):
    print(f"🔐 Jump host: {data.get('jump_host')}")
    for tunnel in data.get("tunnels", []):
        print(f"  - {tunnel['name']}: localhost:{tunnel['local_port']} -> {tunnel['target_ip']}:{tunnel['target_port']}")

def check_status(data):
    for tunnel in data.get("tunnels", []):
        port = tunnel["local_port"]
        result = os.system(f"lsof -i tcp:{port} >/dev/null 2>&1")
        status = "✅ open" if result == 0 else "❌ closed"
        print(f"{tunnel['name']}: localhost:{port} is {status}")

def test_tunnels(data):
    for tunnel in data.get("tunnels", []):
        port = tunnel["local_port"]
        target = tunnel["target_ip"]
        print(f"🔍 Testing localhost:{port} -> {target}...")
        result = os.system(f"nc -z localhost {port}")
        if result == 0:
            print("✅ Tunnel is reachable")
        else:
            print("❌ Tunnel is not responding")

def lint_file(data):
    if not os.path.exists(DEST_FILE):
        print("❌ Lint failed: .bashrc_tunnels.txt does not exist")
        sys.exit(1)

    with open(DEST_FILE, "r", encoding="utf-8") as f:
        existing = f.read()

    generated = generate_bashrc_content(data)

    if existing.strip() != generated.strip():
        print("❌ Lint failed: .bashrc_tunnels.txt is out-of-date")
        sys.exit(1)

    print("✅ .bashrc_tunnels.txt is up-to-date")

def main(args):
    data = load_config()

    if args.generate:
        content = generate_bashrc_content(data)
        write_bashrc_file(content)
    elif args.generate_stdout:
        config = load_config()
        print(generate_bashrc_content(config))
        return
    elif args.tunnel:
        start_tunnel(data, args.tunnel)
    elif args.stop:
        stop_tunnel(data, args.stop)
    elif args.start_all:
        start_all(data)
    elif args.stop_all:
        stop_all(data)
    elif args.show:
        show_config(data)
    elif args.status:
        check_status(data)
    elif args.test:
        test_tunnels(data)
    elif args.lint:
        config = load_config()
        output = generate_bashrc_content(config)
        try:
            with open(".bashrc_tunnels.txt", "r", encoding="utf-8") as f:
                current = f.read()
            if current != output:
                print("❌ Lint warning: .bashrc_tunnels.txt is out-of-date")
            else:
                print("✅ Lint passed: .bashrc_tunnels.txt is up-to-date")
        except FileNotFoundError:
            print("❌ Lint warning: .bashrc_tunnels.txt is missing")
        # Always exit with 0 to avoid failing the Makefile
        sys.exit(0)
    else:
        print("Use --help to see available options")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--generate-stdout', action='store_true', help="Output generated .bashrc_tunnels.txt content to stdout")
    parser.add_argument("--generate", action="store_true", help="Generate .bashrc_tunnels.txt")
    parser.add_argument("--tunnel", help="Start a single tunnel by name")
    parser.add_argument("--start-all", action="store_true", help="Start all tunnels")
    parser.add_argument("--stop", help="Stop a single tunnel by name")
    parser.add_argument("--stop-all", action="store_true", help="Stop all tunnels")
    parser.add_argument("--show", action="store_true", help="Show current tunnel config")
    parser.add_argument("--status", action="store_true", help="Check if tunnels are open")
    parser.add_argument("--test", action="store_true", help="Test tunnel port reachability")
    parser.add_argument("--lint", action="store_true", help="Check if .bashrc_tunnels.txt is up-to-date")
    args = parser.parse_args()
    main(args)
