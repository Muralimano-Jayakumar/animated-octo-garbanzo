#!/usr/bin/env bash

set -euo pipefail

printf '%s\n' "$(git --version)"
gh --version | sed -n '1p'
printf 'colima %s\n' "$(brew list --versions colima | awk '{print $2}')"
docker --version
kubectl version --client=true
kind version
terraform version | sed -n '1p'
helm version --short
make --version | sed -n '1p'
printf 'gitleaks %s\n' "$(gitleaks version)"
shellcheck --version | awk '/version:/{print "ShellCheck " $2}'
hadolint --version
trivy --version | sed -n '1p'
python3 --version
