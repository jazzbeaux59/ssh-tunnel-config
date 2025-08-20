.PHONY: all help init generate start stop test reset show status lint tunnel examples

PYTHON = python3
PYTHON_SCRIPT = scripts/generate_bashrc.py
CONFIG_FILE = config/tunnel-hosts.yaml
SAMPLE_FILE = templates/tunnel-hosts.sample.yaml

# Default target
help:  ## Show this help
	@echo ""
	@echo "Available targets:"
	@awk '/^[a-zA-Z_-]+:.*?##/ { \
		gsub(":", "", $$1); \
		printf "  \033[1m%-12s\033[0m %s\n", $$1, substr($$0, index($$0,$$3)) \
	}' $(MAKEFILE_LIST) | sort
	@echo ""

init:  ## Initialize config/tunnel-hosts.yaml from sample (with prompt)
	@mkdir -p config
	@if [ -f $(CONFIG_FILE) ]; then \
		read -p "⚠️  $(CONFIG_FILE) exists. Overwrite? [y/N] " yn; \
		if [ "$$yn" = "y" ] || [ "$$yn" = "Y" ]; then \
			cp $(SAMPLE_FILE) $(CONFIG_FILE); \
			echo "✅ Copied sample config to $(CONFIG_FILE)"; \
			echo "📝 Remember to edit this file before running 'make generate'"; \
		else \
			echo "❌ Aborted."; \
			exit 1; \
		fi \
	else \
		cp $(SAMPLE_FILE) $(CONFIG_FILE); \
		echo "✅ Created $(CONFIG_FILE) from sample"; \
		echo "📝 Remember to edit this file before running 'make generate'"; \
	fi

generate:  ## Generate .bashrc_tunnels.txt from tunnel-hosts.yaml
	@$(PYTHON) $(PYTHON_SCRIPT) --generate

start:  ## Start all tunnels or a named tunnel with NAME=<name>
	@echo "🚀 Starting SSH tunnels..."
ifeq ($(origin NAME), undefined)
	@$(PYTHON) $(PYTHON_SCRIPT) --start-all
else
	@$(PYTHON) $(PYTHON_SCRIPT) --tunnel $(NAME)
endif

stop:  ## Stop all tunnels or a named tunnel with NAME=<name>
	@echo "🛑 Stopping SSH tunnels..."
ifeq ($(origin NAME), undefined)
	@$(PYTHON) $(PYTHON_SCRIPT) --stop-all
else
	@$(PYTHON) $(PYTHON_SCRIPT) --stop $(NAME)
endif

lint:  ## Check if .bashrc_tunnels.txt is stale
	@echo "🔍 Checking if .bashrc_tunnels.txt is up-to-date..."
	@bash -c 'diff .bashrc_tunnels.txt <(python3 $(PYTHON_SCRIPT) --generate-stdout) > /dev/null && \
		echo "✅ Lint passed: .bashrc_tunnels.txt is up-to-date" || \
		{ echo "❌ Lint warning: .bashrc_tunnels.txt is out-of-date"; exit 0; }'

test:  ## Test tunnel ports for availability
	@$(PYTHON) $(PYTHON_SCRIPT) --test

reset:  ## Regenerate .bashrc_tunnels.txt from config
	@$(MAKE) generate

show:  ## Show current tunnel configuration
	@$(PYTHON) $(PYTHON_SCRIPT) --show

status:  ## Check if tunnels are active
	@echo "🔎 Checking tunnel status..."
	@$(PYTHON) $(PYTHON_SCRIPT) --status

examples:  ## Show usage examples from README
	@awk '/^## Examples/{show=1; next} /^## /{show=0} show' README.md | less

