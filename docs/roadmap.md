# Project status and roadmap

## v1.0.0 status

The local learning platform is feature-complete for its first stable portfolio release. It includes the application, container, cluster, Terraform, PostgreSQL, ingress, security, CI, observability, troubleshooting, and documentation phases.

## Candidate future releases

### v1.1: Policy enforcement and supply-chain evidence

- Rebuild the disposable cluster with a NetworkPolicy-capable CNI.
- Generate and publish a software bill of materials for the release image.
- Add signed image provenance and admission-policy exercises.

### v1.2: Recovery automation

- Add encrypted, independently stored logical backups.
- Exercise restoration into a newly created cluster.
- Record measured recovery-point and recovery-time results.

### v2.0: Cloud environment

- Design a managed Kubernetes deployment with managed PostgreSQL.
- Add TLS, DNS, remote Terraform state, and workload identity.
- Add staged delivery with environment-specific promotion and rollback.

Roadmap items are proposals, not commitments. Each requires its own issue, design review, feature branch, validation, and pull request.
