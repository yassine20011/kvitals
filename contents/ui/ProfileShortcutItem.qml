import QtQuick
import org.kde.kquickcontrols

KeySequenceItem {
    id: root

    property string configuredShortcut: ""
    property string globalShortcut: ""
    signal modified(string newShortcut)

    keySequence: {
        if (configuredShortcut && configuredShortcut !== "" && configuredShortcut !== "none") return configuredShortcut;
        return globalShortcut;
    }
    patterns: ShortcutPattern.Modifier | ShortcutPattern.ModifierAndKey

    onKeySequenceModified: {
        var s = String(keySequence);
        root.modified(s !== "" ? s : "none");
    }
}
