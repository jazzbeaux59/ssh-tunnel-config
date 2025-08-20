#!/bin/bash
source "$(dirname "$0")/../config/sample.env"

start_ssh_tunnel() {
  ssh -fN -L "$1":"$2":"$3" "$4"
}

start_ssh_tunnel 8006 "$PROXMOX_IP" 8006 "$USERNAME@$JUMP_IP"
start_ssh_tunnel 5240 "$MAAS_IP" 5240 "$USERNAME@$JUMP_IP"
start_ssh_tunnel 13389 "$WIN_IP" 3389 "$USERNAME@$JUMP_IP"
start_ssh_tunnel 15986 "$WIN_IP" 5986 "$USERNAME@$JUMP_IP"