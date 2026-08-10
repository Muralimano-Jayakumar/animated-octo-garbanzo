.DEFAULT_GOAL := help

PYTHON ?= python3
VENV ?= .venv
IMAGE ?= muma-bank:dev
CONTAINER ?= muma-bank-local
APP_PORT ?= 8080

.PHONY: help preflight tool-versions app-install app-test app-run container-build container-scan container-run container-stop container-remove container-smoke check

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

container-build: ## Build the local application image
	@docker build --tag $(IMAGE) .

container-scan: ## Fail on fixable high or critical image vulnerabilities
	@trivy image --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 --no-progress $(IMAGE)

container-run: ## Run the image on a loopback-only port
	@docker run --detach --name $(CONTAINER) --publish 127.0.0.1:$(APP_PORT):8080 $(IMAGE)

container-stop: ## Gracefully stop the local application container
	@docker stop --timeout 15 $(CONTAINER)

container-remove: ## Remove the stopped local application container
	@docker rm $(CONTAINER)

container-smoke: ## Exercise container dashboard, health, accounts, and transfer paths
	@APP_URL=http://127.0.0.1:$(APP_PORT) ./scripts/container-smoke.sh

check: preflight ## Run safe repository validation
	@git diff --check
	@bash -n scripts/*.sh
	@if command -v shellcheck >/dev/null 2>&1; then shellcheck scripts/*.sh; fi
	@echo "Bootstrap checks passed."
