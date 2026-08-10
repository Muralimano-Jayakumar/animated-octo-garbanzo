#!/usr/bin/env bash

set -euo pipefail

readonly NAMESPACE="muma-bank"
readonly INGRESS_NAME="muma-bank"
readonly INGRESS_URL="${INGRESS_URL:-http://muma-bank.localhost:8081}"

kubectl --namespace ingress-nginx rollout status \
  deployment/ingress-nginx-controller --timeout=180s
kubectl --namespace "${NAMESPACE}" get ingress "${INGRESS_NAME}"

health_response="$(curl --fail --silent --show-error --max-time 15 "${INGRESS_URL}/healthz")"
accounts_response="$(curl --fail --silent --show-error --max-time 15 "${INGRESS_URL}/api/v1/accounts")"

if [[ "${health_response}" != *'"status":"ok"'* ]]; then
  printf 'Unexpected health response: %s\n' "${health_response}" >&2
  exit 1
fi

if [[ "${accounts_response}" != *'"count":3'* ]]; then
  printf 'Unexpected accounts response: %s\n' "${accounts_response}" >&2
  exit 1
fi

printf 'Ingress routing passed at %s.\n' "${INGRESS_URL}"
