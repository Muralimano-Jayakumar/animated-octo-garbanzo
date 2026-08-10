.DEFAULT_GOAL := help

PYTHON ?= python3
VENV ?= .venv

.PHONY: help preflight tool-versions app-install app-test app-run check

help: ## Show available targets
	@awk 'BEGIN {FS = ":.*## "; printf "Available targets:\n"} /^[a-zA-Z_-]+:.*## / {printf "  %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

preflight: ## Report installed and missing development tools
	@./scripts/preflight.sh

tool-versions: ## Print versions without starting local services
	@./scripts/tool-versions.sh

app-install: ## Create a virtual environment and install app dependencies
	@$(PYTHON) -m venv $(VENV)
	@$(VENV)/bin/python -m pip install --upgrade pip
	@$(VENV)/bin/python -m pip install -e '.[dev]'

app-test: ## Run application linting and tests
	@$(VENV)/bin/ruff check app
	@$(VENV)/bin/pytest

app-run: ## Run the Flask API locally on port 5000
	@$(VENV)/bin/flask --app muma_bank.wsgi run --host 127.0.0.1 --port 5000

check: preflight ## Run safe repository validation
	@git diff --check
	@bash -n scripts/*.sh
	@if command -v shellcheck >/dev/null 2>&1; then shellcheck scripts/*.sh; fi
	@echo "Bootstrap checks passed."
