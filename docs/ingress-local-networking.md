# Ingress and local networking

The local cluster exposes Muma Bank through ingress-nginx at `http://muma-bank.localhost:8081`. The `.localhost` name resolves to the loopback interface, so this workflow does not edit `/etc/hosts` or expose the application on a public network interface.

## Traffic path

```text
browser or curl
  -> muma-bank.localhost:8081 (127.0.0.1)
  -> kind control-plane port 80
  -> ingress-nginx controller
  -> muma-bank ClusterIP Service port 80
  -> Flask container port 8080
```

PostgreSQL remains reachable only through its internal headless Service on port 5432. No host port or Ingress route exposes the database.

## Install and apply

```bash
colima start --cpu 4 --memory 8 --disk 60
make cluster-validate
make ingress-install
make terraform-init
make terraform-validate
make terraform-plan
terraform -chdir=terraform apply
make ingress-validate
```

The install target applies the official kind manifest pinned to ingress-nginx controller `v1.15.1`. It verifies the active kubectl context and cluster name before making changes, and it is safe to rerun.

## Inspect and troubleshoot

```bash
kubectl --namespace ingress-nginx get pods,services
kubectl --namespace muma-bank describe ingress muma-bank
kubectl --namespace muma-bank get endpointslice \
  --selector kubernetes.io/service-name=muma-bank
curl --verbose http://muma-bank.localhost:8081/healthz
```

If the hostname does not resolve in a custom DNS environment, verify it without changing system files:

```bash
curl --resolve muma-bank.localhost:8081:127.0.0.1 \
  http://muma-bank.localhost:8081/healthz
```

## Stop safely

```bash
colima stop
```

Stopping Colima releases CPU and memory while preserving the kind cluster, ingress controller, Terraform state, PostgreSQL volume, and application data.
