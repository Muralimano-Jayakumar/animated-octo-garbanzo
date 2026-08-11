#!/usr/bin/env bash

set -euo pipefail

readonly NAMESPACE="muma-bank-labs"

kubectl apply --filename troubleshooting/recovery/image-pull.yaml
kubectl apply --filename troubleshooting/recovery/readiness.yaml
kubectl --namespace "${NAMESPACE}" delete pod dns-lab --ignore-not-found --wait=true
kubectl apply --filename troubleshooting/recovery/dns.yaml
kubectl --namespace "${NAMESPACE}" delete pvc storage-lab --ignore-not-found --wait=true
kubectl apply --filename troubleshooting/recovery/storage.yaml

kubectl --namespace "${NAMESPACE}" rollout status deployment/image-pull-lab --timeout=180s
kubectl --namespace "${NAMESPACE}" rollout status deployment/readiness-lab --timeout=180s
kubectl --namespace "${NAMESPACE}" wait --for=jsonpath='{.status.phase}'=Succeeded pod/dns-lab --timeout=180s
kubectl --namespace "${NAMESPACE}" wait --for=jsonpath='{.status.phase}'=Bound pvc/storage-lab --timeout=180s
kubectl --namespace "${NAMESPACE}" wait --for=condition=Ready pod/storage-lab --timeout=180s

printf 'All four troubleshooting scenarios recovered successfully.\n'
