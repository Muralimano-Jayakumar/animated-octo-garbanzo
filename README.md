# Muma Bank Kubernetes Platform

A hands-on DevOps learning platform for building, containerizing, deploying, securing, observing, and troubleshooting a small banking application on a local multi-node Kubernetes environment.

## Status

Phase 0 and Phase 1 establish the local workspace, development-tool preflight, repository standards, and GitHub workflow. No cluster or application workload is created during this bootstrap phase.

## Planned architecture

The project will evolve in feature branches and pull requests to include:

- a Flask banking demo application;
- container images and local image workflows;
- a multi-node kind cluster running on Colima;
- Terraform-managed Kubernetes resources;
- PostgreSQL with persistent storage;
- ingress, network policy, and security controls;
- CI validation and security scanning;
- metrics, dashboards, and troubleshooting labs.

## Repository layout

```text
.
├── app/          # Application source and tests
├── cluster/      # Local Kubernetes cluster configuration
├── docs/         # Architecture and operational documentation
├── monitoring/   # Observability configuration
├── scripts/      # Safe automation and validation scripts
└── terraform/    # Infrastructure-as-code modules and environments
```

GitHub Actions workflows live in `.github/workflows/`.

## Prerequisites

Run the read-only preflight to see which tools are available:

```bash
make preflight
```

The planned toolchain includes Git, GitHub CLI, Colima, Docker, kubectl, kind, Terraform, Helm, Gitleaks, ShellCheck, Hadolint, and Trivy.

See [Local development environment](docs/local-development.md) for reproducible Homebrew installation, validation commands, and runtime safety boundaries.

## Local runtime recommendation

For a development machine with at least 16 GB of memory, a practical starting point for Colima is 4 CPUs, 8 GB of memory, and 60 GB of disk. Reduce this to 2 CPUs and 4–6 GB on an 8 GB machine, or increase it when running observability components alongside the cluster. Colima is not started by the bootstrap phase.

## Development workflow

The initial bootstrap is committed to `main`. Subsequent work uses focused feature branches, Conventional Commits, validation before push, and pull requests back to `main`.

Never commit credentials, local environment files, Terraform state, private keys, or certificates. See `.gitignore` for protected patterns.

## Useful commands

```bash
make help
make preflight
make tool-versions
make check
```

## Run the banking API locally

```bash
make app-install
make app-test
make app-run
```

In another terminal, verify the service:

```bash
open http://127.0.0.1:5000
curl http://127.0.0.1:5000/healthz
curl http://127.0.0.1:5000/api/v1/accounts
```

The root URL opens a responsive monochrome banking dashboard with live balances and transfers. See [Banking API](docs/banking-api.md) for endpoints and command-line examples. The current in-memory balances reset whenever the process restarts.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
