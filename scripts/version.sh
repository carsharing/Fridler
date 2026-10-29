#!/usr/bin/env bash
# Prints MARKETING_VERSION from project.yml (e.g. 0.1.0).
set -euo pipefail
cd "$(dirname "$0")/.."
sed -nE 's/^[[:space:]]*MARKETING_VERSION:[[:space:]]*"?([0-9.]+)"?.*/\1/p' project.yml | head -1
