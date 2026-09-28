import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasmoid

KCM.SimpleKCM {
    id: profilesPage

    // ProfileManager is accessed via the plasmoid root context.
    // This page does not use cfg_* properties because profile switching
    // must take effect immediately (not deferred to Apply).
    // The KCM Apply/Cancel cycle applies to the other config pages, not this one.

    // Editing state for inline rename
    property string _editingId: ""
    property string _editingText: ""

    // Warn user before switching profiles while other pages may have unsaved changes.
    // AppletConfiguration.qml exposes applyButton.enabled as the unsaved-changes indicator
    // but it is not accessible from here. We use a conservative heuristic: show a
    // confirmation dialog any time a profile switch is requested from this page.
    // The user can dismiss it if they have no unsaved changes.
    Kirigami.PromptDialog {
        id: switchConfirmDialog
        property string targetId: ""
        title: i18n("Switch Profile")
        subtitle: i18n("Switching profiles will overwrite any unsaved changes in the other configuration tabs. Continue?")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
        onAccepted: {
            profileManager.activateProfile(targetId);
            targetId = "";
        }
        onRejected: {
            targetId = "";
        }
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

                    // Active checkmark
                    Kirigami.Icon {
                        source: "dialog-ok-apply"
                        visible: profileRow.isActive
                        implicitWidth:  Kirigami.Units.iconSizes.small
                        implicitHeight: Kirigami.Units.iconSizes.small
                    }
                    // Spacer when not active
                    Item {
                        visible: !profileRow.isActive
                        implicitWidth:  Kirigami.Units.iconSizes.small
                        implicitHeight: Kirigami.Units.iconSizes.small
                    }

                    // Name display or inline rename field
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

                    // Rename button
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

                    // Commit rename button (shown when editing)
                    QQC2.ToolButton {
                        visible: profileRow.isEditing
                        icon.name: "dialog-ok"
                        display: QQC2.AbstractButton.IconOnly
                        QQC2.ToolTip.text: i18n("Save name")
                        QQC2.ToolTip.visible: hovered
                        onClicked: nameField._commitRename()
                    }

                    // Duplicate button
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

                    // Delete button
                    QQC2.ToolButton {
                        visible: !profileRow.isEditing
                        icon.name: "edit-delete"
                        display: QQC2.AbstractButton.IconOnly
                        enabled: profileManager.profileSummaries.length > 1
                        QQC2.ToolTip.text: profileManager.profileSummaries.length > 1
                            ? i18n("Delete")
                            : i18n("Cannot delete the only profile")
                        QQC2.ToolTip.visible: hovered
                        onClicked: {
                            deleteConfirmDialog.targetId = profileRow.modelData.id;
                            deleteConfirmDialog.targetName = profileRow.modelData.name;
                            deleteConfirmDialog.open();
                        }
                    }

                    // Activate button (shown for inactive profiles)
                    QQC2.Button {
                        visible: !profileRow.isActive && !profileRow.isEditing
                        text: i18n("Activate")
                        icon.name: "system-run"
                        onClicked: {
                            switchConfirmDialog.targetId = profileRow.modelData.id;
                            switchConfirmDialog.open();
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
    }
}
