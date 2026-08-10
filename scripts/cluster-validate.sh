#!/usr/bin/env bash

set -euo pipefail

readonly CLUSTER_NAME="muma-bank"
readonly EXPECTED_CONTEXT="kind-${CLUSTER_NAME}"
readonly EXPECTED_NODES=3
readonly API_ATTEMPTS=60

current_context="$(kubectl config current-context)"
if [[ "${current_context}" != "${EXPECTED_CONTEXT}" ]]; then
  printf 'Expected context %s, found %s.\n' "${EXPECTED_CONTEXT}" "${current_context}" >&2
  exit 1
fi

api_ready=false
for ((attempt = 1; attempt <= API_ATTEMPTS; attempt += 1)); do
  if kubectl --request-timeout=2s get --raw=/readyz >/dev/null 2>&1 \
    && [[ "$(kubectl auth can-i get nodes 2>/dev/null)" == "yes" ]]; then
    api_ready=true
    break
  fi
  sleep 2
done

if [[ "${api_ready}" != "true" ]]; then
  printf 'Kubernetes API did not become ready and authorized after %d attempts.\n' \
    "${API_ATTEMPTS}" >&2
  exit 1
fi

node_count="$(kubectl get nodes --output=name | wc -l | tr -d ' ')"
if [[ "${node_count}" -ne "${EXPECTED_NODES}" ]]; then
  printf 'Expected %d nodes, found %s.\n' "${EXPECTED_NODES}" "${node_count}" >&2
  exit 1
fi

kubectl wait --for=condition=Ready nodes --all --timeout=180s
kubectl wait --namespace kube-system --for=condition=Ready pods --all --timeout=180s

control_plane_count="$(kubectl get nodes --selector='node-role.kubernetes.io/control-plane' --output=name | wc -l | tr -d ' ')"
worker_count="$(kubectl get nodes --selector='!node-role.kubernetes.io/control-plane' --output=name | wc -l | tr -d ' ')"

if [[ "${control_plane_count}" -ne 1 || "${worker_count}" -ne 2 ]]; then
  printf 'Expected one control-plane and two workers; found %s and %s.\n' \
    "${control_plane_count}" "${worker_count}" >&2
  exit 1
fi

kubectl get nodes --output=wide
kubectl get pods --namespace kube-system --output=wide
printf 'Cluster %s validation passed.\n' "${CLUSTER_NAME}"
