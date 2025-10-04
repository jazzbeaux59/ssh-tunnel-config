# ---- Makefile (ssh-tunnel-config) -------------------------------------------
SHELL := /bin/bash

PY ?= python3
PIP ?= pip

VENV ?= .venv
ACTIVATE = . $(VENV)/bin/activate

OK := ✅
ERR := ❌
INFO := ℹ️

LAST_FILE := .last_profile
CONFIG_YML := config/ssh_config.yml

.DEFAULT_GOAL := help

.PHONY: help venv deps lint list start stop status switch current reload configs _detect-cli

# ---- CLI detection ----------------------------------------------------------
CLI_NEW := $(firstword $(wildcard src/tunnels.py))
CLI_OLD := $(firstword $(wildcard scripts/generate_bashrc.py))

_detect-cli:
	@if [ -n "$(CLI_NEW)" ]; then \
		echo "$(INFO) Using new CLI: $(CLI_NEW)"; \
	elif [ -n "$(CLI_OLD)" ]; then \
		echo "$(INFO) Using legacy CLI: $(CLI_OLD)"; \
	else \
		echo "$(ERR) No CLI found."; \
		echo "    Expected one of:"; \
		echo "      - src/tunnels.py (new)"; \
		echo "      - scripts/generate_bashrc.py (legacy)"; \
		exit 1; \
	fi

## Show available targets and their descriptions
help:
	@echo "Available targets:"
	@awk ' \
		/^##/ {desc=substr($$0,4); getline; if ($$0 ~ /^[a-zA-Z0-9_-]+:/) {split($$0,a,":"); printf "%-12s %s\n", a[1]":", desc}} \
	' $(MAKEFILE_LIST)

## Create a Python virtual environment
venv:
	$(PY) -m venv $(VENV)

## Install Python dependencies from requirements.txt
deps: venv
	$(ACTIVATE) && $(PIP) install -r requirements.txt

## Quietly ensure dependencies are installed (for internal use)
_ensure-deps:
	@if [ ! -d "$(VENV)" ]; then \
		echo "$(INFO) Creating virtual environment..."; \
		$(MAKE) --no-print-directory venv; \
	fi
	@if [ ! -f "$(VENV)/.deps-installed" ] || [ "requirements.txt" -nt "$(VENV)/.deps-installed" ]; then \
		echo "$(INFO) Installing dependencies..."; \
		$(ACTIVATE) && $(PIP) install -q -r requirements.txt && touch "$(VENV)/.deps-installed"; \
	fi

## Lint Python and YAML files
lint:
	@echo "Linting Python files with ruff..."
	@ruff check scripts/
	@echo "Linting YAML files with yamllint..."
	@yamllint config/ssh_config.yml

## Start tunnels for the selected profile
start: _detect-cli deps
	@P="$$( { $(RESOLVE_PROFILE_SH) ; } )" && \
	echo "🔐 PROFILE='$$P'" && \
	if [ -n "$(CLI_NEW)" ]; then \
		$(ACTIVATE) && $(PY) $(CLI_NEW) start $$P && echo "$(OK) Started tunnels for '$$P'"; \
	else \
		$(ACTIVATE) && $(PY) $(CLI_OLD) --start --profile $$P && echo "$(OK) Started tunnels for '$$P'"; \
	fi

## Stop tunnels for the selected profile
stop: _detect-cli _ensure-deps
	@P="$$( { $(RESOLVE_PROFILE_SH) ; } )" && \
	echo "🔐 PROFILE='$$P'" && \
	if [ -n "$(CLI_NEW)" ]; then \
		$(ACTIVATE) && $(PY) $(CLI_NEW) stop $$P && echo "$(OK) Stopped tunnels for '$$P'" || true; \
	else \
		$(ACTIVATE) && $(PY) $(CLI_OLD) --stop-all --profile $$P || true; \
		echo "$(OK) Stopped tunnels for '$$P'"; \
	fi

## Show status for the selected profile
status: _detect-cli _ensure-deps
	@P="$$( { $(RESOLVE_PROFILE_SH) ; } )" && \
	echo "🔐 PROFILE='$$P'" && \
	if [ -n "$(CLI_NEW)" ]; then \
		$(ACTIVATE) && $(PY) $(CLI_NEW) status $$P || true; \
	else \
		$(ACTIVATE) && $(PY) $(CLI_OLD) --status --profile $$P || true; \
	fi

## Set and persist the active profile, then restart tunnels
## Set and persist the active profile, then restart tunnels
switch: _detect-cli
	@if [ -z "$(PROFILE)" ]; then \
		echo "$(ERR) PROFILE is required for switch. Use: make switch PROFILE=<name>"; \
		exit 1; \
	fi
	PREV_PROFILE=$$(cat $(LAST_FILE) 2>/dev/null); \
	if [ -n "$$PREV_PROFILE" ]; then \
		echo "🛑 Stopping tunnels for previous profile '$$PREV_PROFILE'..."; \
		$(MAKE) --no-print-directory stop PROFILE="$$PREV_PROFILE"; \
	fi; \
	echo "🔀 Switching to profile '$(PROFILE)'..."; \
	echo "$(PROFILE)" > $(LAST_FILE); \
	$(MAKE) --no-print-directory start PROFILE=$(PROFILE); \
	$(MAKE) --no-print-directory current

## Print the saved profile from .last_profile
current:
	@if [ -f "$(LAST_FILE)" ]; then \
		echo "📌 Current profile: $$(cat $(LAST_FILE))"; \
	else \
		echo "📌 No profile saved yet. Use: make switch PROFILE=<name>"; \
	fi

## Stop and start the active (or provided) profile after config changes
reload: _detect-cli
	@P="$$( { $(RESOLVE_PROFILE_SH) ; } )" && \
	echo "🔁 Reloading profile '$$P'..." && \
	$(MAKE) --no-print-directory stop PROFILE="$$P" && \
	$(MAKE) --no-print-directory start PROFILE="$$P"

## List available profiles and show example SSH/RDP commands for each
configs: _ensure-deps
	@$(ACTIVATE) && $(PY) scripts/list_configs.py

# ---- Resolve profile helper (no write) --------------------------------------
define RESOLVE_PROFILE_SH
PROFILE_EFF="$(PROFILE)"; \
if [ -z "$$PROFILE_EFF" ]; then \
	if [ -f "$(LAST_FILE)" ]; then PROFILE_EFF="$$(sed -n '1p' $(LAST_FILE))"; fi; \
fi; \
if [ -z "$$PROFILE_EFF" ] && [ -f "$(CONFIG_YML)" ]; then \
	PROFILE_EFF="$$(awk '/^default_profile:[[:space:]]*/{print $$2; exit}' $(CONFIG_YML))"; \
fi; \
if [ -z "$$PROFILE_EFF" ]; then \
	echo "$(ERR) Unable to resolve profile. Set PROFILE=<name> once via 'make switch PROFILE=<name>'." >&2; \
	exit 1; \
fi; \
echo "$$PROFILE_EFF"
endef
