# Terraform-managed Kubernetes resources

Terraform manages the initial Muma Bank workload in the existing `kind-muma-bank` cluster.

## Managed resources

- namespace `muma-bank` with the restricted Pod Security Standard;
- ConfigMap containing non-secret Gunicorn configuration;
- application Deployment using `muma-bank:dev` with local image pulls disabled;
- non-root, read-only, capability-dropped container security context;
- startup, readiness, and liveness HTTP probes;
- CPU and memory requests and limits;
- internal ClusterIP Service on port 80.
- generated PostgreSQL credentials stored in Kubernetes Secrets;
- headless PostgreSQL Service and single-replica StatefulSet;
- 1 GiB `ReadWriteOnce` persistent volume claim using kind's `standard` StorageClass;
- database probes, resource controls, and a restricted non-root security context.

Terraform state contains the generated password and must remain local and protected. Never commit state, plan files, variable files, or decoded Secret values.

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
kubectl --namespace muma-bank rollout status statefulset/muma-bank-postgres --timeout=180s
kubectl --namespace muma-bank get pods,services,pvc
terraform -chdir=terraform plan
```

The second plan should report no changes.

## Verify persistence

Submit a transfer through the application, record the resulting balance, and recreate only the database pod:

```bash
kubectl --namespace muma-bank delete pod muma-bank-postgres-0
kubectl --namespace muma-bank rollout status statefulset/muma-bank-postgres --timeout=180s
kubectl --namespace muma-bank get pvc data-muma-bank-postgres-0
```

Query the account again through the application. The changed balance must remain and the claim must remain `Bound`. Pod recreation is safe for this test; deleting the claim or cluster is not part of it.

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
