# Architecture decisions

## ADR-001: Colima and kind for local Kubernetes

**Status:** Accepted

Colima provides a lightweight macOS container VM, while kind supplies reproducible multi-node Kubernetes. This combination supports realistic node, ingress, storage, and troubleshooting exercises without a cloud bill. The tradeoff is that node-local data belongs to the workstation and is not highly available.

## ADR-002: Terraform manages application resources

**Status:** Accepted

Terraform manages the namespace, identities, configuration, Secrets, workload controllers, Services, Ingress, storage, and NetworkPolicies. Local state is intentionally ignored and never committed. Cluster add-ons use pinned, idempotent scripts because their CRDs must exist before dependent custom resources can be applied.

## ADR-003: PostgreSQL StatefulSet with local persistence

**Status:** Accepted

PostgreSQL runs as one StatefulSet replica with a `ReadWriteOnce` claim. This proves stable identity and persistence across Pod recreation while remaining resource-conscious. It does not provide database high availability; loss of the kind cluster requires restoration from backup.

## ADR-004: Generated credentials and no committed secrets

**Status:** Accepted

Terraform generates the database password, while the observability installer generates the Grafana password once. Neither value is printed or committed. This reduces accidental exposure but means Terraform state and the local cluster are sensitive assets.

## ADR-005: Loopback ingress without `/etc/hosts`

**Status:** Accepted

`muma-bank.localhost` resolves to loopback and reaches an ingress controller through kind port 8081. This avoids privileged host-file changes and external network exposure. HTTPS is reserved but not configured because local certificate lifecycle is outside the current learning scope.

## ADR-006: Explicit NetworkPolicies with a documented CNI gap

**Status:** Accepted with limitation

Default-deny and narrow allow rules document the intended network contract. kindnet does not enforce NetworkPolicy, so runtime deny guarantees are not claimed. A policy-capable CNI migration requires a separately approved cluster rebuild and database restore exercise.

## ADR-007: Prometheus and Grafana as an ephemeral local stack

**Status:** Accepted

The pinned kube-prometheus-stack provides standard metrics, dashboards, and alerts with resource limits and six-hour retention. Monitoring history is disposable; application data is not. External alert delivery and durable metric storage are intentionally excluded.

## ADR-008: Pull-request delivery with immutable CI actions

**Status:** Accepted

Each phase uses an issue, feature branch, conventional commit, draft PR, and review. CI actions are pinned to full commits and receive read-only contents permission. CI validates but never deploys, keeping environment mutation under operator control.
