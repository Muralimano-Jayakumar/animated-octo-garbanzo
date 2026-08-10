#!/usr/bin/env bash

set -euo pipefail

readonly CLUSTER_NAME="muma-bank"
readonly EXPECTED_CONTEXT="kind-${CLUSTER_NAME}"
readonly CONTROLLER_VERSION="v1.15.1"
readonly MANIFEST_URL="https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-${CONTROLLER_VERSION}/deploy/static/provider/kind/deploy.yaml"

if ! colima status >/dev/null 2>&1; then
  printf 'Colima is not running. Start it before installing ingress-nginx.\n' >&2
  exit 1
fi

if [[ "$(kubectl config current-context)" != "${EXPECTED_CONTEXT}" ]]; then
  printf 'Expected kubectl context %s; refusing to modify another cluster.\n' "${EXPECTED_CONTEXT}" >&2
  exit 1
fi

if ! kind get clusters | grep --fixed-strings --line-regexp --quiet "${CLUSTER_NAME}"; then
  printf 'Cluster %s does not exist. Run make cluster-create first.\n' "${CLUSTER_NAME}" >&2
  exit 1
fi

kubectl apply --server-side --filename "${MANIFEST_URL}"
kubectl --namespace ingress-nginx patch deployment ingress-nginx-controller \
  --type merge \
  --patch '{"spec":{"template":{"spec":{"nodeSelector":{"ingress-ready":"true","kubernetes.io/os":"linux"}}}}}'
kubectl --namespace ingress-nginx rollout status \
  deployment/ingress-nginx-controller --timeout=180s

printf 'ingress-nginx %s is ready on cluster %s.\n' "${CONTROLLER_VERSION}" "${CLUSTER_NAME}"
