#!/usr/bin/env bash

set -euo pipefail

readonly NAMESPACE="muma-bank-labs"

if [[ "${CONFIRM_DELETE:-}" != "${NAMESPACE}" ]]; then
  printf 'Refusing cleanup. Run CONFIRM_DELETE=%s make troubleshooting-cleanup\n' "${NAMESPACE}" >&2
  exit 1
fi

kubectl delete namespace "${NAMESPACE}" --wait=true
printf 'Deleted only troubleshooting namespace %s.\n' "${NAMESPACE}"
