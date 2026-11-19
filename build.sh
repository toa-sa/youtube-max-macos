#!/bin/bash
# Builds YouTube Max.app (macOS 14+, Apple Silicon / Intel) into ./build.
# Requires Xcode command-line tools. Downloads nothing.
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="YouTube Max"
BUNDLE_ID="app.youtubemax.mac"
BUILD_DIR="build"
APP="$BUILD_DIR/$APP_NAME.app"
SDK="$(xcrun --show-sdk-path)"
ARCH="$(uname -m)"
TARGET="$ARCH-apple-macosx14.0"

echo "→ Compiling…"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc -parse-as-library -O -target "$TARGET" -sdk "$SDK" \
  Sources/*.swift -o "$APP/Contents/MacOS/$APP_NAME"

echo "→ Copying resources…"
cp Resources/*.png "$APP/Contents/Resources/"
cp Resources/Fonts/*.ttf "$APP/Contents/Resources/"

echo "→ Writing Info.plist…"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key><string>ar</string>
	<key>CFBundleDisplayName</key><string>$APP_NAME</string>
	<key>CFBundleExecutable</key><string>$APP_NAME</string>
	<key>CFBundleIconFile</key><string>AppIcon</string>
	<key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
	<key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
	<key>CFBundleName</key><string>$APP_NAME</string>
	<key>CFBundlePackageType</key><string>APPL</string>
	<key>CFBundleShortVersionString</key><string>1.0</string>
	<key>CFBundleVersion</key><string>1</string>
	<key>LSApplicationCategoryType</key><string>public.app-category.video</string>
	<key>LSMinimumSystemVersion</key><string>14.0</string>
	<key>NSHighResolutionCapable</key><true/>
	<key>NSHumanReadableCopyright</key><string>TOA · Built on yt-dlp and FFmpeg. MIT.</string>
</dict>
</plist>
PLIST

if [[ -f Resources/AppIcon.icns ]]; then
  cp Resources/AppIcon.icns "$APP/Contents/Resources/"
fi

echo "→ Signing (ad-hoc)…"
xattr -cr "$APP"
codesign --force --sign - "$APP"

echo "✓ $APP"
