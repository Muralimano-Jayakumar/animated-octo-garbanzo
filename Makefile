.DEFAULT_GOAL := help

PYTHON ?= python3
VENV ?= .venv
IMAGE ?= muma-bank:dev
CONTAINER ?= muma-bank-local
APP_PORT ?= 8080

.PHONY: help preflight tool-versions app-install app-test app-run container-build container-scan container-run container-stop container-remove container-smoke cluster-create cluster-validate cluster-load-image cluster-delete ingress-install ingress-validate network-security-validate observability-install observability-validate troubleshooting-apply troubleshooting-validate troubleshooting-recover troubleshooting-cleanup terraform-fmt terraform-init terraform-validate terraform-plan docs-validate release-validate check

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

cluster-create: ## Create the local three-node kind cluster
	@./scripts/cluster-create.sh

cluster-validate: ## Validate kind node and system-pod readiness
	@./scripts/cluster-validate.sh

cluster-load-image: ## Load the application image onto every kind node
	@IMAGE=$(IMAGE) ./scripts/cluster-load-image.sh

cluster-delete: ## Delete only the named cluster with explicit confirmation
	@CONFIRM_DELETE=$(CONFIRM_DELETE) ./scripts/cluster-delete.sh

ingress-install: ## Install or reconcile the pinned ingress-nginx cluster add-on
	@./scripts/ingress-install.sh

ingress-validate: ## Validate ingress controller readiness and local HTTP routing
	@./scripts/ingress-validate.sh

network-security-validate: ## Validate workload identities, policies, and allowed traffic
	@./scripts/network-security-validate.sh

observability-install: ## Install the pinned local Prometheus and Grafana stack
	@./scripts/observability-install.sh

observability-validate: ## Validate Prometheus scraping, alerts, and Grafana health
	@./scripts/observability-validate.sh

troubleshooting-apply: ## Apply isolated broken scenarios in muma-bank-labs
	@./scripts/troubleshooting-apply.sh

troubleshooting-validate: ## Verify the expected failure symptoms
	@./scripts/troubleshooting-validate.sh

troubleshooting-recover: ## Apply recoveries and verify healthy resources
	@./scripts/troubleshooting-recover.sh

troubleshooting-cleanup: ## Delete labs only with CONFIRM_DELETE=muma-bank-labs
	@CONFIRM_DELETE=$(CONFIRM_DELETE) ./scripts/troubleshooting-cleanup.sh

terraform-fmt: ## Format Terraform configuration
	@terraform -chdir=terraform fmt -recursive

terraform-init: ## Initialize the local Terraform working directory
	@terraform -chdir=terraform init

terraform-validate: ## Validate initialized Terraform configuration
	@terraform -chdir=terraform validate

terraform-plan: ## Show the Kubernetes resource plan without applying it
	@terraform -chdir=terraform plan

docs-validate: ## Validate required documentation and local Markdown links
	@./scripts/docs-validate.sh

release-validate: ## Validate release version, notes, and tracked-file safety
	@./scripts/release-validate.sh

check: preflight ## Run safe repository validation
	@git diff --check
	@bash -n scripts/*.sh
	@if command -v shellcheck >/dev/null 2>&1; then shellcheck scripts/*.sh; fi
	@$(MAKE) --no-print-directory docs-validate
	@echo "Bootstrap checks passed."
