#!/usr/bin/env bash
# Builds build/Fridler.ipa: unsigned, ready for AltStore to sign and install.
set -euo pipefail
cd "$(dirname "$0")/.."

GROUP="group.io.github.carsharing.fridler"
OUT=build
rm -rf "$OUT/Payload" "$OUT/Fridler.ipa"

xcodebuild \
  -project Fridler.xcodeproj \
  -scheme Fridler \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$OUT/DerivedData" \
  -quiet \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
  build

APP="$OUT/DerivedData/Build/Products/Release-iphoneos/Fridler.app"
APPEX="$APP/PlugIns/FridlerWidget.appex"
if [ ! -d "$APPEX" ]; then
  echo "::error::The widget extension is missing from Fridler.app/PlugIns"
  exit 1
fi

# AltStore only registers (and renames) the App Group when the binaries
# declare it, so ad-hoc sign each bundle with its entitlements, inside first.
codesign --force --sign - --timestamp=none --entitlements Widget/FridlerWidget.entitlements "$APPEX"
codesign --force --sign - --timestamp=none --entitlements App/Fridler.entitlements "$APP"

for bundle in "$APPEX" "$APP"; do
  entitlements=$(codesign -d --entitlements - --xml "$bundle" 2>&1 || true)
  echo "Entitlements of $(basename "$bundle"):"
  echo "$entitlements"
  if [[ "$entitlements" != *"$GROUP"* ]]; then
    echo "::error::$bundle does not declare $GROUP"
    exit 1
  fi
done

mkdir -p "$OUT/Payload"
cp -R "$APP" "$OUT/Payload/"
(cd "$OUT" && zip -qry Fridler.ipa Payload)
rm -rf "$OUT/Payload"

echo "Built $OUT/Fridler.ipa ($(du -h "$OUT/Fridler.ipa" | cut -f1))"
/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Info.plist" | sed 's/^/Version: /'
