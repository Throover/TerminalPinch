#!/bin/sh
# TerminalPinch installer — https://github.com/Throover/TerminalPinch
# Usage: curl -fsSL https://raw.githubusercontent.com/Throover/TerminalPinch/main/install.sh | sh
set -e
URL="https://github.com/Throover/TerminalPinch/releases/latest/download/TerminalPinch.zip"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "Downloading TerminalPinch…"
curl -fsSL "$URL" -o "$TMP/TerminalPinch.zip"
ditto -x -k "$TMP/TerminalPinch.zip" "$TMP"

pkill -x TerminalPinch 2>/dev/null || true
DEST=/Applications
[ -w "$DEST" ] || DEST="$HOME/Applications"
mkdir -p "$DEST"
rm -rf "$DEST/TerminalPinch.app"
ditto "$TMP/TerminalPinch.app" "$DEST/TerminalPinch.app"

echo "Installed in $DEST/TerminalPinch.app — opening…"
open "$DEST/TerminalPinch.app"
