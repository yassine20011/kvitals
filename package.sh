#!/usr/bin/env bash
set -e

PLASMOID_NAME="org.kde.plasma.kvitals"
VERSION=$(grep '"Version"' metadata.json | cut -d '"' -f 4)
FILENAME="${PLASMOID_NAME}-v${VERSION}.plasmoid"

echo "📦 Packaging $PLASMOID_NAME version $VERSION..."

# A .plasmoid file is just a ZIP archive containing the package files
# We exclude the git directory, install scripts, and screenshots
zip -r "$FILENAME" \
    metadata.json \
    contents \
    LICENSE \
    README.md \
    -x "*.git*" \
    -x "install.sh" \
    -x "install-remote.sh" \
    -x "package.sh" \
    -x "*.DS_Store"


echo "✅ Created package: $FILENAME"