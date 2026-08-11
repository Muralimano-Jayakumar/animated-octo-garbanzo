# Operations runbook

## Start the platform

From the repository root:

```bash
pwd
colima start --cpu 4 --memory 8 --disk 60
make cluster-validate
make ingress-install
terraform -chdir=terraform init
terraform -chdir=terraform apply
make observability-install
```

Expected repository path: `/Users/muralimano/Desktop/mcp-workspace/kube-proj`.

## Validate health

```bash
kubectl --namespace muma-bank get pods,services,pvc,ingress
kubectl --namespace muma-bank rollout status deployment/muma-bank --timeout=180s
kubectl --namespace muma-bank rollout status statefulset/muma-bank-postgres --timeout=180s
make ingress-validate
make network-security-validate
make observability-validate
terraform -chdir=terraform plan
```

Terraform should report no changes. The application is available at `http://muma-bank.localhost:8081`.

## Routine inspection

```bash
kubectl get nodes --output=wide
kubectl get pods --all-namespaces --output=wide
kubectl --namespace muma-bank get events --sort-by=.metadata.creationTimestamp
kubectl --namespace muma-bank logs deployment/muma-bank --tail=100
kubectl --namespace muma-bank logs statefulset/muma-bank-postgres --tail=100
```

Do not print Secret values while collecting incident evidence.

## Incident triage

1. Establish scope with `kubectl get pods --all-namespaces`.
2. Inspect controller rollout status and Pod events.
3. Check application and database logs without exposing environment variables.
4. Test `/healthz`, `/readyz`, Service endpoints, DNS, and Ingress in that order.
5. Check PVC state before restarting or replacing database resources.
6. Query Prometheus target status and active alerts.
7. Compare deployed resources with `terraform plan` before changing anything.
8. Record the symptom, evidence, root cause, remediation, and prevention in the issue or PR.

The [troubleshooting labs](troubleshooting-labs.md) provide worked examples.

## Safe shutdown

Stop foreground port-forwards with `Ctrl+C`, then:

```bash
colima stop
```

This preserves kind containers, PostgreSQL storage, monitoring resources, and local Terraform state while releasing CPU and memory.

## Actions that require explicit review

- `terraform destroy`
- `kind delete cluster`
- deleting the PostgreSQL PVC
- changing storage classes
- rebuilding the cluster CNI
- force pushes or history rewriting

Never use `git push --force`, `git reset --hard`, or broad recursive deletion as an operational shortcut.
