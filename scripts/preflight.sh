#!/usr/bin/env bash

set -u

readonly TOOLS=(
  git
  gh
  colima
  docker
  kubectl
  kind
  terraform
  helm
  make
  gitleaks
  shellcheck
  hadolint
  trivy
  python3
)

installed=()
missing=()

printf 'Muma Bank Kubernetes Platform preflight\n'
printf 'Working directory: %s\n\n' "$(pwd)"

for tool in "${TOOLS[@]}"; do
  if command -v "${tool}" >/dev/null 2>&1; then
    installed+=("${tool}")
    printf '[installed] %-10s %s\n' "${tool}" "$(command -v "${tool}")"
  else
    missing+=("${tool}")
    printf '[missing]   %s\n' "${tool}"
  fi
done

printf '\nInstalled tools (%d): %s\n' "${#installed[@]}" "${installed[*]:-none}"
printf 'Missing tools (%d): %s\n' "${#missing[@]}" "${missing[*]:-none}"

if command -v gh >/dev/null 2>&1; then
  printf '\nGitHub CLI authentication:\n'
  gh auth status || true
fi

printf '\nPreflight is informational; no services were started and no resources were changed.\n'
