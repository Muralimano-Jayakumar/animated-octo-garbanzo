#!/usr/bin/env bash

set -euo pipefail

readonly NAMESPACE="muma-bank"

kubectl --namespace "${NAMESPACE}" rollout status deployment/muma-bank --timeout=180s
kubectl --namespace "${NAMESPACE}" rollout status statefulset/muma-bank-postgres --timeout=180s

policy_count="$(kubectl --namespace "${NAMESPACE}" get networkpolicy --no-headers | wc -l | tr -d ' ')"
if [[ "${policy_count}" != "6" ]]; then
  printf 'Expected 6 NetworkPolicies, found %s.\n' "${policy_count}" >&2
  exit 1
fi

application_account="$(kubectl --namespace "${NAMESPACE}" get deployment muma-bank -o jsonpath='{.spec.template.spec.serviceAccountName}')"
database_account="$(kubectl --namespace "${NAMESPACE}" get statefulset muma-bank-postgres -o jsonpath='{.spec.template.spec.serviceAccountName}')"

if [[ "${application_account}" != "muma-bank" || "${database_account}" != "muma-bank-postgres" ]]; then
  printf 'Workloads are not using the expected dedicated ServiceAccounts.\n' >&2
  exit 1
fi

if [[ "$(kubectl auth can-i get secrets --namespace "${NAMESPACE}" --as "system:serviceaccount:${NAMESPACE}:muma-bank")" != "no" ]]; then
  printf 'Application ServiceAccount unexpectedly has permission to read Secrets.\n' >&2
  exit 1
fi

if [[ "$(kubectl auth can-i get secrets --namespace "${NAMESPACE}" --as "system:serviceaccount:${NAMESPACE}:muma-bank-postgres")" != "no" ]]; then
  printf 'Database ServiceAccount unexpectedly has permission to read Secrets.\n' >&2
  exit 1
fi

make ingress-validate

if kubectl --namespace kube-system get daemonset kindnet >/dev/null 2>&1; then
  printf 'NOTICE: kindnet does not enforce NetworkPolicy. Policy objects and allowed paths were validated, but deny-path enforcement requires a policy-capable CNI in a future cluster rebuild.\n'
fi

printf 'Network security structure and allowed-path validation passed.\n'
