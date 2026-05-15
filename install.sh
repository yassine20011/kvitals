#!/usr/bin/env bash
set -euo pipefail

PLASMOID_ID="org.kde.plasma.kvitals"
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST_DIR="$HOME/.local/share/plasma/plasmoids/$PLASMOID_ID"
KPACKAGE_DIR="$HOME/.local/share/kpackage/generic/$PLASMOID_ID"

echo "Installing KVitals plasmoid..."

# Remove old installation if present
for dir in "$DEST_DIR" "$KPACKAGE_DIR"; do
    if [[ -d "$dir" ]] || [[ -L "$dir" ]]; then
        echo "  Removing previous installation from $dir..."
        rm -rf "$dir"
    fi
done

# Install to primary location
mkdir -p "$DEST_DIR"
cp -r "$SRC_DIR/metadata.json" "$DEST_DIR/"
cp -r "$SRC_DIR/contents" "$DEST_DIR/"

mkdir -p "$(dirname "$KPACKAGE_DIR")"
ln -s "$DEST_DIR" "$KPACKAGE_DIR"


echo ""
echo "✅ Installed to: $DEST_DIR"
echo ""
echo "Next steps:"
echo "  1. Right-click on your KDE top panel"
echo "  2. Click 'Add Widgets...'"
echo "  3. Search for 'KVitals'"
echo "  4. Drag it onto your panel"
echo ""
echo "To uninstall: rm -rf $DEST_DIR $KPACKAGE_DIR"
