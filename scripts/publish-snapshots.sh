#!/usr/bin/env bash
# Force-pushes the latest rendered pictures to the `snapshots` branch so
# anyone can look at them on GitHub without installing the app.
set -euo pipefail
cd "$(dirname "$0")/.."

SRC=Snapshots/Output
if ! ls "$SRC"/*.png >/dev/null 2>&1; then
  echo "No snapshots to publish"
  exit 0
fi

WORK=$(mktemp -d)
cp "$SRC"/*.png "$WORK/"
{
  echo "# Fridler snapshots"
  echo
  echo "Rendered by CI from ${GITHUB_SHA:-a local build}. Pictures with a reference in"
  echo "\`Snapshots/Reference\` on \`main\` are checked against it on every build."
  echo
  for png in "$WORK"/*.png; do
    name=$(basename "$png" .png)
    echo "### $name"
    echo
    echo "![$name]($name.png)"
    echo
  done
} > "$WORK/README.md"

cd "$WORK"
git init -q -b snapshots
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -A
git commit -qm "Snapshots for ${GITHUB_SHA:-local build}"
git push -fq "https://x-access-token:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" HEAD:snapshots
echo "Published $(ls *.png | wc -l | tr -d ' ') snapshots to the snapshots branch"
