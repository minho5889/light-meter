#!/usr/bin/env bash
#
# finalize-signing.sh — produce a signed App Store .ipa for Sunny Light Meter.
#
# RUN THIS the moment Robert sends the App Store provisioning profile.
#   ./scripts/finalize-signing.sh ~/Downloads/<the-profile>.mobileprovision
#
# It auto-extracts the bundle ID / profile name / team from the profile itself
# (no manual lookup), installs the profile, archives with manual signing using
# the already-installed "Apple Distribution: Jisu Jung (GWBS3Q4W36)" cert, and
# exports build/ipa/*.ipa — the file Sunny InnoLab uploads to TestFlight.
#
# NOTE: untested until a real profile exists — validate on first run. If codesign
# prompts for keychain access (partition list), either click "Always Allow", or run:
#   security set-key-partition-list -S apple-tool:,apple: -s \
#     -k '<your-mac-login-password>' ~/Library/Keychains/login.keychain-db
# Fallback if this script hits trouble: use Xcode Organizer (Window > Organizer >
# Distribute App > Custom > Export) per docs/release-checklist.md.

set -euo pipefail

PROFILE="${1:?usage: finalize-signing.sh <path-to .mobileprovision>}"
[ -f "$PROFILE" ] || { echo "No such profile: $PROFILE" >&2; exit 1; }

export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

# 1. Decode the profile (CMS-signed plist) and pull out what signing needs.
PLIST="$(mktemp)"
trap 'rm -f "$PLIST"' EXIT
security cms -D -i "$PROFILE" > "$PLIST"

UUID="$(/usr/libexec/PlistBuddy -c 'Print :UUID' "$PLIST")"
NAME="$(/usr/libexec/PlistBuddy -c 'Print :Name' "$PLIST")"
TEAM="$(/usr/libexec/PlistBuddy -c 'Print :TeamIdentifier:0' "$PLIST")"
APPID="$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:application-identifier' "$PLIST")"
BUNDLE_ID="${APPID#"$TEAM".}"   # strip the "TEAMID." prefix → bundle identifier

echo "──────────────────────────────────────────────"
echo "  Profile name : $NAME"
echo "  Profile UUID : $UUID"
echo "  Team ID      : $TEAM"
echo "  Bundle ID    : $BUNDLE_ID"
echo "──────────────────────────────────────────────"

# 2. Install the profile where Xcode looks for it.
PROFILES_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
mkdir -p "$PROFILES_DIR"
cp "$PROFILE" "$PROFILES_DIR/$UUID.mobileprovision"
echo "Installed profile → $PROFILES_DIR/$UUID.mobileprovision"

# 3. Make sure the project is current.
xcodegen generate >/dev/null

# 4. Archive (Release) with manual signing overrides — no project.yml edit needed.
echo "Archiving…"
rm -rf build/LightMeter.xcarchive
xcodebuild -project LightMeter.xcodeproj -scheme LightMeter \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath build/LightMeter.xcarchive archive \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="$TEAM" \
  PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
  PROVISIONING_PROFILE_SPECIFIER="$NAME" \
  CODE_SIGN_IDENTITY="Apple Distribution"

# 5. Write ExportOptions and export the signed .ipa.
mkdir -p build
cat > build/ExportOptions.plist <<PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>teamID</key><string>$TEAM</string>
  <key>signingStyle</key><string>manual</string>
  <key>provisioningProfiles</key><dict>
    <key>$BUNDLE_ID</key><string>$NAME</string>
  </dict>
  <key>uploadSymbols</key><true/>
</dict></plist>
PLIST_EOF

echo "Exporting signed .ipa…"
rm -rf build/ipa
xcodebuild -exportArchive \
  -archivePath build/LightMeter.xcarchive \
  -exportOptionsPlist build/ExportOptions.plist \
  -exportPath build/ipa

echo ""
echo "✅ Done. Hand this .ipa to Sunny InnoLab for the TestFlight upload:"
ls -la build/ipa/*.ipa

echo ""
echo "To make manual signing permanent for future builds, set in project.yml"
echo "(targets.LightMeter.settings.base):"
echo "    PRODUCT_BUNDLE_IDENTIFIER: $BUNDLE_ID"
echo "    CODE_SIGN_STYLE: Manual"
echo "    DEVELOPMENT_TEAM: $TEAM"
echo "    PROVISIONING_PROFILE_SPECIFIER: \"$NAME\""
echo "    CODE_SIGN_IDENTITY: \"Apple Distribution\""
