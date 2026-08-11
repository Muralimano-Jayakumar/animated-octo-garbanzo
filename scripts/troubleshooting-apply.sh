#!/usr/bin/env bash

set -euo pipefail

readonly EXPECTED_CONTEXT="kind-muma-bank"
readonly NAMESPACE="muma-bank-labs"

if [[ "$(kubectl config current-context)" != "${EXPECTED_CONTEXT}" ]]; then
  printf 'Expected kubectl context %s; refusing to modify another cluster.\n' "${EXPECTED_CONTEXT}" >&2
  exit 1
fi

kubectl apply --filename troubleshooting/namespace.yaml
kubectl apply --filename troubleshooting/broken/

printf 'Broken scenarios applied only in namespace %s.\n' "${NAMESPACE}"
