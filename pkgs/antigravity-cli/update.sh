#!/usr/bin/env bash
set -euo pipefail

PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES="$PKG_DIR/sources.json"
BASE_URL="https://storage.googleapis.com/antigravity-public/antigravity-cli"

version="$(curl -fsSL "$BASE_URL/latest")"
current="$(jq -r .version "$SOURCES")"

if [[ "$current" == "$version" ]]; then
  echo "antigravity-cli is up-to-date: $version"
  exit 0
fi

echo "Updating antigravity-cli: $current -> $version"

# The download URLs embed an opaque build id that only the manifest knows.
whole="$(curl -fsSL "$BASE_URL/$version/manifest.json" \
  | jq -r '.platforms."linux-x64".url' | cut -d/ -f6)"
buildId="${whole#*-}"

url="$BASE_URL/$whole/linux-x64/cli_linux_x64.tar.gz"
raw_hash="$(nix-prefetch-url "$url")"
hash="$(nix --extra-experimental-features "nix-command flakes" hash convert --hash-algo sha256 "$raw_hash")"

jq -n --arg version "$version" --arg buildId "$buildId" --arg hash "$hash" \
  '{version: $version, buildId: $buildId, hash: $hash}' >"$SOURCES"

echo "antigravity-cli updated to $version ($hash)"
