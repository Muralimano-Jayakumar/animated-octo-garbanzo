# Release process

This project uses Semantic Versioning. `VERSION` and the Python package version must match, and every release must have a changelog entry and versioned release notes.

## Prepare a release candidate

1. Create a release issue and a feature branch from current `main`.
2. Update `VERSION`, `pyproject.toml`, `CHANGELOG.md`, and `docs/releases/<version>.md`.
3. Run `make release-validate` and the complete validation suite.
4. Open a pull request and wait for every required GitHub check.
5. Obtain approval, resolve review conversations, and merge through protected `main`.

Do not create the tag from the feature branch. A release tag must identify the reviewed commit on `main`.

## Publish v1.0.0 after merge

```bash
git checkout main
git pull --ff-only origin main
make release-validate
git status --short
git tag --annotate v1.0.0 --message "release: v1.0.0"
git show --no-patch v1.0.0
git push origin v1.0.0
gh release create v1.0.0 \
  --repo Muralimano-Jayakumar/animated-octo-garbanzo \
  --title "Muma Bank Kubernetes Platform v1.0.0" \
  --notes-file docs/releases/v1.0.0.md \
  --verify-tag
```

Before pushing, confirm the tag resolves to the intended merge commit and that the working tree is clean. Tags and published releases are never replaced automatically.

## Post-release verification

```bash
gh release view v1.0.0 --repo Muralimano-Jayakumar/animated-octo-garbanzo
git ls-remote --tags origin refs/tags/v1.0.0
```

Confirm the release page renders correctly, the tag points to `main`, and the installation and operations links work.

## Corrections

Never force-update a published tag. Correct code or documentation through a new pull request and publish the next patch version, such as `v1.0.1`. If a release exposes a secret, revoke the credential first and follow an explicitly reviewed incident process; deleting a Git tag does not remove it from Git history.
