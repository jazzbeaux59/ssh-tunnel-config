# Makefile for SSH tunnel config

SHELL := /bin/bash

export ENV_FILE := ./config/sample.env

include $(ENV_FILE)

.PHONY: help all start stop one

help:
	@echo "Available targets:"
	@echo "  make start     - Start all SSH tunnels"
	@echo "  make stop      - Kill all SSH tunnels"
	@echo "  make one LPORT= PORT= TARGET= - Start a specific tunnel"
	@echo "  make show      - Show tunnel aliases"
	@echo "  make help      - This message"

start:
	@./scripts/launch_all.sh

stop:
	@./scripts/kill_all.sh

one:
	@if [ -z "$(LPORT)" ] || [ -z "$(TARGET)" ] || [ -z "$(PORT)" ]; then \
		echo "Usage: make one LPORT=<local> PORT=<remote> TARGET=<ip>"; \
		exit 1; \
	fi; \
	./scripts/tunnel_one.sh $(LPORT) $(TARGET) $(PORT) $(USERNAME)@$(JUMP_IP)

show:
	@source ./.bashrc_tunnels.txt && show_tunnels

test:
	@echo "Testing tunnel connections..."
	@echo "Testing Proxmox..."
	@curl -sk https://localhost:8006 || echo "Proxmox unreachable"
	@echo "Testing MAAS..."
	@curl -s http://localhost:5240 || echo "MAAS unreachable"
	@echo "Testing WinRM port..."
	@nc -zv localhost 15986 || echo "WinRM port closed"
	@echo "Testing RDP port..."
	@nc -zv localhost 13389 || echo "RDP port closed"