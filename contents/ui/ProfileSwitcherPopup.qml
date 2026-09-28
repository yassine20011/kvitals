import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

PlasmaComponents.Popup {
    id: root

    property var profileSummaries: []
    property string activeProfileId: ""
    readonly property alias autoDismissInterval: dismissTimer.interval
    signal profileSelected(string id)

    focus: true
    closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside
    padding: Kirigami.Units.smallSpacing

    Timer {
        id: dismissTimer
        interval: 3000
        repeat: false
        onTriggered: root.close()
    }

    onAboutToShow: {
        _updatePosition();
        _selectActiveIndex();
        dismissTimer.restart();
    }

    onOpened: {
        listView.forceActiveFocus();
    }

    onClosed: {
        dismissTimer.stop();
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

    function _updatePosition() {
        var loc = Plasmoid.location;
        var spacing = Kirigami.Units.smallSpacing;
        if (loc === PlasmaCore.Types.BottomEdge) {
            y = -height - spacing;
            x = Math.round((parent.width - width) / 2);
        } else if (loc === PlasmaCore.Types.TopEdge) {
            y = parent.height + spacing;
            x = Math.round((parent.width - width) / 2);
        } else if (loc === PlasmaCore.Types.LeftEdge) {
            x = parent.width + spacing;
            y = Math.round((parent.height - height) / 2);
        } else if (loc === PlasmaCore.Types.RightEdge) {
            x = -width - spacing;
            y = Math.round((parent.height - height) / 2);
        } else {
            x = 0;
            y = parent.height + spacing;
        }
    }

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing
        width: Kirigami.Units.gridUnit * 12

        PlasmaComponents.Label {
            text: i18n("KVitals Profile")
            font.bold: true
            opacity: 0.7
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.topMargin: Kirigami.Units.smallSpacing / 2
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            implicitHeight: Math.min(contentHeight, Kirigami.Units.gridUnit * 16)
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
