#!/usr/bin/env bash
# Prints the CHANGELOG section for a version (e.g. v0.1.0) plus install steps.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1#v}"
awk -v v="$VERSION" '
  /^## / { printing = index($0, "[" v "]") > 0; next }
  printing { print }
' CHANGELOG.md

cat <<'NOTES'

### Install or update
1. On your iPhone, download **Fridler.ipa** below (Safari → Downloads).
2. Open AltStore → **My Apps** → **+** → pick `Fridler.ipa` (AltServer running on your computer, same Wi-Fi).
3. Long-press the home screen → **Edit** → **Add Widget** → **Fridler**.

Updating keeps your fridge: install the new IPA over the old one.
NOTES
