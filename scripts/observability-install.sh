#!/usr/bin/env bash

set -euo pipefail

readonly EXPECTED_CONTEXT="kind-muma-bank"
readonly NAMESPACE="monitoring"
readonly RELEASE="observability"
readonly CHART="oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack"
readonly CHART_VERSION="87.12.2"

if [[ "$(kubectl config current-context)" != "${EXPECTED_CONTEXT}" ]]; then
  printf 'Expected kubectl context %s; refusing to modify another cluster.\n' "${EXPECTED_CONTEXT}" >&2
  exit 1
fi

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

if ! kubectl --namespace "${NAMESPACE}" get secret observability-grafana-admin >/dev/null 2>&1; then
  grafana_password="$(openssl rand -base64 32)"
  kubectl --namespace "${NAMESPACE}" create secret generic observability-grafana-admin \
    --from-literal=admin-user=admin \
    --from-literal="admin-password=${grafana_password}"
fi

helm upgrade --install "${RELEASE}" "${CHART}" \
  --namespace "${NAMESPACE}" \
  --version "${CHART_VERSION}" \
  --values monitoring/kube-prometheus-stack-values.yaml \
  --wait \
  --timeout 10m

kubectl apply --filename monitoring/muma-bank-rules.yaml
kubectl --namespace "${NAMESPACE}" create configmap muma-bank-dashboard \
  --from-file=muma-bank.json=monitoring/dashboards/muma-bank.json \
  --dry-run=client -o yaml \
  | kubectl label --local --filename - grafana_dashboard=1 -o yaml \
  | kubectl apply -f -

printf 'Observability stack chart %s is ready.\n' "${CHART_VERSION}"
