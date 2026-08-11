#!/usr/bin/env bash
set -euo pipefail

REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPOSITORY_ROOT

cd "${REPOSITORY_ROOT}"

python3 - <<'PYTHON'
from pathlib import Path
import re
import sys

root = Path.cwd()
documents = [root / "README.md", *sorted((root / "docs").glob("*.md"))]
required = {
    root / "docs" / "README.md",
    root / "docs" / "architecture.md",
    root / "docs" / "architecture-decisions.md",
    root / "docs" / "operations-runbook.md",
    root / "docs" / "disaster-recovery.md",
    root / "docs" / "portfolio-evidence.md",
}
errors: list[str] = []

for required_document in sorted(required):
    if not required_document.is_file():
        errors.append(f"missing required document: {required_document.relative_to(root)}")

link_pattern = re.compile(r"(?<!!)\[[^]]*]\(([^)]+)\)")
for document in documents:
    content = document.read_text(encoding="utf-8")
    if content.count("```") % 2:
        errors.append(f"unclosed fenced code block: {document.relative_to(root)}")

    for target in link_pattern.findall(content):
        target = target.strip().split(maxsplit=1)[0].strip("<>")
        if not target or target.startswith(("#", "http://", "https://", "mailto:")):
            continue
        path_text = target.split("#", maxsplit=1)[0]
        resolved = (document.parent / path_text).resolve()
        try:
            resolved.relative_to(root)
        except ValueError:
            errors.append(
                f"link escapes repository: {document.relative_to(root)} -> {target}"
            )
            continue
        if not resolved.exists():
            errors.append(f"broken link: {document.relative_to(root)} -> {target}")

if errors:
    print("Documentation validation failed:", file=sys.stderr)
    for error in errors:
        print(f"- {error}", file=sys.stderr)
    raise SystemExit(1)

print(f"Documentation validation passed for {len(documents)} Markdown files.")
PYTHON
