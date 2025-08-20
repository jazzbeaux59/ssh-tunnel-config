# Use bash shell
SHELL := /bin/bash

CONFIG_FILE := .bashrc_tunnels.txt
YAML_FILE := config/tunnel-hosts.yaml
SAMPLE_YAML := templates/tunnel-hosts.sample.yaml
GEN_SCRIPT := scripts/generate_bashrc.py
SHUTDOWN_SCRIPT := scripts/shutdown_tunnels.sh

.PHONY: generate start stop test lint reset init help

## Generate .bashrc_tunnels.txt from tunnel-hosts.yaml
generate:
	@echo "⚙️ Generating tunnel helpers from $(YAML_FILE)..."
	@python3 $(GEN_SCRIPT)

## Initialize config/tunnel-hosts.yaml from sample (with prompt), then generate
init:
	@mkdir -p config
	@if [ -f $(YAML_FILE) ]; then \
	  read -p "⚠️  $(YAML_FILE) already exists. Overwrite? [y/N] " confirm; \
	  if [ "$$confirm" != "y" ]; then \
	    echo "❌ Aborting init."; \
	    exit 1; \
	  fi; \
	fi
	@cp $(SAMPLE_YAML) $(YAML_FILE)
	@echo "✅ Copied sample config to $(YAML_FILE)"
	@echo "📝 Please edit and customize $(YAML_FILE) before running 'make generate'"

## Start all defined tunnels
start:
	@echo "🚀 Starting SSH tunnels..."
	@bash -c 'source $(CONFIG_FILE); declare -F | grep start_tunnel_ | awk "{print \$$3}" | while read f; do $$f; done'

## Stop SSH tunnels (requires shutdown_tunnels.sh)
stop:
	@test -f $(SHUTDOWN_SCRIPT) || (echo "❌ Script not found: $(SHUTDOWN_SCRIPT)" && exit 1)
	@echo "🛑 Stopping all SSH tunnels..."
	@bash $(SHUTDOWN_SCRIPT)

## Test tunnel ports for availability
test:
	@echo "🔍 Testing for tunnel port availability..."
	@awk '/^start_tunnel_/ { print $$1 }' $(CONFIG_FILE) | while read f; do \
		port=$$(grep -A1 "$$f" $(CONFIG_FILE) | grep start_ssh_tunnel | awk '{print $$2}'); \
		if lsof -i :$$port -sTCP:LISTEN >/dev/null 2>&1; then \
			echo "❌ Port $$port already in use"; \
		else \
			echo "✅ Port $$port is available"; \
		fi; \
	done

## Lint: check if file was regenerated
lint:
	@grep -q 'Generated from config/tunnel-hosts.yaml' $(CONFIG_FILE) && \
		echo "✅ Config file appears to be generated from YAML." || \
		(echo "⚠️  Config may be outdated or manually edited." && exit 1)

## Reset config by regenerating from YAML
reset: generate
	@echo "🔁 Tunnel config reset from YAML."

## Show help
help:
	@echo ""
	@echo "Available targets:"
	@grep -E '^##' $(MAKEFILE_LIST) | sed -E 's/^## //;s/^([a-z_-]+):.*/\1/' | awk '{ printf "  %-12s %s\n", $$1, substr($$0, index($$0,$$2)) }'

