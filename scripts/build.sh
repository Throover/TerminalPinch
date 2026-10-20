#!/bin/zsh
# Construit TerminalPinch.app (Apple Silicon + Intel) et TerminalPinch.dmg dans build/
set -euo pipefail
cd "${0:A:h}/.."
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)
APP=build/TerminalPinch.app
rm -rf build && mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

for arch in arm64 x86_64; do
  swiftc -O -target $arch-apple-macos13.0 Sources/*.swift -o build/TerminalPinch-$arch
done
lipo -create build/TerminalPinch-* -output "$APP/Contents/MacOS/TerminalPinch"
rm build/TerminalPinch-*

cp Resources/Info.plist "$APP/Contents/"
cp -R Resources/*.lproj "$APP/Contents/Resources/"
swift scripts/make_icon.swift build
iconutil -c icns build/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf build/AppIcon.iconset

# Signature stable si le certificat « TerminalPinch Developer » existe (les autorisations macOS
# survivent alors aux mises à jour), sinon signature ad hoc.
IDENTITY=$(security find-identity -p codesigning | awk -F'"' '/TerminalPinch Developer/ {print $2; exit}')
codesign --force --deep -s "${IDENTITY:--}" "$APP"

# DMG : glisser l'app dans Applications
mkdir -p build/dmg && cp -R "$APP" build/dmg/ && ln -s /Applications build/dmg/Applications
hdiutil create -volname TerminalPinch -srcfolder build/dmg -ov -format UDZO "build/TerminalPinch-$VERSION.dmg" >/dev/null
rm -rf build/dmg
echo "OK : $APP et build/TerminalPinch-$VERSION.dmg"
