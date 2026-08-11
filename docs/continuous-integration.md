# Continuous integration

GitHub Actions validates every pull request, every push to `main`, and manual workflow dispatches. CI is intentionally read-only and never creates a kind cluster or applies Terraform.

## Required checks

| Check | Purpose |
| --- | --- |
| Application tests | Ruff, pytest, and the 90% coverage threshold on Python 3.14 |
| Terraform validation | Formatting, provider initialization without a backend, and configuration validation |
| Shell validation | Bash parsing and ShellCheck for every project script |
| Secret scanning | Gitleaks across complete Git history |
| Container security | Image build and Trivy HIGH/CRITICAL vulnerability and secret policy |

Workflow permissions are restricted to `contents: read`. Jobs have explicit timeouts, stale runs are cancelled, and external actions are pinned to immutable commit SHAs with release comments for reviewability.

## Local parity

Run the closest local equivalent before pushing:

```bash
make app-test
terraform -chdir=terraform fmt -check -recursive
terraform -chdir=terraform init -backend=false -input=false
terraform -chdir=terraform validate
bash -n scripts/*.sh
shellcheck scripts/*.sh
gitleaks detect --source . --no-banner --redact
make container-build
make container-scan
```

The container targets require Colima or another Docker runtime. Stop Colima after scanning if it is not otherwise needed.

## Branch protection

After the first successful run on `main`, configure the repository ruleset to require a pull request and the five checks above before merging. Also require branches to be up to date and block force pushes and branch deletion. Repository administrators can configure this under **Settings → Rules → Rulesets**.

## Dependency updates

Dependabot checks GitHub Actions and Python dependencies weekly and groups related updates to avoid noisy pull requests. Review release notes and keep action references pinned to full commit SHAs when merging upgrades.
