#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

find_qt6_tool() {
    local candidate
    for candidate in "$@"; do
        if [[ "$candidate" == */* ]] && [ -x "$candidate" ]; then
            echo "$candidate"
            return 0
        elif command -v "$candidate" >/dev/null 2>&1; then
            command -v "$candidate"
            return 0
        fi
    done
    return 1
}

if ! QMLLINT="$(find_qt6_tool \
    qmllint6 qmllint-qt6 \
    /usr/lib/qt6/bin/qmllint /usr/lib64/qt6/bin/qmllint \
    qmllint)"; then
    echo "Error: Qt 6 qmllint is unavailable." >&2
    exit 1
fi

VERSION_OUTPUT="$("$QMLLINT" --version 2>&1 || true)"
if ! echo "$VERSION_OUTPUT" | grep -qE '(^|[[:space:]])6\.'; then
    echo "Error: Qt 6 qmllint is required; found: ${VERSION_OUTPUT:-unknown}." >&2
    exit 1
fi

mapfile -d '' QML_FILES < <(find "$PROJECT_ROOT/contents" "$SCRIPT_DIR/qml" -name '*.qml' -print0)

"$QMLLINT" \
    -I "$PROJECT_ROOT/contents/ui" \
    -I "$PROJECT_ROOT/contents/ui/models" \
    -I "$PROJECT_ROOT/contents/ui/sensors" \
    "${QML_FILES[@]}"
