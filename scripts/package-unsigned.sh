#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="StarMagpie"
CONFIGURATION="Release"
DERIVED_DATA_PATH="$ROOT_DIR/build/DerivedData"
DIST_DIR="$ROOT_DIR/dist"
ARCHIVE_NAME="$APP_NAME-unsigned.zip"

cd "$ROOT_DIR"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required. Install it with: brew install xcodegen" >&2
  exit 1
fi

rm -rf "$DIST_DIR" "$DERIVED_DATA_PATH"
mkdir -p "$DIST_DIR"

xcodegen generate

xcodebuild build \
  -quiet \
  -scheme "$APP_NAME" \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=macOS" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY=""

APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/$APP_NAME.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "Build succeeded but app bundle was not found at $APP_PATH" >&2
  exit 1
fi

COPYFILE_DISABLE=1 ditto -c -k --norsrc --keepParent "$APP_PATH" "$DIST_DIR/$ARCHIVE_NAME"
shasum -a 256 "$DIST_DIR/$ARCHIVE_NAME" > "$DIST_DIR/$ARCHIVE_NAME.sha256"

echo "Created $DIST_DIR/$ARCHIVE_NAME"
echo "Created $DIST_DIR/$ARCHIVE_NAME.sha256"
