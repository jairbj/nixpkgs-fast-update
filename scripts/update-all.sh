#!/usr/bin/env bash
# Update all package sources. Safe to run repeatedly; only rewrites files when
# a newer upstream version is available.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

bash "$ROOT/pkgs/grok-build/update.sh"
bash "$ROOT/pkgs/claude-code/update.sh"

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git diff --quiet -- pkgs/ && [[ -z "$(git ls-files --others --exclude-standard -- pkgs/)" ]]; then
    echo "No package updates."
    exit 0
  fi
  echo "Packages updated:"
  git status --short -- pkgs/ || true
else
  echo "Done (not a git work tree; skipped dirty check)."
fi
