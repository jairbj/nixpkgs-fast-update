#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES="$PKG_DIR/sources.json"

version="$(curl -fsSL https://x.ai/cli/stable)"
current="$(jq -r .version "$SOURCES")"

if [[ "$current" == "$version" ]]; then
  echo "grok-build is up-to-date: $version"
  exit 0
fi

echo "Updating grok-build: $current -> $version"

url="https://x.ai/cli/grok-${version}-linux-x86_64"
raw_hash="$(nix-prefetch-url "$url")"
hash="$(nix --extra-experimental-features "nix-command flakes" hash convert --hash-algo sha256 "$raw_hash")"

jq -n --arg version "$version" --arg hash "$hash" \
  '{version: $version, hash: $hash}' >"$SOURCES"

echo "grok-build updated to $version ($hash)"
