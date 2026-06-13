# Release Checklist — TestFlight & App Store

This is the runbook for getting **Sunny Light Meter** onto TestFlight. The app ships
under **Sunny InnoLab's** Apple Developer account (they own the certificate, provisioning
profile, and App Store Connect record). The developer builds and signs; **Sunny InnoLab
uploads**.

---

## ✅ Done in R3 (compliance pass)

- **App icon** — `LightMeter/Assets.xcassets/AppIcon.appiconset` (1024², opaque, no alpha).
- **Privacy manifest** — `LightMeter/PrivacyInfo.xcprivacy`: no tracking, no data
  collection, declares the one required-reason API in use (`UserDefaults`, reason `CA92.1`).
- **Encryption compliance** — `ITSAppUsesNonExemptEncryption = false` in Info.plist
  (the app uses no non-exempt crypto), so TestFlight won't prompt per build.
- **Camera usage string** — `NSCameraUsageDescription` present and specific.
- **Display name** — `CFBundleDisplayName = "Sunny Light Meter"`.
- **Launch screen** — `UILaunchScreen` present.
- **No medical/health claims** — flicker copy is disclaimer-only ("Informational only,
  not medical advice"); verified by repo-wide grep.

---

## ⛔ Still needed from Sunny InnoLab

Ask them for (the same person who sent the `.p12` will have these):

1. **The `.p12` password** — to install the distribution certificate into Keychain.
2. **The distribution provisioning profile** (`.mobileprovision`), **App Store** type,
   for this app.
3. **The exact bundle identifier** the profile is bound to (its App ID). Our placeholder
   is `com.lightmeter.LightMeter` — it **must be changed to match** their App ID exactly,
   or signing fails.
4. **The Team ID** (10 chars). Derivable from the installed cert, but confirm it.
5. **Confirm the handoff**: they upload, so we hand them a **signed `.ipa`** (this runbook),
   unless they'd rather we upload directly — in which case ask for an App Store Connect
   role/invite instead.

> A matching **App Store Connect app record** must exist for the bundle ID before any
> upload. Sunny InnoLab creates this (or confirms it exists).

---

## 🔧 One-time signing setup (once the files arrive)

**1. Install the certificate** (you'll be prompted for the `.p12` password):
```bash
security import ~/Downloads/p12-certificates.p12 \
  -k ~/Library/Keychains/login.keychain-db \
  -T /usr/bin/codesign -P '<P12_PASSWORD>'
security find-identity -v -p codesigning   # confirm "Apple Distribution: Sunny InnoLab (TEAMID)"
```

**2. Install the provisioning profile** — double-click the `.mobileprovision`, or:
```bash
open '<path-to>.mobileprovision'          # installs into ~/Library/MobileDevice/Provisioning Profiles
```
Note its **"Name"** (shown in Xcode) — needed below as the specifier.

**3. Switch the project to manual signing.** Edit `project.yml` → `targets.LightMeter.settings.base`
(do NOT change it in Xcode's UI — `xcodegen generate` overwrites that). Replace the signing
block with:
```yaml
        PRODUCT_BUNDLE_IDENTIFIER: <SUNNY_INNOLAB_APP_ID>   # must match the profile
        CODE_SIGN_STYLE: Manual
        DEVELOPMENT_TEAM: <TEAMID>
        PROVISIONING_PROFILE_SPECIFIER: "<Profile Name>"
        CODE_SIGN_IDENTITY: "Apple Distribution"
```
Then regenerate:
```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodegen generate
```

---

## 📦 Build the signed archive → `.ipa`

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

# 1. Archive
xcodebuild -project LightMeter.xcodeproj -scheme LightMeter \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath build/LightMeter.xcarchive archive

# 2. Export the .ipa (App Store distribution). Needs build/ExportOptions.plist:
#    method=app-store-connect, teamID=<TEAMID>, signingStyle=manual,
#    provisioningProfiles={ <bundleID>: "<Profile Name>" }
xcodebuild -exportArchive \
  -archivePath build/LightMeter.xcarchive \
  -exportOptionsPlist build/ExportOptions.plist \
  -exportPath build/ipa
```
Result: `build/ipa/Sunny Light Meter.ipa` — this is what Sunny InnoLab uploads.

---

## 🚀 Upload & TestFlight (Sunny InnoLab, or you if granted access)

- Upload via **Transporter.app** (drag the `.ipa`) or Xcode Organizer.
- In App Store Connect → TestFlight → **Export Compliance**: choose
  **"None of the algorithms mentioned above"** (matches `ITSAppUsesNonExemptEncryption = false`).
- Build appears in TestFlight after processing (~5–15 min). Add internal testers.

---

## Pre-flight checklist

- [ ] `.p12` installed; `security find-identity` shows the Apple Distribution identity
- [ ] Provisioning profile installed; name known
- [ ] `PRODUCT_BUNDLE_IDENTIFIER` matches the profile's App ID
- [ ] Manual signing block set in `project.yml`; `xcodegen generate` run
- [ ] App icon renders (no alpha) · privacy manifest present · encryption key set
- [ ] App Store Connect app record exists for the bundle ID
- [ ] `xcodebuild archive` succeeds, `.ipa` exported
- [ ] Export-compliance answer ready ("None of the algorithms…")
