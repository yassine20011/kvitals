import test from "node:test";
import assert from "node:assert/strict";
import { loadQmlLibrary } from "../helpers.js";

const Shortcuts = loadQmlLibrary("contents/ui/models/ShortcutLogic.js");

test("shortcut initialization supplies the default only when needed", () => {
    assert.deepEqual({ ...Shortcuts.initializeShortcut("", "") }, {
        configuredShortcut: Shortcuts.DEFAULT_SHORTCUT,
        globalShortcut: Shortcuts.DEFAULT_SHORTCUT
    });
    assert.deepEqual({ ...Shortcuts.initializeShortcut("Meta+F8", "") }, {
        configuredShortcut: "Meta+F8",
        globalShortcut: "Meta+F8"
    });
});

test("explicitly disabling the shortcut survives initialization and change events", () => {
    assert.deepEqual({ ...Shortcuts.initializeShortcut(Shortcuts.DISABLED_SHORTCUT, "Meta+Shift+V") }, {
        configuredShortcut: Shortcuts.DISABLED_SHORTCUT,
        globalShortcut: ""
    });
    assert.deepEqual({ ...Shortcuts.shortcutAfterGlobalChange("", Shortcuts.DISABLED_SHORTCUT) }, {
        configuredShortcut: Shortcuts.DISABLED_SHORTCUT,
        globalShortcut: ""
    });
});

test("a cleared live shortcut self-heals from persisted configuration", () => {
    assert.deepEqual({ ...Shortcuts.shortcutAfterGlobalChange("", "Meta+F8") }, {
        configuredShortcut: "Meta+F8",
        globalShortcut: "Meta+F8"
    });
    assert.equal(Shortcuts.shortcutAfterGlobalChange("Alt+V", "Meta+F8").configuredShortcut, "Alt+V");
});
