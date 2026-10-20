.pragma library

var DEFAULT_SHORTCUT = "Meta+Shift+V";
var DISABLED_SHORTCUT = "none";

function initializeShortcut(configuredShortcut, globalShortcut) {
    var configured = configuredShortcut || DEFAULT_SHORTCUT;
    var global = String(globalShortcut || "");
    if (configured !== DISABLED_SHORTCUT && global === "") global = configured;
    if (configured === DISABLED_SHORTCUT) global = "";
    return { configuredShortcut: configured, globalShortcut: global };
}

function shortcutAfterGlobalChange(changedShortcut, configuredShortcut) {
    var changed = String(changedShortcut || "");
    if (changed !== "") return { configuredShortcut: changed, globalShortcut: changed };
    if (configuredShortcut === DISABLED_SHORTCUT) {
        return { configuredShortcut: DISABLED_SHORTCUT, globalShortcut: "" };
    }
    return { configuredShortcut: configuredShortcut || DEFAULT_SHORTCUT, globalShortcut: configuredShortcut || DEFAULT_SHORTCUT };
}
