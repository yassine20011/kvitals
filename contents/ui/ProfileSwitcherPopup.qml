import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

PlasmaCore.Dialog {
    id: root

    property var profileSummaries: []
    property string activeProfileId: ""
    signal profileSelected(string id)

    visualParent: parent
    location: Plasmoid.location
    type: PlasmaCore.Dialog.AppletPopup
    backgroundHints: PlasmaCore.Dialog.StandardBackground
    flags: Qt.Window | Qt.WindowStaysOnTopHint

    property bool _hasBeenActive: false

    function open() {
        _hasBeenActive = false;
        _selectActiveIndex();
        show();
        requestActivate();
        dismissTimer.restart();
    }

    function close() {
        visible = false;
        _hasBeenActive = false;
        dismissTimer.stop();
    }

    onActiveChanged: {
        if (active) {
            _hasBeenActive = true;
        } else if (_hasBeenActive && visible) {
            root.close();
        }
    }

    onVisibleChanged: {
        if (visible) {
            _selectActiveIndex();
            dismissTimer.restart();
            listView.forceActiveFocus();
        } else {
            dismissTimer.stop();
        }
    }

    function _selectActiveIndex() {
        for (var i = 0; i < profileSummaries.length; i++) {
            if (profileSummaries[i].id === activeProfileId) {
                listView.currentIndex = i;
                return;
            }
        }
        listView.currentIndex = 0;
    }

    mainItem: ColumnLayout {
        id: layout
        spacing: Kirigami.Units.smallSpacing
        implicitWidth: Kirigami.Units.gridUnit * 14
        implicitHeight: headerLabel.implicitHeight + separator.implicitHeight + listView.implicitHeight + Kirigami.Units.smallSpacing * 4

        Timer {
            id: dismissTimer
            interval: 3000
            repeat: false
            onTriggered: root.close()
        }

        Shortcut {
            sequence: "Escape"
            onActivated: root.close()
        }

        Shortcut {
            sequence: "Return"
            onActivated: listView._activateCurrent()
        }

        Shortcut {
            sequence: "Enter"
            onActivated: listView._activateCurrent()
        }

        PlasmaComponents.Label {
            id: headerLabel
            text: i18n("KVitals Profile")
            font.bold: true
            opacity: 0.7
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            Layout.topMargin: Kirigami.Units.smallSpacing / 2
        }

        Kirigami.Separator {
            id: separator
            Layout.fillWidth: true
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            implicitHeight: Math.min(Math.max(contentHeight, Kirigami.Units.gridUnit * 2), Kirigami.Units.gridUnit * 16)
            model: root.profileSummaries
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 0
            PlasmaComponents.ScrollBar.vertical: PlasmaComponents.ScrollBar {}

            delegate: PlasmaComponents.ItemDelegate {
                id: delegateItem
                width: listView.width
                highlighted: ListView.isCurrentItem
                readonly property bool isActive: modelData.id === root.activeProfileId

                contentItem: RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        source: "checkmark"
                        visible: delegateItem.isActive
                        implicitWidth: Kirigami.Units.iconSizes.small
                        implicitHeight: Kirigami.Units.iconSizes.small
                    }

                    Item {
                        visible: !delegateItem.isActive
                        implicitWidth: Kirigami.Units.iconSizes.small
                        implicitHeight: Kirigami.Units.iconSizes.small
                    }

                    PlasmaComponents.Label {
                        text: modelData.name
                        font.bold: delegateItem.isActive
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                onClicked: {
                    root.profileSelected(modelData.id);
                    root.close();
                }

                onHoveredChanged: {
                    if (hovered) {
                        listView.currentIndex = index;
                        dismissTimer.restart();
                    }
                }
            }

            Keys.onUpPressed: function(event) {
                dismissTimer.restart();
                if (currentIndex > 0) {
                    currentIndex--;
                } else {
                    currentIndex = count - 1;
                }
                event.accepted = true;
            }

            Keys.onDownPressed: function(event) {
                dismissTimer.restart();
                if (currentIndex < count - 1) {
                    currentIndex++;
                } else {
                    currentIndex = 0;
                }
                event.accepted = true;
            }

            Keys.onReturnPressed: function(event) {
                _activateCurrent();
                event.accepted = true;
            }

            Keys.onEnterPressed: function(event) {
                _activateCurrent();
                event.accepted = true;
            }

            Keys.onEscapePressed: function(event) {
                root.close();
                event.accepted = true;
            }

            function _activateCurrent() {
                if (currentIndex >= 0 && currentIndex < root.profileSummaries.length) {
                    root.profileSelected(root.profileSummaries[currentIndex].id);
                    root.close();
                }
            }
        }
    }
}
