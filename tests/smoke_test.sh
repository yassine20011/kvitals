#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WIDGET_PATH="$(cd "$SCRIPT_DIR/.." && pwd)"
TIMEOUT=10
LOG=$(mktemp)
XVFB_PID=""
DBUS_PID=""

cleanup() {
    if [ -n "$XVFB_PID" ]; then
        kill "$XVFB_PID" 2>/dev/null || true
    fi
    if [ -n "$DBUS_PID" ]; then
        kill "$DBUS_PID" 2>/dev/null || true
    fi
    rm -f "$LOG"
}
trap cleanup EXIT

for required_command in plasmoidviewer timeout; do
    if ! command -v "$required_command" >/dev/null 2>&1; then
        echo "Error: required command '$required_command' is unavailable." >&2
        exit 1
    fi
done

PLASMA_VERSION="$(plasmoidviewer --version 2>&1 || true)"
if ! echo "$PLASMA_VERSION" | grep -qE '(^|[[:space:]])6\.'; then
    echo "Error: Plasma 6 plasmoidviewer is required; found: ${PLASMA_VERSION:-unknown}." >&2
    exit 1
fi

# Headless display setup
USE_XVFB_RUN=0
if [ -z "${DISPLAY:-}" ]; then
    if command -v Xvfb >/dev/null 2>&1; then
        Xvfb :99 -screen 0 1280x800x24 &
        XVFB_PID=$!
        export DISPLAY=:99
        sleep 1
    elif command -v xvfb-run >/dev/null 2>&1; then
        USE_XVFB_RUN=1
    else
        echo "Error: DISPLAY is not set and neither Xvfb nor xvfb-run is available." >&2
        exit 1
    fi
fi

# DBus session setup
if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    if command -v dbus-daemon >/dev/null 2>&1; then
        eval "$(dbus-daemon --session --fork --print-address=1 --print-pid=1 \
            | awk 'NR==1{addr=$0} NR==2{pid=$0} END{print "export DBUS_SESSION_BUS_ADDRESS=" addr; print "DBUS_PID=" pid}')"
    elif command -v dbus-launch >/dev/null 2>&1; then
        eval "$(dbus-launch --sh-syntax)"
        DBUS_PID=$DBUS_SESSION_BUS_PID
    else
        echo "Warning: dbus not found; plasmoidviewer may fail" >&2
    fi
fi

RUN_PREFIX=(plasmoidviewer)
if [ "$USE_XVFB_RUN" -eq 1 ]; then
    RUN_PREFIX=(xvfb-run -a plasmoidviewer)
fi

CASES=(
    "desktop|planar|floating|1"
    "horizontal-panel|horizontal|topedge|1"
    "vertical-panel|vertical|leftedge|1"
    "hidpi-horizontal-panel|horizontal|topedge|2"
)

echo "Running Plasma 6 smoke matrix on $WIDGET_PATH (${TIMEOUT}s per case)..."

for test_case in "${CASES[@]}"; do
    IFS='|' read -r name form_factor location scale_factor <<<"$test_case"
    : >"$LOG"
    echo "  - $name (form factor: $form_factor, location: $location, scale: $scale_factor)"

    set +e
    QT_SCALE_FACTOR="$scale_factor" \
    QT_LOGGING_RULES="qml.debug=true" \
        timeout "$TIMEOUT" "${RUN_PREFIX[@]}" \
            -a "$WIDGET_PATH" -f "$form_factor" -l "$location" >"$LOG" 2>&1
    EXIT_CODE=$?
    set -e

    # A healthy plasmoidviewer remains open until timeout. An early exit,
    # including code 0, does not prove that the widget initialized.
    if [ "$EXIT_CODE" -ne 124 ]; then
        echo "SMOKE TEST FAILED [$name]: plasmoidviewer exited early with code $EXIT_CODE"
        cat "$LOG"
        exit 1
    fi

    if grep -qiE "error when loading applet|package .* does not exist|Could not find requested component|module .* is not installed|Type .* unavailable|QQml.*Error|Segmentation fault|SIGSEGV|Aborted" "$LOG"; then
        echo "SMOKE TEST FAILED [$name]: fatal applet loading error detected"
        cat "$LOG"
        exit 1
    fi

    if grep -qiE "SyntaxError|TypeError|ReferenceError|Binding loop detected|Cannot assign|Unable to assign" "$LOG"; then
        echo "SMOKE TEST FAILED [$name]: QML runtime error detected"
        cat "$LOG"
        exit 1
    fi
done

echo "Smoke matrix passed on Plasma 6: desktop, horizontal, vertical, and HiDPI modes."
