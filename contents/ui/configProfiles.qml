import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasmoid
import org.kde.kquickcontrols
import "models"

KCM.SimpleKCM {
    id: profilesPage

    ProfileManager {
        id: profileManager
        manageOnly: true
    }

    property bool unsavedChanges: false
    property string _editingId: ""
    property string _editingText: ""
    property string cfg_configuredShortcut: ""

    function saveConfig() {
        var seqStr = cfg_configuredShortcut;
        Plasmoid.globalShortcut = (seqStr && seqStr !== "none") ? seqStr : "";
        unsavedChanges = false;
    }

    Kirigami.PromptDialog {
        id: deleteConfirmDialog
        property string targetId: ""
        property string targetName: ""
        title: i18n("Delete Profile")
        subtitle: i18n("Delete \"%1\"? This cannot be undone.", targetName)
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
        onAccepted: {
            profileManager.deleteProfile(targetId);
            targetId = "";
            targetName = "";
        }
        onRejected: {
            targetId = "";
            targetName = "";
        }
    }

    Kirigami.FormLayout {
        id: form

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Information
            text: i18n("Profile activation is disabled while settings are open. Switch profiles from the widget.")
            visible: true
        }

        // Active profile indicator
        RowLayout {
            Kirigami.FormData.label: i18n("Active profile:")
            spacing: Kirigami.Units.smallSpacing

            QQC2.Label {
                text: profileManager.activeProfileName
                font.bold: true
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Profiles")
        }

        // Profile list
        ColumnLayout {
            spacing: Kirigami.Units.smallSpacing
            Layout.fillWidth: true

            Repeater {
                model: profileManager.profileSummaries

                delegate: RowLayout {
                    id: profileRow
                    spacing: Kirigami.Units.smallSpacing
                    Layout.fillWidth: true

                    required property var modelData
                    readonly property bool isActive: modelData.id === profileManager.activeProfileId
                    readonly property bool isEditing: profilesPage._editingId === modelData.id

                    Kirigami.Icon {
                        source: "dialog-ok-apply"
                        visible: profileRow.isActive
                        implicitWidth: Kirigami.Units.iconSizes.small
                        implicitHeight: Kirigami.Units.iconSizes.small
                    }

                    Item {
                        visible: !profileRow.isActive
                        implicitWidth: Kirigami.Units.iconSizes.small
                        implicitHeight: Kirigami.Units.iconSizes.small
                    }

                    QQC2.TextField {
                        id: nameField
                        visible: profileRow.isEditing
                        text: profilesPage._editingText
                        Layout.fillWidth: true
                        onTextChanged: profilesPage._editingText = text
                        Keys.onReturnPressed: _commitRename()
                        Keys.onEscapePressed: _cancelRename()
                        Component.onCompleted: {
                            if (profileRow.isEditing) {
                                forceActiveFocus();
                                selectAll();
                            }
                        }
                        function _commitRename() {
                            var t = profilesPage._editingText.trim();
                            if (t.length > 0) profileManager.renameProfile(profileRow.modelData.id, t);
                            profilesPage._editingId = "";
                        }
                        function _cancelRename() {
                            profilesPage._editingId = "";
                        }
                    }

                    QQC2.Label {
                        visible: !profileRow.isEditing
                        text: modelData.name
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    QQC2.ToolButton {
                        visible: !profileRow.isEditing
                        icon.name: "document-edit"
                        display: QQC2.AbstractButton.IconOnly
                        QQC2.ToolTip.text: i18n("Rename")
                        QQC2.ToolTip.visible: hovered
                        onClicked: {
                            profilesPage._editingId = profileRow.modelData.id;
                            profilesPage._editingText = profileRow.modelData.name;
                        }
                    }

                    QQC2.ToolButton {
                        visible: profileRow.isEditing
                        icon.name: "dialog-ok"
                        display: QQC2.AbstractButton.IconOnly
                        QQC2.ToolTip.text: i18n("Save name")
                        QQC2.ToolTip.visible: hovered
                        onClicked: nameField._commitRename()
                    }

                    QQC2.ToolButton {
                        visible: !profileRow.isEditing
                        icon.name: "edit-copy"
                        display: QQC2.AbstractButton.IconOnly
                        QQC2.ToolTip.text: i18n("Duplicate")
                        QQC2.ToolTip.visible: hovered
                        onClicked: {
                            var newName = profileRow.modelData.name + i18n(" (copy)");
                            profileManager.duplicateProfile(profileRow.modelData.id, newName);
                        }
                    }

                    QQC2.ToolButton {
                        visible: !profileRow.isEditing
                        icon.name: "edit-delete"
                        display: QQC2.AbstractButton.IconOnly
                        enabled: profileManager.profileSummaries.length > 1 && !profileRow.isActive && !modelData.isDefault
                        QQC2.ToolTip.text: modelData.isDefault
                            ? i18n("Cannot delete the original Default profile")
                            : (profileRow.isActive
                                ? i18n("Cannot delete the active profile")
                                : (profileManager.profileSummaries.length > 1
                                    ? i18n("Delete")
                                    : i18n("Cannot delete the only profile")))
                        QQC2.ToolTip.visible: hovered
                        onClicked: {
                            deleteConfirmDialog.targetId = profileRow.modelData.id;
                            deleteConfirmDialog.targetName = profileRow.modelData.name;
                            deleteConfirmDialog.open();
                        }
                    }
                }
            }
        }

        // New profile row
        RowLayout {
            Kirigami.FormData.label: " "
            spacing: Kirigami.Units.smallSpacing

            QQC2.TextField {
                id: newProfileField
                placeholderText: i18n("New profile name…")
                Layout.preferredWidth: Kirigami.Units.gridUnit * 14
                Keys.onReturnPressed: _addProfile()
                function _addProfile() {
                    var name = text.trim();
                    if (name.length === 0) return;
                    profileManager.createProfile(name);
                    text = "";
                }
            }

            QQC2.Button {
                text: i18n("Add")
                icon.name: "list-add"
                enabled: newProfileField.text.trim().length > 0
                onClicked: newProfileField._addProfile()
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Shortcut")
        }

        KeySequenceItem {
            id: shortcutItem
            Kirigami.FormData.label: i18n("Profile switcher:")
            keySequence: {
                var cfg = cfg_configuredShortcut;
                if (cfg && cfg !== "" && cfg !== "none") return cfg;
                return Plasmoid.globalShortcut;
            }
            patterns: ShortcutPattern.Modifier | ShortcutPattern.ModifierAndKey
            onKeySequenceModified: {
                var s = String(keySequence);
                cfg_configuredShortcut = (s !== "") ? s : "none";
                profilesPage.unsavedChanges = true;
            }
        }
    }
}
