#!/usr/bin/env bash
set -euo pipefail

PLASMOID_ID="org.kde.plasma.kvitals"
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST_DIR="$HOME/.local/share/plasma/plasmoids/$PLASMOID_ID"

echo "Installing KVitals plasmoid..."

# Remove old installation if present
if [[ -d "$DEST_DIR" ]]; then
    echo "  Removing previous installation..."
    rm -rf "$DEST_DIR"
fi

# Create destination
mkdir -p "$DEST_DIR"

# Copy everything
cp -r "$SRC_DIR/metadata.json" "$DEST_DIR/"
cp -r "$SRC_DIR/contents" "$DEST_DIR/"

# Make script executable
chmod +x "$DEST_DIR/contents/scripts/sys-stats.sh"

echo ""
echo "✅ Installed to: $DEST_DIR"
echo ""
echo "Next steps:"
echo "  1. Right-click on your KDE top panel"
echo "  2. Click 'Add Widgets...'"
echo "  3. Search for 'KVitals'"
echo "  4. Drag it onto your panel"
echo ""
echo "To uninstall: rm -rf $DEST_DIR"
