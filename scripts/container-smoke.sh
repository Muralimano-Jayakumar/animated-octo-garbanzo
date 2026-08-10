#!/usr/bin/env bash

set -euo pipefail

readonly APP_URL="${APP_URL:-http://127.0.0.1:8080}"
readonly MAX_ATTEMPTS="${MAX_ATTEMPTS:-20}"

wait_for_health() {
  local attempt
  for ((attempt = 1; attempt <= MAX_ATTEMPTS; attempt += 1)); do
    if curl --fail --silent --show-error "${APP_URL}/healthz" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done

  printf 'Application did not become healthy after %s attempts.\n' "${MAX_ATTEMPTS}" >&2
  return 1
}

wait_for_health

curl --fail --silent --show-error "${APP_URL}/" | grep --quiet "Muma Bank"
curl --fail --silent --show-error "${APP_URL}/readyz" | grep --quiet '"status":"ready"'
curl --fail --silent --show-error "${APP_URL}/api/v1/accounts" | grep --quiet '"count":3'
curl --fail --silent --show-error \
  --request POST \
  --header 'Content-Type: application/json' \
  --header 'X-Request-ID: container-smoke-test' \
  --data '{"source_account_id":"ACC-1001","destination_account_id":"ACC-1002","amount":"10.00"}' \
  "${APP_URL}/api/v1/transfers" | grep --quiet '"amount":"10.00"'

printf 'Container smoke test passed for %s.\n' "${APP_URL}"
