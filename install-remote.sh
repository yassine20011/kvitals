#!/usr/bin/env bash
set -euo pipefail

REPO="yassine20011/kvitals"
PLASMOID_ID="org.kde.plasma.kvitals"
DEST_DIR="$HOME/.local/share/plasma/plasmoids/$PLASMOID_ID"
KPACKAGE_DIR="$HOME/.local/share/kpackage/generic/$PLASMOID_ID"
TMP_DIR=$(mktemp -d)

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "[STATUS] Installing KVitals..."

# Download and extract
# Clone repository
if ! command -v git &>/dev/null; then
    echo "[ERR] git is required"
    exit 1
fi

echo "  Cloning repository..."
git clone --depth 1 "https://github.com/$REPO.git" "$TMP_DIR/kvitals"
SRC_DIR="$TMP_DIR/kvitals"

# Remove old installation
for dir in "$DEST_DIR" "$KPACKAGE_DIR"; do
    if [[ -d "$dir" ]] || [[ -L "$dir" ]]; then
        echo "  Removing previous installation from $dir..."
        rm -rf "$dir"
    fi
done

# Install
mkdir -p "$DEST_DIR"
cp "$SRC_DIR/metadata.json" "$DEST_DIR/"
cp -r "$SRC_DIR/contents" "$DEST_DIR/"

mkdir -p "$(dirname "$KPACKAGE_DIR")"
ln -s "$DEST_DIR" "$KPACKAGE_DIR"


echo ""
echo "[OK] KVitals installed to: $DEST_DIR"
echo ""
echo "Next steps:"
echo "  1. Restart Plasma:  plasmashell --replace &"
echo "  2. Right-click panel → Add Widgets → search 'KVitals'"
echo "  3. Drag it onto your panel"
echo ""
echo "To uninstall: rm -rf $DEST_DIR $KPACKAGE_DIR"
