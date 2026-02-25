#!/bin/bash

# Configuration
APP_NAME="Deploybell"
BINARY_PATH=".build/release/Deploybell"
BUILD_DIR="build_dmg"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
DMG_NAME="$APP_NAME.dmg"

echo "🚀 Starting DMG build process..."

# 1. Build release binary
echo "📦 Building release binary..."
swift build -c release

if [ ! -f "$BINARY_PATH" ]; then
    echo "❌ Error: Build failed, binary not found at $BINARY_PATH"
    exit 1
fi

# 2. Setup folder structure
echo "📂 Setting up .app bundle structure..."
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

# 3. Copy binary
echo "📄 Copying binary..."
cp "$BINARY_PATH" "$MACOS/$APP_NAME"

# 4. Create Info.plist
echo "📝 Creating Info.plist..."
cat > "$CONTENTS/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>online.v1be.deploybell</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# 5. Create DMG
echo "💿 Generating DMG..."
rm -f "$DMG_NAME"
hdiutil create -volname "$APP_NAME" -srcfolder "$BUILD_DIR" -ov -format UDZO "$DMG_NAME"

echo "✅ Success! DMG created: $DMG_NAME"
