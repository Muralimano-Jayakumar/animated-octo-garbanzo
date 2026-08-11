# Engineering evidence

This repository demonstrates an incremental DevOps delivery history rather than a single bulk upload.

| Capability | Evidence |
| --- | --- |
| Source control | Conventional commits, phase branches, draft PRs, reviews, and merge history |
| Work management | Focused GitHub issues with acceptance criteria and testing requirements |
| Application engineering | Flask dashboard/API, domain validation, PostgreSQL repository, 90% coverage gate |
| Containers | Multi-stage non-root image, read-only runtime, pinned base digest, Trivy policy |
| Kubernetes | Three-node kind cluster, probes, resources, Services, Ingress, StatefulSet, PVC |
| Infrastructure as code | Terraform plan/apply workflow, generated credentials, drift validation |
| Security | Restricted Pod Security, tokenless identities, no RBAC grants, NetworkPolicy intent, Gitleaks |
| CI/CD | Five read-only GitHub Actions checks with immutable action references and Dependabot |
| Observability | Prometheus metrics, Grafana dashboard, alerts, resource bounds, validation |
| Operations | Startup/shutdown runbook, persistence test, disaster-recovery boundaries |
| Troubleshooting | Four reproducible failure and recovery labs with guarded cleanup |

## Review narrative

A reviewer can follow the repository history phase by phase: bootstrap, local tooling, Flask application, containerization, kind, Terraform, PostgreSQL, ingress, network security, CI, observability, troubleshooting, and documentation. Each phase supplies code, validation evidence, and operational context.

## Demonstration sequence

1. Show a clean CI run and the pull-request history.
2. Start Colima and validate the three-node cluster.
3. Open Muma Bank through ingress and submit a transfer.
4. Recreate the PostgreSQL Pod and show the changed balance persists.
5. Open the Grafana dashboard and Prometheus target.
6. Run one troubleshooting lab from symptom through recovery.
7. Stop Colima and explain what is preserved.

The architecture intentionally documents its limitations: local-only infrastructure, one PostgreSQL replica, ephemeral monitoring history, and non-enforcing kindnet NetworkPolicies. Calling out those tradeoffs is part of the engineering evidence.
