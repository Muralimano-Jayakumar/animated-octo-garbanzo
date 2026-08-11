#!/usr/bin/env bash

set -euo pipefail

readonly NAMESPACE="muma-bank-labs"

for _ in {1..60}; do
  image_reason="$(kubectl --namespace "${NAMESPACE}" get pod -l lab=image-pull -o jsonpath='{.items[0].status.containerStatuses[0].state.waiting.reason}' 2>/dev/null || true)"
  readiness_phase="$(kubectl --namespace "${NAMESPACE}" get pod -l lab=readiness -o jsonpath='{.items[0].status.phase}' 2>/dev/null || true)"
  readiness_value="$(kubectl --namespace "${NAMESPACE}" get pod -l lab=readiness -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null || true)"
  dns_phase="$(kubectl --namespace "${NAMESPACE}" get pod dns-lab -o jsonpath='{.status.phase}' 2>/dev/null || true)"
  storage_phase="$(kubectl --namespace "${NAMESPACE}" get pvc storage-lab -o jsonpath='{.status.phase}' 2>/dev/null || true)"

  if [[ "${image_reason}" == "ErrImageNeverPull" \
    && "${readiness_phase}" == "Running" \
    && "${readiness_value}" == "false" \
    && "${dns_phase}" == "Failed" \
    && "${storage_phase}" == "Pending" ]]; then
    printf 'All four failure symptoms were reproduced and identified.\n'
    exit 0
  fi
  sleep 1
done

kubectl --namespace "${NAMESPACE}" get pods,pvc,events --sort-by=.metadata.creationTimestamp
printf 'Expected troubleshooting symptoms were not all observed.\n' >&2
exit 1
