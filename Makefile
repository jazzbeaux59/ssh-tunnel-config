# Makefile for SSH Tunnel Manager
SHELL := /bin/bash

PYTHON := python3
SCRIPT := scripts/generate_bashrc.py
CONFIG := config/ssh_config.yml
CURRENT_PROFILE_FILE := .current_profile
DEFAULT_PROFILE := $(or ${PROFILE},$(shell cat $(CURRENT_PROFILE_FILE) 2>/dev/null || awk '/^default_profile:/ {print $$2}' $(CONFIG)))

.PHONY: help start stop switch status test show generate lint examples

# Set help as the default target
.DEFAULT_GOAL := help

## 🔧 Core Commands

start:
	@echo "🔧 Starting SSH tunnels..."
	@echo "--------------------------------------------------"
	$(PYTHON) $(SCRIPT) --start-all --profile $(DEFAULT_PROFILE)

stop:
	@echo "🛑 Stopping SSH tunnels..."
	@echo "--------------------------------------------------"
	$(PYTHON) $(SCRIPT) --stop-all --profile $(DEFAULT_PROFILE)

switch:
	@echo "🔀 Switching to profile '$(PROFILE)'..."
	@echo "$(PROFILE)" > $(CURRENT_PROFILE_FILE)
	@$(MAKE) stop PROFILE=$(PROFILE)
	@$(MAKE) start PROFILE=$(PROFILE)

## 📊 Status & Debug

status:
	@echo "🔍 Checking tunnel status..."
	@echo "--------------------------------------------------"
	$(PYTHON) $(SCRIPT) --status --profile $(DEFAULT_PROFILE)

test:
	@echo "🔬 Testing tunnel reachability..."
	@echo "--------------------------------------------------"
	$(PYTHON) $(SCRIPT) --test --profile $(DEFAULT_PROFILE)

show:
	@echo "📄 Showing tunnel config for profile '$(DEFAULT_PROFILE)'..."
	@echo "--------------------------------------------------"
	$(PYTHON) $(SCRIPT) --show --profile $(DEFAULT_PROFILE)

## 📝 File Generation

generate:
	@echo "📄 Generating .bashrc_tunnels.txt..."
	@$(PYTHON) $(SCRIPT) --generate --profile $(DEFAULT_PROFILE)

lint:
	@echo "🔍 Checking if .bashrc_tunnels.txt is up-to-date..."
	@$(PYTHON) $(SCRIPT) --lint --profile $(DEFAULT_PROFILE)

## 📚 Misc

examples:
	@echo "📚 Usage examples:"
	@sed -n '/^## 🧪 Usage Examples$$/,/^## /{/^## /!p}' README.md | sed '/^$$/d'

help:
	@echo "🛠️  SSH Tunnel Manager — Available Targets"
	@echo
	@echo "🔧 Core Commands:"
	@echo "  make start              Start all tunnels for the current profile"
	@echo "  make stop               Stop all tunnels for the current profile"
	@echo "  make switch PROFILE=XX Switch to a different tunnel profile"
	@echo
	@echo "📊 Status & Debug:"
	@echo "  make status             Show which tunnels are currently open"
	@echo "  make test               Test reachability of tunnel endpoints"
	@echo "  make show               Show parsed config for the current profile"
	@echo
	@echo "📝 File Generation:"
	@echo "  make generate           Generate .bashrc_tunnels.txt"
	@echo "  make lint               Check if .bashrc_tunnels.txt is up-to-date"
	@echo
	@echo "📚 Misc:"
	@echo "  make examples           Show usage examples"
	@echo "  make help               Show this help message"
	@echo
	@echo "💡 Tip: Override the profile with PROFILE=name, e.g. make start PROFILE=infra"
