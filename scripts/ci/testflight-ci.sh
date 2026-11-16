#!/usr/bin/env bash
# TestFlight from a GitHub macOS runner (.github/workflows/ios-release.yml), manual signing:
# the shared Apple Distribution cert (temp keychain, set up by the workflow) + the API-made
# App Store profile "Pupdoku AppStore CI". The Mac keeps using scripts/testflight.sh
# (automatic signing). Same rules as testflight.sh: build number = git commit count,
# version = CFBundleShortVersionString in project.yml, PupdokuTests (simulator) gate the upload.
# Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH. Flags: --no-upload (signed export only), --skip-tests.
set -euo pipefail
cd "$(dirname "$0")/../.."
UPLOAD=1; RUN_TESTS=1
for a in "$@"; do
  case "$a" in
    --no-upload) UPLOAD=0 ;;
    --skip-tests) RUN_TESTS=0 ;;
    *) echo "Unknown option: $a" >&2; exit 2 ;;
  esac
done
TEAM_ID="7H5T5AR2X5"
BUNDLE_ID="com.centricfiber.pupdoku"
APP_PROFILE="Pupdoku AppStore CI"
BUILD_DIR="build"; ARCHIVE="$BUILD_DIR/Pupdoku.xcarchive"; EXPORT_DIR="$BUILD_DIR/export"
mkdir -p "$BUILD_DIR"

command -v xcodegen >/dev/null || brew install xcodegen
xcodegen generate --quiet
BUILD_NUMBER="$(git rev-list --count HEAD)"
VERSION="$(grep -E '^[[:space:]]*CFBundleShortVersionString:' project.yml | head -1 | sed -E 's/.*"(.*)".*/\1/')"
echo "Pupdoku $VERSION ($BUILD_NUMBER) from $(git rev-parse --short HEAD)"

if [ "$RUN_TESTS" -eq 1 ]; then
  # Ad-hoc signed simulator build (not unsigned: without the iCloud entitlement CKContainer throws at launch).
  echo "==> PupdokuTests on a simulator"
  SIM="$(xcrun simctl list devices available iPhone | grep -oE '[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}' | tail -1)"
  [ -n "$SIM" ] || { echo "No iPhone simulator available"; exit 1; }
  xcodebuild test -project Pupdoku.xcodeproj -scheme Pupdoku -destination "id=$SIM"     -skipPackagePluginValidation -skipMacroValidation     CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= PROVISIONING_PROFILE_SPECIFIER=     > "$BUILD_DIR/test.log" 2>&1 || true
  grep -E "error:|Executed|TEST (SUCCEEDED|FAILED)" "$BUILD_DIR/test.log" | sort -u | tail -20
  grep -q "TEST SUCCEEDED" "$BUILD_DIR/test.log" || { echo "tests failed"; tail -40 "$BUILD_DIR/test.log"; exit 1; }
fi

AUTH=(-authenticationKeyPath "$ASC_KEY_PATH" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")

echo "==> Archive"
xcodebuild archive \
  -project Pupdoku.xcodeproj -scheme Pupdoku -configuration Release \
  -destination "generic/platform=iOS" -archivePath "$ARCHIVE" \
  -skipPackagePluginValidation -skipMacroValidation \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="Apple Distribution" DEVELOPMENT_TEAM="$TEAM_ID" \
  PUPDOKU_APP_PROFILE="$APP_PROFILE" \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  > "$BUILD_DIR/archive.log" 2>&1 || true
[ -d "$ARCHIVE" ] || { echo "archive failed"; grep -E "error:" "$BUILD_DIR/archive.log" | sort -u | head -40; tail -30 "$BUILD_DIR/archive.log"; exit 1; }
BUILT="$(/usr/libexec/PlistBuddy -c 'Print :ApplicationProperties:CFBundleVersion' "$ARCHIVE/Info.plist")"
[ "$BUILT" = "$BUILD_NUMBER" ] || { echo "archive has build $BUILT, expected $BUILD_NUMBER"; exit 1; }
APP="$ARCHIVE/Products/Applications/Pupdoku.app"
GAD="$(/usr/libexec/PlistBuddy -c 'Print :GADApplicationIdentifier' "$APP/Info.plist" 2>/dev/null || true)"
case "$GAD" in ca-app-pub-*~*) ;; *) echo "GADApplicationIdentifier missing/placeholder ($GAD): would crash at launch"; exit 1 ;; esac
echo "==> Signed entitlements"
codesign -d --entitlements :- "$APP" 2>/dev/null | plutil -p - || true

DEST=export; [ "$UPLOAD" -eq 1 ] && DEST=upload
cat > "$BUILD_DIR/ExportOptions.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key><string>app-store-connect</string>
    <key>destination</key><string>$DEST</string>
    <key>teamID</key><string>$TEAM_ID</string>
    <key>signingStyle</key><string>manual</string>
    <key>signingCertificate</key><string>Apple Distribution</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>$BUNDLE_ID</key><string>$APP_PROFILE</string>
    </dict>
    <key>uploadSymbols</key><true/>
    <key>manageAppVersionAndBuildNumber</key><false/>
</dict>
</plist>
EOF
echo "==> Export ($DEST)"
set +e
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist" \
  -exportPath "$EXPORT_DIR" "${AUTH[@]}" > "$BUILD_DIR/upload.log" 2>&1
RC=$?
set -e
tail -25 "$BUILD_DIR/upload.log"
[ "$RC" -eq 0 ] || { echo "export/upload failed (rc $RC)"; grep -E "error" "$BUILD_DIR/upload.log" | head -20; exit 1; }
ls -la "$EXPORT_DIR" || true
echo "Done: Pupdoku $VERSION ($BUILD_NUMBER) $( [ "$UPLOAD" -eq 1 ] && echo 'uploaded to TestFlight' || echo 'exported (signed .ipa, not uploaded)' )."
