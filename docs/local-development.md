# Local development environment

This project uses Homebrew to install the local container, Kubernetes, and security-validation command-line tools required by later phases.

## Install the toolchain

From the repository root:

```bash
brew bundle --file Brewfile
```

Terraform, Git, GitHub CLI, Make, and Python are also required. Terraform is intentionally not included in the `Brewfile` because this workstation uses HashiCorp's tap, whose trust configuration should remain an explicit user-level decision.

## Validate the installation

```bash
make preflight
make tool-versions
make check
```

These targets inspect binaries and repository files only. They do not start Colima, create a kind cluster, apply Terraform, or deploy Kubernetes workloads.

## Colima resource profile

The recommended starting profile for the later cluster phase is:

| Resource | Allocation |
| --- | ---: |
| CPU | 4 cores |
| Memory | 8 GiB |
| Disk | 60 GiB |

Adjust the profile to the host's available resources before starting the runtime. Colima remains stopped in this phase.

## Installed tool roles

| Tool | Purpose |
| --- | --- |
| Colima | macOS container runtime virtual machine |
| Docker CLI | Container build and image operations |
| kubectl | Kubernetes API client |
| kind | Local multi-node Kubernetes clusters |
| Helm | Kubernetes package management |
| Gitleaks | Credential and secret scanning |
| ShellCheck | Shell static analysis |
| Hadolint | Dockerfile linting |
| Trivy | Filesystem, image, and configuration scanning |

## Safety boundaries

- Do not commit `.env`, `*.tfvars`, Terraform state, kubeconfigs, credentials, keys, or certificates.
- Do not use `brew services start colima`; later project scripts will start Colima explicitly with reviewed resource settings.
- Do not create a kind cluster until the dedicated cluster feature phase.
