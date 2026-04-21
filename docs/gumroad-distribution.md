# Gumroad Mac Distribution

Use `script/package_gumroad.sh` to create the downloadable DMG.

## Public Release

Public Gumroad downloads should be Developer ID signed, notarized, and stapled.
The app already has hardened runtime enabled in the Xcode project.

Prerequisites on the release Mac:

- Apple Developer Program membership.
- A `Developer ID Application` certificate installed in Keychain Access.
- A stored notarytool profile.

Create the notary profile once:

```sh
xcrun notarytool store-credentials "NoisyKeysNotary" \
  --apple-id "APPLE_ID_EMAIL" \
  --team-id "5V5PZUN2HG" \
  --password "APP_SPECIFIC_PASSWORD"
```

Create the Gumroad DMG:

```sh
script/package_gumroad.sh --notarize --keychain-profile NoisyKeysNotary
```

The upload artifact will be in `dist/`, for example:

```text
dist/NoisyKeys-1.0.dmg
dist/NoisyKeys-1.0.dmg.sha256
```

## Local Installer Test

If the release Mac does not have a Developer ID certificate yet, create a test
DMG with:

```sh
script/package_gumroad.sh --local-test
```

Do not upload local-test output to Gumroad. It is only for checking the
drag-to-Applications install flow.

## Buyer Install Notes

Tell buyers to drag `NoisyKeys.app` into Applications, open it from
Applications, then approve Accessibility permission when macOS asks. The app
does not need a network entitlement for vibe detection.
