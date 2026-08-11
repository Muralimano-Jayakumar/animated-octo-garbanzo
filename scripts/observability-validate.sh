#!/usr/bin/env bash

set -euo pipefail

readonly NAMESPACE="monitoring"
readonly PROMETHEUS_URL="http://127.0.0.1:19090"
readonly GRAFANA_URL="http://127.0.0.1:13000"

prometheus_pid=""
grafana_pid=""

cleanup() {
  if [[ -n "${prometheus_pid}" ]]; then kill "${prometheus_pid}" 2>/dev/null || true; fi
  if [[ -n "${grafana_pid}" ]]; then kill "${grafana_pid}" 2>/dev/null || true; fi
}
trap cleanup EXIT

kubectl --namespace "${NAMESPACE}" rollout status \
  deployment/observability-kube-prometh-operator --timeout=180s
kubectl --namespace "${NAMESPACE}" rollout status \
  deployment/observability-grafana --timeout=180s
kubectl --namespace "${NAMESPACE}" rollout status \
  statefulset/prometheus-observability-kube-prometh-prometheus --timeout=180s

kubectl --namespace "${NAMESPACE}" port-forward \
  service/observability-kube-prometh-prometheus 19090:9090 >/tmp/muma-bank-prometheus.log 2>&1 &
prometheus_pid="$!"
kubectl --namespace "${NAMESPACE}" port-forward \
  service/observability-grafana 13000:80 >/tmp/muma-bank-grafana.log 2>&1 &
grafana_pid="$!"

for _ in {1..30}; do
  if curl --fail --silent --max-time 2 "${PROMETHEUS_URL}/-/ready" >/dev/null \
    && curl --fail --silent --max-time 2 "${GRAFANA_URL}/api/health" >/dev/null; then
    break
  fi
  sleep 1
done

target_response="$(curl --fail --silent --get --max-time 10 \
  --data-urlencode 'query=up{job="muma-bank"}' \
  "${PROMETHEUS_URL}/api/v1/query")"
if [[ "${target_response}" != *'"job":"muma-bank"'* || "${target_response}" != *',"1"]'* ]]; then
  printf 'Prometheus is not reporting the Muma Bank target as up: %s\n' "${target_response}" >&2
  exit 1
fi

rules_response="$(curl --fail --silent --max-time 10 "${PROMETHEUS_URL}/api/v1/rules?type=alert")"
if [[ "${rules_response}" != *'MumaBankUnavailable'* || "${rules_response}" != *'MumaBankServerErrors'* ]]; then
  printf 'Muma Bank alerting rules were not loaded.\n' >&2
  exit 1
fi

grafana_response="$(curl --fail --silent --max-time 10 "${GRAFANA_URL}/api/health")"
grafana_compact="$(printf '%s' "${grafana_response}" | tr -d '[:space:]')"
if [[ "${grafana_compact}" != *'"database":"ok"'* ]]; then
  printf 'Grafana health check failed: %s\n' "${grafana_response}" >&2
  exit 1
fi

kubectl --namespace "${NAMESPACE}" get configmap muma-bank-dashboard >/dev/null
printf 'Prometheus target, alert rules, dashboard provisioning, and Grafana health passed.\n'
