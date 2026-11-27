#!/usr/bin/env bash
# Point the package at a new Aura release.
#
#   ./update.sh <version> [sha256]
#
# Give the SHA-256 from the release's SHA256SUMS-linux.txt (the same one the download page shows).
# Without it the script downloads the .deb from ordreth.com and hashes it, which only proves the file
# is the one the site serves today: prefer the published checksum.
set -euo pipefail
export LC_ALL=C

cd "$(dirname "$0")"

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
  echo "usage: $0 <version> [sha256]" >&2
  exit 2
fi

version="$1"
if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.]+)?$ ]]; then
  echo "not a version: $version" >&2
  exit 2
fi

url="https://ordreth.com/apps/aura/downloads/Aura_${version}_amd64.deb"

if [ $# -eq 2 ]; then
  sha256="$2"
else
  tmp="$(mktemp -d)"
  trap 'rm -rf -- "$tmp"' EXIT
  echo "downloading $url" >&2
  curl --fail --location --proto '=https' --output "$tmp/aura.deb" "$url"
  sha256="$(sha256sum -- "$tmp/aura.deb" | cut -d' ' -f1)"
fi

sha256="${sha256,,}"
if ! [[ "$sha256" =~ ^[0-9a-f]{64}$ ]]; then
  echo "not a SHA-256 (64 hex digits): $sha256" >&2
  exit 2
fi

printf '{\n  "version": "%s",\n  "sha256": "%s"\n}\n' "$version" "$sha256" > sources.json
echo "sources.json: $version $sha256"
echo "next: nix build .#aura && ./result/bin/aura-player"
