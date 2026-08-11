# Observability

Muma Bank exports Prometheus metrics and runs a resource-bounded local monitoring stack from the official `kube-prometheus-stack` chart pinned to `87.12.2`.

## Signals

- `muma_bank_http_requests_total` counts requests by method, endpoint, and status.
- `muma_bank_http_request_duration_seconds` measures endpoint latency.
- `muma_bank_transfers_total` counts successful transfers.
- Standard kube-prometheus components expose Kubernetes workload and node health.

The `/metrics` endpoint is scraped directly through the internal ClusterIP Service. Requests forwarded by ingress-nginx receive a 404, preventing the metrics payload from being exposed through the public application route.

## Install

```bash
colima start --cpu 4 --memory 8 --disk 60
make container-build
make cluster-load-image
kubectl --namespace muma-bank delete pod \
  --selector app.kubernetes.io/component=api
kubectl --namespace muma-bank rollout status deployment/muma-bank --timeout=180s
terraform -chdir=terraform apply
make observability-install
make observability-validate
```

The installation script creates a random Grafana administrator password only when the Secret does not already exist. It never prints the password. The Helm command is idempotent and uses the committed local values file.

## Access Prometheus

```bash
kubectl --namespace monitoring port-forward \
  service/observability-kube-prometh-prometheus 9090:9090
```

Open `http://127.0.0.1:9090` and query:

```promql
up{job="muma-bank"}
sum(rate(muma_bank_http_requests_total[5m]))
histogram_quantile(0.95, sum by (le) (rate(muma_bank_http_request_duration_seconds_bucket[5m])))
```

## Access Grafana

Retrieve the generated password without printing it into shared logs:

```bash
kubectl --namespace monitoring get secret observability-grafana-admin \
  --output jsonpath='{.data.admin-password}' | base64 --decode
```

Then start a local port-forward:

```bash
kubectl --namespace monitoring port-forward service/observability-grafana 3000:80
```

Open `http://127.0.0.1:3000`, sign in as `admin`, and open the provisioned **Muma Bank** dashboard.

## Alerts

- `MumaBankUnavailable` fires when the application target is down for two minutes.
- `MumaBankServerErrors` fires when sustained HTTP 5xx responses are observed.

Alertmanager is local and has no external receiver, so this phase does not send notifications outside the workstation.

## Stop safely

Stop port-forward processes with `Ctrl+C`, then run:

```bash
colima stop
```

The monitoring stack uses ephemeral storage. Stopping Colima preserves its pods; deleting the cluster removes Prometheus history and generated Grafana credentials but does not affect source files.
