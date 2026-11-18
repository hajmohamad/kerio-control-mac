#!/bin/bash
set -e

APP_NAME="Kerio Control"
BUILD_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS="${APP_BUNDLE}/Contents"
MACOS="${CONTENTS}/MacOS"
FRAMEWORKS="${CONTENTS}/Frameworks"
RESOURCES="${CONTENTS}/Resources"
DIST_DIR="${BUILD_DIR}/dist"

echo "=========================================="
echo " Building ${APP_NAME}.app (Universal 2)"
echo " Architectures: arm64 (Apple Silicon) + x86_64 (Intel)"
echo "=========================================="

# 1. Clean old bundle
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS}" "${FRAMEWORKS}" "${RESOURCES}"

# 2. Compile libhook.dylib (Universal Binary)
echo "==> Compiling libhook.dylib..."
clang -dynamiclib "${BUILD_DIR}/src/hook.c" \
    -o "${FRAMEWORKS}/libhook.dylib" \
    -install_name "@rpath/libhook.dylib" \
    -framework CoreFoundation \
    -arch arm64 -arch x86_64 -O2

# 3. Compile Main Executable (Universal Binary)
echo "==> Compiling main executable..."
clang "${BUILD_DIR}/src/main.m" \
    -o "${MACOS}/${APP_NAME}" \
    -L"${FRAMEWORKS}" -lhook \
    -rpath "@executable_path/../Frameworks" \
    -framework Cocoa \
    -framework PreferencePanes \
    -arch arm64 -arch x86_64 -O2

# 4. Copy App Icon
echo "==> Copying app icon..."
if [ -f "${BUILD_DIR}/resources/AppIcon.icns" ]; then
    cp "${BUILD_DIR}/resources/AppIcon.icns" "${RESOURCES}/AppIcon.icns"
elif [ -f "/usr/local/kerio/vpnclient/KVpnClientStatus.app/Contents/Resources/VPN_mac.icns" ]; then
    cp "/usr/local/kerio/vpnclient/KVpnClientStatus.app/Contents/Resources/VPN_mac.icns" "${RESOURCES}/AppIcon.icns"
elif [ -f "${BUILD_DIR}/AppIcon.icns" ]; then
    cp "${BUILD_DIR}/AppIcon.icns" "${RESOURCES}/AppIcon.icns"
fi

# 5. Create Info.plist
echo "==> Creating Info.plist..."
cat << 'EOF' > "${CONTENTS}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>Kerio Control</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.custom.keriocontrol</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Kerio Control</string>
    <key>CFBundleDisplayName</key>
    <string>Kerio Control</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# 6. Ad-hoc codesign so macOS Gatekeeper allows running smoothly
echo "==> Code-signing bundle..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "==> Build successful: ${APP_BUNDLE}"

# 7. Packaging (if requested or by default)
if [ "$1" = "package" ] || [ "$1" = "release" ] || [ "$1" = "dist" ]; then
    echo "=========================================="
    echo " Packaging for Release..."
    echo "=========================================="
    mkdir -p "${DIST_DIR}"
    
    # Create ZIP
    echo "==> Creating ZIP archive..."
    ditto -c -k --keepParent "${APP_BUNDLE}" "${DIST_DIR}/${APP_NAME}-macOS-Universal.zip"
    
    # Create DMG
    echo "==> Creating DMG image..."
    DMG_TEMP="/tmp/kerio_dmg_temp_$$"
    rm -rf "${DMG_TEMP}"
    mkdir -p "${DMG_TEMP}"
    cp -R "${APP_BUNDLE}" "${DMG_TEMP}/"
    ln -s /Applications "${DMG_TEMP}/Applications"
    
    DMG_OUT="${DIST_DIR}/${APP_NAME}-macOS-Universal.dmg"
    rm -f "${DMG_OUT}"
    hdiutil create -volname "${APP_NAME}" -srcfolder "${DMG_TEMP}" -ov -format UDZO "${DMG_OUT}" > /dev/null
    rm -rf "${DMG_TEMP}"
    
    echo "==> Packages created in ${DIST_DIR}:"
    ls -lh "${DIST_DIR}"
fi
