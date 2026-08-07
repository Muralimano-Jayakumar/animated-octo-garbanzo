.DEFAULT_GOAL := help

.PHONY: help preflight tool-versions check

help: ## Show available targets
	@awk 'BEGIN {FS = ":.*## "; printf "Available targets:\n"} /^[a-zA-Z_-]+:.*## / {printf "  %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

preflight: ## Report installed and missing development tools
	@./scripts/preflight.sh

tool-versions: ## Print versions without starting local services
	@./scripts/tool-versions.sh

check: preflight ## Run safe repository validation
	@git diff --check
	@bash -n scripts/*.sh
	@if command -v shellcheck >/dev/null 2>&1; then shellcheck scripts/*.sh; fi
	@echo "Bootstrap checks passed."
