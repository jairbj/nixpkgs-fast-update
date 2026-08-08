#!/usr/bin/env bash
set -euo pipefail

PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES="$PKG_DIR/sources.json"

tag="$(curl -fsSL https://api.github.com/repos/coder/code-server/releases/latest | jq -r .tag_name)"
version="${tag#v}"
current="$(jq -r .version "$SOURCES")"

if [[ "$current" == "$version" ]]; then
  echo "code-server is up-to-date: $version"
  exit 0
fi

echo "Updating code-server: $current -> $version"

url="https://github.com/coder/code-server/releases/download/v${version}/code-server-${version}-linux-amd64.tar.gz"
raw_hash="$(nix-prefetch-url "$url")"
hash="$(nix --extra-experimental-features "nix-command flakes" hash convert --hash-algo sha256 "$raw_hash")"

jq -n --arg version "$version" --arg hash "$hash" \
  '{version: $version, hash: $hash}' >"$SOURCES"

echo "code-server updated to $version ($hash)"
