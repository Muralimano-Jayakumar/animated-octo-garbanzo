# Terraform-managed Kubernetes resources

Terraform manages the initial Muma Bank workload in the existing `kind-muma-bank` cluster.

## Managed resources

- namespace `muma-bank` with the restricted Pod Security Standard;
- ConfigMap containing non-secret Gunicorn configuration;
- single-replica Deployment using `muma-bank:dev` with local image pulls disabled;
- non-root, read-only, capability-dropped container security context;
- startup, readiness, and liveness HTTP probes;
- CPU and memory requests and limits;
- internal ClusterIP Service on port 80.

The replica count is deliberately restricted to one while account data remains in memory. PostgreSQL persistence is required before horizontal scaling.

## Prerequisites

```bash
colima start
make cluster-validate
make cluster-load-image
```

Confirm the active context before planning:

```bash
kubectl config current-context
```

Expected: `kind-muma-bank`.

## Initialize and review

```bash
make terraform-fmt
make terraform-init
make terraform-validate
make terraform-plan
```

Review every create, update, and delete action before applying. Local state and plan files are excluded from Git.

## Apply and validate

```bash
terraform -chdir=terraform apply
kubectl --namespace muma-bank rollout status deployment/muma-bank --timeout=180s
kubectl --namespace muma-bank get all
terraform -chdir=terraform plan
```

The second plan should report no changes.

## Access locally

Start a foreground port-forward:

```bash
kubectl --namespace muma-bank port-forward service/muma-bank 8080:80
```

Open `http://127.0.0.1:8080`. Stop the port-forward with `Ctrl+C`.

## Stop safely

Stopping Colima preserves the kind cluster, workload, and Terraform state while releasing runtime CPU and memory:

```bash
colima stop
```

Terraform destroy is intentionally excluded from Make targets. If resources must be removed later, review `terraform -chdir=terraform plan -destroy` before explicitly running destroy.
