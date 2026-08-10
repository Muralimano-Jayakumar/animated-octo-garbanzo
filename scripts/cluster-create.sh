#!/usr/bin/env bash

set -euo pipefail

readonly CLUSTER_NAME="muma-bank"
readonly CONFIG_FILE="cluster/kind-config.yaml"
readonly NODE_IMAGE="kindest/node:v1.36.1@sha256:3489c7674813ba5d8b1a9977baea8a6e553784dab7b84759d1014dbd78f7ebd5"

if ! colima status >/dev/null 2>&1; then
  printf 'Colima is not running. Start it before creating the cluster.\n' >&2
  exit 1
fi

if kind get clusters 2>/dev/null | grep --fixed-strings --line-regexp --quiet "${CLUSTER_NAME}"; then
  printf 'Cluster %s already exists; no changes made.\n' "${CLUSTER_NAME}"
  exit 0
fi

kind create cluster \
  --name "${CLUSTER_NAME}" \
  --config "${CONFIG_FILE}" \
  --image "${NODE_IMAGE}" \
  --wait 180s

kubectl label node "${CLUSTER_NAME}-control-plane" ingress-ready=true --overwrite
kubectl label node "${CLUSTER_NAME}-worker" workload-tier=application --overwrite
kubectl label node "${CLUSTER_NAME}-worker2" workload-tier=data --overwrite

printf 'Cluster %s created with context kind-%s.\n' "${CLUSTER_NAME}" "${CLUSTER_NAME}"
