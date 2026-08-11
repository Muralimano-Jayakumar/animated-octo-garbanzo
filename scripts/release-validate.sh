#!/usr/bin/env bash
set -euo pipefail

REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPOSITORY_ROOT

cd "${REPOSITORY_ROOT}"

python3 - <<'PYTHON'
from pathlib import Path
import re
import sys
import tomllib

root = Path.cwd()
version = (root / "VERSION").read_text(encoding="utf-8").strip()
errors: list[str] = []

if not re.fullmatch(r"0|[1-9]\d*\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)", version):
    errors.append(f"VERSION is not a stable semantic version: {version!r}")

with (root / "pyproject.toml").open("rb") as configuration:
    package_version = tomllib.load(configuration)["project"]["version"]

if package_version != version:
    errors.append(
        f"version mismatch: VERSION={version!r}, pyproject.toml={package_version!r}"
    )

changelog = (root / "CHANGELOG.md").read_text(encoding="utf-8")
if f"## [{version}]" not in changelog:
    errors.append(f"CHANGELOG.md has no {version} release heading")

release_notes = root / "docs" / "releases" / f"v{version}.md"
if not release_notes.is_file():
    errors.append(f"missing release notes: {release_notes.relative_to(root)}")

if errors:
    print("Release validation failed:", file=sys.stderr)
    for error in errors:
        print(f"- {error}", file=sys.stderr)
    raise SystemExit(1)

print(f"Release metadata is consistent for v{version}.")
PYTHON

tracked_files="$(git ls-files)"
readonly tracked_files
if grep -Eq '(^|/)(\.env($|\.)|terraform\.tfvars$|[^/]*\.tfstate($|\.)|[^/]*\.tfplan$|backups/|\.DS_Store$)' <<<"${tracked_files}"; then
  echo "Release validation failed: forbidden runtime or secret-bearing file is tracked." >&2
  grep -E '(^|/)(\.env($|\.)|terraform\.tfvars$|[^/]*\.tfstate($|\.)|[^/]*\.tfplan$|backups/|\.DS_Store$)' <<<"${tracked_files}" >&2
  exit 1
fi

./scripts/docs-validate.sh
