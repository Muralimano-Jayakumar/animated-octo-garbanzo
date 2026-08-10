#!/usr/bin/env bash

set -euo pipefail

readonly CLUSTER_NAME="muma-bank"

if [[ "${CONFIRM_DELETE:-}" != "${CLUSTER_NAME}" ]]; then
  printf 'Refusing deletion. Run with CONFIRM_DELETE=%s after reviewing the target.\n' \
    "${CLUSTER_NAME}" >&2
  exit 1
fi

if ! kind get clusters 2>/dev/null | grep --fixed-strings --line-regexp --quiet "${CLUSTER_NAME}"; then
  printf 'Cluster %s does not exist; no changes made.\n' "${CLUSTER_NAME}"
  exit 0
fi

kind delete cluster --name "${CLUSTER_NAME}"
