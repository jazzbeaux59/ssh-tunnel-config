#!/usr/bin/env python3

import os
import sys
import argparse
import yaml

CONFIG_PATH = "config/ssh_config.yml"
BASHRC_OUTPUT = ".bashrc_tunnels.txt"
TEMPLATE_HEADER = "# Generated from config/ssh_config.yml"

def load_config():
    if not os.path.exists(CONFIG_PATH):
        print(f"❌ Config file not found: {CONFIG_PATH}")
        sys.exit(1)
    try:
        with open(CONFIG_PATH, "r", encoding="utf-8") as f:
            return yaml.safe_load(f)
    except yaml.YAMLError as e:
        print(f"❌ YAML syntax error in {CONFIG_PATH}:\n{e}")
        sys.exit(1)

def get_profile(config, profile):
    if profile:
        if profile not in config.get("profiles", {}):
            print(f"❌ Profile '{profile}' not found in config.")
            sys.exit(1)
        return {profile: config["profiles"][profile]}
    return config.get("profiles", {})

def generate_bashrc_lines(config):
    lines = [TEMPLATE_HEADER]
    for profile, data in config.items():
        jump_host = data["jump_host"]
        jump_user = data["jump_user"]
        for tunnel in data["tunnels"]:
            name = tunnel["name"]
            local_port = tunnel["local_port"]
            target_ip = tunnel["target_ip"]
            target_port = tunnel["target_port"]
            full_name = f"{name}_{profile}"
            lines.append(f"# {full_name} tunnel")
            lines.append(f"start_tunnel_{full_name}() {{")
            lines.append(f"  ssh -f -N -L {local_port}:{target_ip}:{target_port} {jump_user}@{jump_host} \\")
            lines.append("    -o ExitOnForwardFailure=yes \\")
            lines.append("    -o ServerAliveInterval=60 \\")
            lines.append("    -o ServerAliveCountMax=3 \\")
            lines.append("    -o ConnectTimeout=10 \\")
            lines.append("    -o StrictHostKeyChecking=no")
            lines.append("}")
            lines.append("")
    return lines

def write_bashrc_file(content):
    with open(BASHRC_OUTPUT, "w", encoding="utf-8") as f:
        f.write(content + "\n")
    print(f"✅ Generated {BASHRC_OUTPUT}")

def lint_file(config):
    expected = "\n".join(generate_bashrc_lines(config)).strip()
    if not os.path.exists(BASHRC_OUTPUT):
        print("❌ Lint warning: .bashrc_tunnels.txt is missing")
        sys.exit(1)
    with open(BASHRC_OUTPUT, "r", encoding="utf-8") as f:
        actual = f.read().strip()
    if actual != expected:
        print("❌ Lint warning: .bashrc_tunnels.txt is out-of-date")
        print("💡 Run the following command to regenerate it:")
        print("   make generate")
        sys.exit(1)
    else:
        print("✅ Lint passed: .bashrc_tunnels.txt is up-to-date")

def show_config(profiles):
    for profile, data in profiles.items():
        print(f"🔐 Profile: {profile}")
        print(f"    Jump host: {data['jump_user']}@{data['jump_host']}")
        for tunnel in data["tunnels"]:
            print(f"    - {tunnel['name']}: localhost:{tunnel['local_port']} -> {tunnel['target_ip']}:{tunnel['target_port']}")

def check_status(profiles):
    for profile, data in profiles.items():
        for tunnel in data["tunnels"]:
            port = tunnel["local_port"]
            result = os.system(f"lsof -i tcp:{port} >/dev/null 2>&1")
            status = "✅ open" if result == 0 else "❌ closed"
            print(f"{tunnel['name']}_{profile}: localhost:{port} is {status}")

def test_tunnels(profiles):
    for profile, data in profiles.items():
        for tunnel in data["tunnels"]:
            port = tunnel["local_port"]
            target = tunnel["target_ip"]
            print(f"🔍 Testing localhost:{port} -> {target} ({profile})...")
            result = os.system(f"nc -z localhost {port}")
            print("✅ Tunnel is reachable" if result == 0 else "❌ Tunnel is not responding")

def start_tunnel(profiles, name):
    for profile, data in profiles.items():
        for tunnel in data["tunnels"]:
            if tunnel["name"] == name:
                print(f"🔗 Starting tunnel: {name}_{profile}")
                cmd = (
                    f"ssh -f -N -L {tunnel['local_port']}:{tunnel['target_ip']}:{tunnel['target_port']} "
                    f"{data['jump_user']}@{data['jump_host']} "
                    "-o ExitOnForwardFailure=yes "
                    "-o ServerAliveInterval=60 "
                    "-o ServerAliveCountMax=3 "
                    "-o ConnectTimeout=10 "
                    "-o StrictHostKeyChecking=no"
                )
                os.system(cmd)
                return
    print(f"❌ Tunnel '{name}' not found in filtered profiles.")
    sys.exit(1)

def stop_tunnel(profiles, name):
    for profile, data in profiles.items():
        for tunnel in data["tunnels"]:
            if tunnel["name"] == name:
                port = tunnel["local_port"]
                print(f"🛑 Stopping tunnel {name}_{profile} on port {port}")
                os.system(f"lsof -ti tcp:{port} | xargs --no-run-if-empty kill")
                return
    print(f"❌ Tunnel '{name}' not found in filtered profiles.")
    sys.exit(1)

def start_all(profiles):
    for profile, data in profiles.items():
        for tunnel in data["tunnels"]:
            start_tunnel({profile: data}, tunnel["name"])

def stop_all(profiles):
    for profile, data in profiles.items():
        for tunnel in data["tunnels"]:
            stop_tunnel({profile: data}, tunnel["name"])

def main(cli):
    config = load_config()
    profiles = get_profile(config, cli.profile)

    if cli.generate:
        lines = generate_bashrc_lines(profiles)
        write_bashrc_file("\n".join(lines))
    elif cli.generate_stdout:
        print("\n".join(generate_bashrc_lines(profiles)))
    elif cli.lint:
        lint_file(profiles)
    elif cli.show:
        show_config(profiles)
    elif cli.status:
        check_status(profiles)
    elif cli.test:
        test_tunnels(profiles)
    elif cli.tunnel:
        start_tunnel(profiles, cli.tunnel)
    elif cli.stop:
        stop_tunnel(profiles, cli.stop)
    elif cli.start_all:
        start_all(profiles)
    elif cli.stop_all:
        stop_all(profiles)
    else:
        print("Use --help to see available options")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--generate", action="store_true", help="Generate .bashrc_tunnels.txt")
    parser.add_argument("--generate-stdout", action="store_true", help="Print generated content to stdout")
    parser.add_argument("--lint", action="store_true", help="Check if .bashrc_tunnels.txt is up-to-date")
    parser.add_argument("--show", action="store_true", help="Display configured tunnels")
    parser.add_argument("--status", action="store_true", help="Check status of tunnel ports")
    parser.add_argument("--test", action="store_true", help="Test tunnel port reachability")
    parser.add_argument("--start-all", action="store_true", help="Start all tunnels")
    parser.add_argument("--stop-all", action="store_true", help="Stop all tunnels")
    parser.add_argument("--tunnel", help="Start a single tunnel by name")
    parser.add_argument("--stop", help="Stop a single tunnel by name")
    parser.add_argument("--profile", help="Limit operations to a specific profile")
    cli = parser.parse_args()
    main(cli)
