# Changelog

All notable changes to this project are documented here. The project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

No changes yet.

## [1.0.0] - 2026-08-11

### Added

- Responsive Flask banking dashboard and API with validated, atomic account transfers.
- PostgreSQL persistence through a Kubernetes StatefulSet and persistent volume claim.
- Multi-stage, non-root container image with health checks and security scanning.
- Reproducible three-node kind cluster running through Colima on macOS.
- Terraform-managed Kubernetes workloads, identities, Services, Ingress, Secrets, storage, and NetworkPolicies.
- Loopback-only ingress at `muma-bank.localhost:8081` without modifying `/etc/hosts`.
- Prometheus metrics, alert rules, and a Grafana dashboard.
- GitHub Actions validation for application code, Terraform, shell scripts, secrets, containers, and documentation.
- Reproducible Kubernetes troubleshooting labs and operational recovery guidance.
- Architecture diagrams, decisions, runbooks, disaster-recovery boundaries, and portfolio evidence.

### Security

- Restricted Pod Security enforcement, tokenless ServiceAccounts, non-root containers, read-only root filesystems, and default-deny NetworkPolicy intent.
- Protected `main` branch with required CI checks, review approval, resolved conversations, and force-push/deletion prevention.

[Unreleased]: https://github.com/Muralimano-Jayakumar/animated-octo-garbanzo/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Muralimano-Jayakumar/animated-octo-garbanzo/releases/tag/v1.0.0
