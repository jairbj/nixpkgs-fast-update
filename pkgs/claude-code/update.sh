#!/usr/bin/env bash
set -euo pipefail

PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$PKG_DIR/manifest.json"
BASE_URL="https://downloads.claude.ai/claude-code-releases"

VERSION="${1:-$(curl -fsSL "$BASE_URL/latest")}"
current="$(jq -r .version "$MANIFEST" 2>/dev/null || echo none)"

if [[ "$current" == "$VERSION" ]]; then
  echo "claude-code is up-to-date: $VERSION"
  exit 0
fi

echo "Updating claude-code: $current -> $VERSION"
curl -fsSL "$BASE_URL/$VERSION/manifest.json" --output "$MANIFEST"
echo "claude-code updated to $VERSION"
