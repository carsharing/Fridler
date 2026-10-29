#!/usr/bin/env bash
# Runs unit and snapshot tests on the newest available iPhone simulator.
# Rendered pictures land in Snapshots/Output.
set -euo pipefail
cd "$(dirname "$0")/.."

UDID=$(xcrun simctl list devices available -j | python3 -c '
import json, re, sys
best = None
for runtime, devices in json.load(sys.stdin)["devices"].items():
    m = re.search(r"iOS-(\d+)-(\d+)", runtime)
    if not m:
        continue
    version = (int(m.group(1)), int(m.group(2)))
    for d in devices:
        if d.get("isAvailable") and d["name"].startswith("iPhone"):
            key = (version, "Pro Max" in d["name"], d["name"])
            if best is None or key > best[0]:
                best = (key, d["udid"])
if best is None:
    sys.exit("No iPhone simulator available")
print(best[1])
')
echo "Testing on simulator $UDID"

rm -rf Snapshots/Output
xcodebuild \
  -project Fridler.xcodeproj \
  -scheme Fridler \
  -destination "id=$UDID" \
  -derivedDataPath build/TestData \
  -resultBundlePath build/TestResults.xcresult \
  -quiet \
  CODE_SIGNING_ALLOWED=NO \
  test
