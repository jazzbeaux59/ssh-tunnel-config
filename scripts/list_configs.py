import os
import sys
import yaml

def first_port(tunnels, want):
    for t in tunnels:
        try:
            if int(t.get("target_port", 0)) == want:
                return int(t.get("local_port"))
        except Exception:
            pass
    return None

def all_ports(tunnels, want_ports):
    # Return a list of (local_port, target_port) for all matching target_ports
    result = []
    for t in tunnels:
        try:
            tp = int(t.get("target_port", 0))
            if tp in want_ports:
                result.append((int(t.get("local_port")), tp))
        except Exception:
            pass
    return result

def main():
    cfg_path = os.path.join("config", "ssh_config.yml")
    with open(cfg_path, "r", encoding="utf-8") as f:
        raw = yaml.safe_load(f)
    profiles = raw.get("profiles", {}) or {}
    if not profiles:
        print("No profiles found in config/ssh_config.yml")
        sys.exit(1)

    print("Available profiles:")
    for name, pdata in profiles.items():
        tunnels = pdata.get("tunnels") or []
        ssh_lp  = first_port(tunnels, 22)
        rdp_lp  = first_port(tunnels, 3389)
        web_ports = [5240, 8006, 80, 443]
        web_lps = all_ports(tunnels, web_ports)
        print(f"  - {name}")
        print(f"    switch:  make switch PROFILE={name}")
        if ssh_lp:
            print(f"    ssh:     ssh -p {ssh_lp} ubuntu@localhost")
            print(f"    scp:     scp -P {ssh_lp} ./file ubuntu@localhost:/home/ubuntu/")
        else:
            print("    ssh:     (no target_port 22 tunnel declared)")
        if rdp_lp:
            print(f"    rdp(win): mstsc.exe /v:localhost:{rdp_lp}")
            print(f"    rdp(*nix): xfreerdp /v:localhost:{rdp_lp}")
        else:
            print("    rdp:     (no target_port 3389 tunnel declared)")
        for lp, tp in web_lps:
            proto = "https" if tp in (443, 8006, 5240) else "http"
            print(f"    web:     {proto}://localhost:{lp}")

if __name__ == "__main__":
    main()
