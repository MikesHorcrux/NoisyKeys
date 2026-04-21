#!/usr/bin/env bash
set -euo pipefail

APP_NAME="NoisyKeys"
DISPLAY_NAME="Noisy Keys"
BUNDLE_ID="com.lunarmothstudios.NoisyKeys"
PROJECT_NAME="NoisyKeys.xcodeproj"
SCHEME_NAME="NoisyKeys"
CONFIGURATION="Release"
TEAM_ID="${TEAM_ID:-5V5PZUN2HG}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$ROOT_DIR/build/Gumroad"
DERIVED_DATA_PATH="$BUILD_ROOT/DerivedData"
DIST_DIR="$ROOT_DIR/dist"
STAGING_DIR="$BUILD_ROOT/staging"
APP_BUNDLE="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/$APP_NAME.app"

LOCAL_TEST=0
NOTARIZE=0
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
DEVELOPER_ID_APPLICATION="${DEVELOPER_ID_APPLICATION:-}"

usage() {
  cat >&2 <<USAGE
usage: script/package_gumroad.sh [--local-test] [--notarize] [--keychain-profile NAME]

Creates a drag-to-Applications DMG in dist/.

By default this requires a Developer ID Application certificate so the result is suitable
for public Mac distribution. Use --local-test to create a non-notarized test DMG with
the current project signing identity.

Environment:
  TEAM_ID                    Apple Developer team id. Default: $TEAM_ID
  DEVELOPER_ID_APPLICATION   Exact Developer ID Application identity name.
  NOTARY_PROFILE             xcrun notarytool keychain profile name.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --local-test)
      LOCAL_TEST=1
      shift
      ;;
    --notarize)
      NOTARIZE=1
      shift
      ;;
    --keychain-profile)
      NOTARY_PROFILE="${2:-}"
      if [[ -z "$NOTARY_PROFILE" ]]; then
        echo "--keychain-profile requires a value" >&2
        exit 2
      fi
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

cd "$ROOT_DIR"

if [[ -z "$DEVELOPER_ID_APPLICATION" ]]; then
  DEVELOPER_ID_APPLICATION="$(security find-identity -v -p codesigning | awk -F '"' '/Developer ID Application/ { print $2; exit }')"
fi

if [[ -z "$DEVELOPER_ID_APPLICATION" && "$LOCAL_TEST" -ne 1 ]]; then
  cat >&2 <<ERROR
No Developer ID Application signing identity was found.

Install the Developer ID Application certificate for team $TEAM_ID, or run:
  script/package_gumroad.sh --local-test

Do not upload --local-test output to Gumroad; Gatekeeper will not treat it as a
normal public download.
ERROR
  exit 1
fi

rm -rf "$BUILD_ROOT" "$STAGING_DIR"
mkdir -p "$DIST_DIR" "$STAGING_DIR"

BUILD_SETTINGS=(
  -project "$PROJECT_NAME"
  -scheme "$SCHEME_NAME"
  -configuration "$CONFIGURATION"
  -destination "generic/platform=macOS"
  -derivedDataPath "$DERIVED_DATA_PATH"
  ONLY_ACTIVE_ARCH=NO
  "ARCHS=arm64 x86_64"
)

if [[ -n "$DEVELOPER_ID_APPLICATION" ]]; then
  BUILD_SETTINGS+=(
    CODE_SIGN_STYLE=Manual
    "CODE_SIGN_IDENTITY=$DEVELOPER_ID_APPLICATION"
    "DEVELOPMENT_TEAM=$TEAM_ID"
    ENABLE_HARDENED_RUNTIME=YES
    CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO
  )
fi

xcodebuild "${BUILD_SETTINGS[@]}" clean build

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "Build succeeded, but $APP_BUNDLE was not found" >&2
  exit 1
fi

if [[ -n "$DEVELOPER_ID_APPLICATION" ]]; then
  codesign --force --options runtime --timestamp \
    --sign "$DEVELOPER_ID_APPLICATION" \
    "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
  codesign --force --options runtime --timestamp \
    --sign "$DEVELOPER_ID_APPLICATION" \
    "$APP_BUNDLE"
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_BUNDLE/Contents/Info.plist")"
BUILD_NUMBER="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_BUNDLE/Contents/Info.plist")"

SIGNING_LABEL="developer-id"
if [[ -z "$DEVELOPER_ID_APPLICATION" ]]; then
  SIGNING_LABEL="local-test"
fi

DMG_BASENAME="$APP_NAME-$VERSION"
if [[ "$SIGNING_LABEL" == "local-test" ]]; then
  DMG_BASENAME="$DMG_BASENAME-local-test"
fi

DMG_PATH="$DIST_DIR/$DMG_BASENAME.dmg"
SHA_PATH="$DMG_PATH.sha256"
VOLUME_NAME="$DISPLAY_NAME $VERSION"

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

cp -R "$APP_BUNDLE" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"

cat > "$STAGING_DIR/Read Me.txt" <<README
$DISPLAY_NAME $VERSION ($BUILD_NUMBER)

Install:
1. Drag $APP_NAME.app to Applications.
2. Open $DISPLAY_NAME from Applications.
3. macOS may ask for Input Monitoring permission so the app can hear global typing.
4. If sound only works while the app is in front, toggle Noisy Keys off and back
   on in Input Monitoring, then quit and reopen the Applications copy.

Support:
Keep this DMG for reinstalling the same build.
README

rm -f "$DMG_PATH" "$SHA_PATH"
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

if [[ "$NOTARIZE" -eq 1 ]]; then
  if [[ -z "$NOTARY_PROFILE" ]]; then
    echo "--notarize requires NOTARY_PROFILE or --keychain-profile NAME" >&2
    exit 2
  fi

  if [[ "$SIGNING_LABEL" != "developer-id" ]]; then
    echo "Notarization requires a Developer ID Application signed build" >&2
    exit 1
  fi

  xcrun notarytool submit "$DMG_PATH" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait
  xcrun stapler staple "$DMG_PATH"
  xcrun stapler validate "$DMG_PATH"
  spctl --assess --type open --context context:primary-signature --verbose=4 "$DMG_PATH"
fi

shasum -a 256 "$DMG_PATH" > "$SHA_PATH"

cat <<RESULT

Created:
  $DMG_PATH
  $SHA_PATH

Signing:
  $SIGNING_LABEL

Bundle:
  $BUNDLE_ID
  version $VERSION ($BUILD_NUMBER)
RESULT

if [[ "$SIGNING_LABEL" == "local-test" ]]; then
  cat <<WARNING

Warning:
  This is a local-test DMG. It is useful for checking the installer flow, but it
  is not ready for Gumroad until a Developer ID certificate is installed and the
  DMG is notarized.
WARNING
fi
