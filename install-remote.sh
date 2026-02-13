#!/usr/bin/env bash
set -euo pipefail

REPO="yassine20011/kvitals"
PLASMOID_ID="org.kde.plasma.kvitals"
DEST_DIR="$HOME/.local/share/plasma/plasmoids/$PLASMOID_ID"
TMP_DIR=$(mktemp -d)

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "⚡ Installing KVitals..."

# Download and extract
# Clone repository
if ! command -v git &>/dev/null; then
    echo "❌ Error: git is required"
    exit 1
fi

echo "  Cloning repository..."
git clone --depth 1 "https://github.com/$REPO.git" "$TMP_DIR/kvitals"
SRC_DIR="$TMP_DIR/kvitals"

# Remove old installation
if [[ -d "$DEST_DIR" ]]; then
    echo "  Removing previous installation..."
    rm -rf "$DEST_DIR"
fi

# Install
mkdir -p "$DEST_DIR"
cp "$SRC_DIR/metadata.json" "$DEST_DIR/"
cp -r "$SRC_DIR/contents" "$DEST_DIR/"
chmod +x "$DEST_DIR/contents/scripts/sys-stats.sh"

echo ""
echo "✅ KVitals installed to: $DEST_DIR"
echo ""
echo "Next steps:"
echo "  1. Restart Plasma:  plasmashell --replace &"
echo "  2. Right-click panel → Add Widgets → search 'KVitals'"
echo "  3. Drag it onto your panel"
echo ""
echo "To uninstall: rm -rf $DEST_DIR"
