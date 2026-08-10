# Kubernetes network security

The `muma-bank` namespace uses least-privilege workload identities and an explicit default-deny network model.

## Controls

- Dedicated `muma-bank` and `muma-bank-postgres` ServiceAccounts have token automount disabled and receive no RBAC grants.
- `default-deny-all` selects every namespace pod for ingress and egress isolation.
- ingress-nginx controller pods may reach only application port 8080.
- application pods may send DNS requests only to CoreDNS and database traffic only to PostgreSQL port 5432.
- PostgreSQL accepts port 5432 traffic only from application pods and has no allowed egress.
- The database remains behind a headless ClusterIP Service with no Ingress or host port.
- The namespace continues enforcing the Kubernetes restricted Pod Security Standard.

## Validate

```bash
colima start --cpu 4 --memory 8 --disk 60
make cluster-validate
make ingress-install
terraform -chdir=terraform apply
make network-security-validate
terraform -chdir=terraform plan
```

The validator checks five NetworkPolicy objects, workload ServiceAccount assignment, denial of Secret reads through Kubernetes RBAC, and the application health and accounts API through ingress-nginx.

## Local CNI limitation

The preserved cluster uses kind's default `kindnet` CNI. Kubernetes accepts and stores NetworkPolicy resources, but kindnet does not enforce their packet-filtering rules. The policies in this phase therefore define and validate the intended security contract, while deny-path runtime enforcement remains unavailable in this existing cluster.

Do not claim deny-path enforcement based only on these tests. Enabling it requires intentionally rebuilding the cluster with `disableDefaultCNI: true` and installing a pinned policy-capable CNI such as Calico or Cilium. A cluster rebuild deletes the current kind nodes and their locally provisioned PostgreSQL volume, so it must be planned as a separate, explicitly approved migration with backup and restore steps.

## Inspect

```bash
kubectl --namespace muma-bank get serviceaccounts,networkpolicies
kubectl --namespace muma-bank describe networkpolicy default-deny-all
kubectl auth can-i get secrets \
  --namespace muma-bank \
  --as system:serviceaccount:muma-bank:muma-bank
```

The final command must return `no`.
