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

if ! QML_TEST_RUNNER="$(find_qt6_tool \
    qmltestrunner6 qmltestrunner-qt6 \
    /usr/lib/qt6/bin/qmltestrunner /usr/lib64/qt6/bin/qmltestrunner \
    qmltestrunner)"; then
    echo "Error: Qt 6 qmltestrunner is unavailable." >&2
    exit 1
fi

if command -v ldd >/dev/null 2>&1 && ldd "$QML_TEST_RUNNER" 2>/dev/null | grep -q 'libQt5'; then
    echo "Error: Qt 5 qmltestrunner found; KVitals requires Qt 6." >&2
    exit 1
fi

export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-offscreen}"
export QT_QUICK_BACKEND="${QT_QUICK_BACKEND:-software}"
export QSG_RHI_BACKEND="${QSG_RHI_BACKEND:-software}"

RUNNER_ARGS=(
    -input "$SCRIPT_DIR/qml"
    -import "$PROJECT_ROOT/contents/ui"
    -import "$PROJECT_ROOT/contents/ui/models"
    -import "$PROJECT_ROOT/contents/ui/sensors"
)

echo "Running native Qt Quick tests with $QML_TEST_RUNNER..."
if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ] && command -v dbus-run-session >/dev/null 2>&1; then
    dbus-run-session -- "$QML_TEST_RUNNER" "${RUNNER_ARGS[@]}"
else
    "$QML_TEST_RUNNER" "${RUNNER_ARGS[@]}"
fi
