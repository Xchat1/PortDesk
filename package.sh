#!/bin/bash
set -e

# PortDeck packaging script

APP_NAME="PortDeck"
BUNDLE_ID="com.portdeck.app"
BUILD_CONFIG="release"
VERSION="1.0.0"
INSTALL=false
CLEAN=false

usage() {
    echo "Usage: $0 [--install] [--clean]"
    echo "  --install  Copy PortDeck.app to ~/Applications and clear quarantine"
    echo "  --clean    Remove .build and PortDeck.app before building"
    exit 0
}

for arg in "$@"; do
    case "$arg" in
        --install) INSTALL=true ;;
        --clean)   CLEAN=true ;;
        -h|--help) usage ;;
        *)
            echo "Unknown option: $arg"
            usage
            ;;
    esac
done

if [ "$CLEAN" = true ]; then
    echo "=== Cleaning previous build artifacts ==="
    rm -rf .build "$APP_NAME.app" "$APP_NAME-macOS-"*.zip
fi

echo "=== Building $APP_NAME in $BUILD_CONFIG mode ==="
swift build -c "$BUILD_CONFIG"

BINARY_PATH=".build/apple/Products/Release/PortDeck"
if [ ! -f "$BINARY_PATH" ]; then
    BINARY_PATH=".build/$BUILD_CONFIG/PortDeck"
fi

if [ ! -f "$BINARY_PATH" ]; then
    BINARY_PATH=$(find .build -name "PortDeck" -type f | head -n 1)
fi

if [ -z "$BINARY_PATH" ] || [ ! -f "$BINARY_PATH" ]; then
    echo "Error: Compiled binary 'PortDeck' not found!"
    exit 1
fi

echo "Found compiled binary at: $BINARY_PATH"

echo "=== Creating $APP_NAME.app bundle ==="
APP_BUNDLE="$APP_NAME.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

if [ -f "AppIcon.icns" ]; then
    cp "AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

cp "$BINARY_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "=== Ad-hoc signing $APP_BUNDLE ==="
codesign -s - --force --deep "$APP_BUNDLE"

echo "=== Packaging complete: $APP_BUNDLE created successfully ==="

if [ "$INSTALL" = true ]; then
    echo "=== Installing to ~/Applications ==="
    pkill -x "$APP_NAME" 2>/dev/null || true
    rm -rf "$HOME/Applications/$APP_BUNDLE"
    cp -R "$APP_BUNDLE" "$HOME/Applications/"
    xattr -cr "$HOME/Applications/$APP_BUNDLE"
    echo "Installed to $HOME/Applications/$APP_BUNDLE"
    echo "Launch with: open $HOME/Applications/$APP_BUNDLE"
else
    echo "You can launch the app by running: open $APP_BUNDLE"
    echo "Or install with: $0 --install"
fi
