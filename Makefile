.DEFAULT_GOAL := help

.PHONY: help preflight check

help: ## Show available targets
	@awk 'BEGIN {FS = ":.*## "; printf "Available targets:\n"} /^[a-zA-Z_-]+:.*## / {printf "  %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

preflight: ## Report installed and missing development tools
	@./scripts/preflight.sh

check: preflight ## Run safe bootstrap validation
	@git diff --check
	@echo "Bootstrap checks passed."
