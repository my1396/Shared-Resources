#!/usr/bin/env zsh
# Download curated Twemoji PNGs listed in twemoji_manifest.json using jq and curl
# Usage: ./fetch_twemoji.sh
set -euo pipefail

# Move to the directory of this script so relative paths work
SCRIPT_DIR="${0:A:h}"
cd "$SCRIPT_DIR"

manifest="twemoji_manifest.json"
if [[ ! -f "$manifest" ]]; then
  echo "Missing $manifest" >&2
  exit 1
fi

version=$(jq -r '.version' "$manifest")
folder=$(jq -r '.folder' "$manifest")
base="https://cdn.jsdelivr.net/gh/twitter/twemoji@${version}/assets/${folder}"

# Iterate codes
jq -r '.emoji | keys[]' "$manifest" | while read -r code; do
  url="${base}/${code}.png"
  out="${code}.png"
  if [[ -f "$out" ]]; then
    echo "Exists: $out"
  else
    echo "Downloading: $out"
    curl -fsSL "$url" -o "$out" || echo "Failed: $url" >&2
  fi
done

echo "Done. Files saved in $(pwd). Map to filter names as needed (already matching)."