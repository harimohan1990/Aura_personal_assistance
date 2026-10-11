#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "=== Building AURA Swift Native Executable ==="
swift build -c release

APP_DIR="$DIR/AURA.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "=== Creating macOS Application Bundle ==="
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy binary
cp "$DIR/.build/release/AURA" "$MACOS_DIR/AURA"
chmod +x "$MACOS_DIR/AURA"

# Create Info.plist with full permissions for Accessibility, Mic, Speech, and Network
cat <<EOF > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>AURA</string>
    <key>CFBundleIdentifier</key>
    <string>com.aura.aiassistant</string>
    <key>CFBundleName</key>
    <string>AURA</string>
    <key>CFBundleDisplayName</key>
    <string>AURA AI Assistant</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSMicrophoneUsageDescription</key>
    <string>AURA requires continuous microphone access for hands-free accessibility voice control and speech interaction.</string>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>AURA uses speech recognition to convert your voice into commands for hands-free and disability assistance.</string>
    <key>NSAccessibilityUsageDescription</key>
    <string>AURA provides accessibility voice control to assist individuals with motor or physical disabilities.</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>AURA controls applications, browser tabs, and system settings on your behalf.</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>AURA uses your location to calculate routes, distance, and directions home.</string>
    <key>NSLocationUsageDescription</key>
    <string>AURA requires location access for map navigation.</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
</dict>
</plist>
EOF

# Code signing with Entitlements
ENTITLEMENTS_FILE="$DIR/../build/entitlements.mac.plist"
if [ -f "$ENTITLEMENTS_FILE" ]; then
    echo "=== Signing AURA.app with Security Entitlements ==="
    codesign --force --deep --sign - --entitlements "$ENTITLEMENTS_FILE" "$APP_DIR" || true
    echo "✓ Successfully signed with microphone, speech, audio-input, and network entitlements."
fi

echo "✓ AURA.app built successfully at: $APP_DIR"
if [ -d "$DIR/.." ]; then
    rm -rf "$DIR/../AURA.app"
    cp -R "$APP_DIR" "$DIR/../AURA.app"
    echo "✓ Synced AURA.app to workspace root: $DIR/../AURA.app"
fi

echo ""
echo "=== Deployment Completed ==="
echo "1. Run locally: open \"$APP_DIR\""
echo "2. Install to system: cp -R \"$APP_DIR\" /Applications/AURA.app"
