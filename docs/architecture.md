# Platform architecture

Muma Bank is a local, multi-node Kubernetes learning platform designed to demonstrate application delivery, infrastructure as code, persistence, security, CI, observability, and operations as one coherent system.

## Components

```mermaid
flowchart LR
    User[Browser or curl] -->|HTTP 8081| KindPort[Loopback kind port]
    KindPort --> Ingress[ingress-nginx]
    Ingress --> Service[Muma Bank Service]
    Service --> Flask[Flask and Gunicorn Pod]
    Flask -->|SQL 5432| PgService[Headless PostgreSQL Service]
    PgService --> Postgres[(PostgreSQL StatefulSet)]
    Postgres --> PVC[(1 GiB PVC)]
    Prometheus[Prometheus] -->|scrape /metrics| Service
    Prometheus --> Grafana[Grafana dashboards]
    Prometheus --> Alerts[Prometheus alert rules]
```

All host exposure is bound to loopback. The application is available at `http://muma-bank.localhost:8081`; PostgreSQL, Prometheus, and Grafana remain ClusterIP-only and require explicit local port-forwarding.

## Cluster topology

```mermaid
flowchart TB
    Mac[macOS host] --> Colima[Colima VM: 4 CPU, 8 GiB RAM, 60 GiB disk]
    Colima --> CP[kind control plane: ingress-ready]
    Colima --> Worker1[kind worker: application]
    Colima --> Worker2[kind worker: data]
    CP --> Ingress[ingress-nginx]
    Worker1 --> App[Muma Bank]
    Worker1 --> Monitoring[Prometheus stack]
    Worker2 --> DB[PostgreSQL and PVC]
```

The scheduler may move ordinary workloads because the labels are educational placement hints, not mandatory affinity rules. PostgreSQL storage is node-local to the kind environment.

## Request and data flow

```mermaid
sequenceDiagram
    participant C as Client
    participant I as ingress-nginx
    participant A as Flask API
    participant D as PostgreSQL
    participant P as Prometheus
    C->>I: GET or POST muma-bank.localhost:8081
    I->>A: ClusterIP HTTP request
    A->>D: Transaction with row locks
    D-->>A: Committed balances
    A-->>I: JSON or HTML plus request ID
    I-->>C: HTTP response
    P->>A: GET /metrics through internal Service
    A-->>P: Prometheus exposition format
```

Transfers lock both account rows in deterministic order and commit the debit and credit atomically. The PVC preserves database files across PostgreSQL Pod recreation.

## Delivery flow

```mermaid
flowchart LR
    Issue[GitHub Issue] --> Branch[Feature branch]
    Branch --> Commit[Conventional commit]
    Commit --> PR[Draft Pull Request]
    PR --> CI{Five CI checks}
    CI -->|pass| Review[Code review]
    Review --> Merge[Merge to main]
    Merge --> Dependabot[Weekly dependency updates]
```

CI performs Python tests, Terraform validation, ShellCheck, Gitleaks, and Trivy scanning with read-only repository permissions. Deployment remains a deliberate local operator action.

## Trust boundaries

- The Mac-to-cluster boundary is loopback-only.
- ingress-nginx is the only intended application entry point.
- dedicated ServiceAccounts receive no RBAC grants or mounted tokens.
- Kubernetes Secrets hold generated database and Grafana credentials; Terraform state remains local and ignored.
- NetworkPolicies describe default-deny intent, but the preserved kindnet CNI does not enforce them. See [network security](network-security.md).
