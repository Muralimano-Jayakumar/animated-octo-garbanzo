#!/usr/bin/env bash

set -euo pipefail

readonly CLUSTER_NAME="muma-bank"
readonly IMAGE="${IMAGE:-muma-bank:dev}"

if ! docker image inspect "${IMAGE}" >/dev/null 2>&1; then
  printf 'Local image %s does not exist. Build it before loading.\n' "${IMAGE}" >&2
  exit 1
fi

kind load docker-image "${IMAGE}" --name "${CLUSTER_NAME}"

for node in \
  "${CLUSTER_NAME}-control-plane" \
  "${CLUSTER_NAME}-worker" \
  "${CLUSTER_NAME}-worker2"; do
  if ! docker exec "${node}" crictl images --output json | grep --fixed-strings --quiet 'muma-bank'; then
    printf 'Image %s was not found on node %s.\n' "${IMAGE}" "${node}" >&2
    exit 1
  fi
done

printf 'Image %s is available on every %s node.\n' "${IMAGE}" "${CLUSTER_NAME}"
