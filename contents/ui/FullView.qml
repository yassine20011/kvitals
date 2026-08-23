import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: fullView
    spacing: 0
    Layout.preferredWidth: Kirigami.Units.gridUnit * 18
    Layout.preferredHeight: Kirigami.Units.gridUnit * 22
    Layout.minimumWidth: Kirigami.Units.gridUnit * 15
    Layout.maximumWidth: Kirigami.Units.gridUnit * 24
    Layout.minimumHeight: Kirigami.Units.gridUnit * 10
    Layout.maximumHeight: Kirigami.Units.gridUnit * 36

    required property var groupsModel
    required property color baseTextColor
    required property color labelColor
    required property color iconColor
    required property bool fontBold
    required property var chartHistory
    required property int chartVersion
    required property bool pinned
    signal togglePinned()
    signal toggleMetricPin(string metricId)
    signal refreshRequested()

    readonly property int _rowHeight: Math.round(Kirigami.Units.gridUnit * 1.6)
    readonly property int _iconSz: Kirigami.Units.iconSizes.small

    // Persistent accordion expansion state across data updates
    property var expandedGroups: ({})

    function isGroupExpanded(key) {
        return Boolean(expandedGroups[key]);
    }

    function toggleGroup(key) {
        var copy = Object.assign({}, expandedGroups);
        copy[key] = !copy[key];
        expandedGroups = copy;
    }

    function resolveIcon(name) {
        if (!name) return "configure";
        if (name.indexOf("-symbolic") !== -1 && name.indexOf("/") === -1) {
            return Qt.resolvedUrl("../icons/" + name + ".svg");
        }
        return name;
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => disconnectSource(sourceName)
        function exec(cmd) {
            connectSource(cmd);
        }
    }

    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        contentWidth: availableWidth
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        Column {
            width: parent.width
            spacing: 0

            Repeater {
                model: fullView.groupsModel

                delegate: Column {
                    id: groupBlock
                    required property var modelData
                    required property int index
                    width: parent.width

                    readonly property string groupKey: modelData.key
                    readonly property bool isExpanded: fullView.isGroupExpanded(groupKey)

                    // Top-level Category Header (e.g. Temperature, Memory, Processor, Storage)
                    PlasmaComponents.ItemDelegate {
                        id: groupRow
                        width: parent.width
                        height: fullView._rowHeight

                        contentItem: RowLayout {
                            spacing: Kirigami.Units.smallSpacing
                            anchors.verticalCenter: parent.verticalCenter

                            Kirigami.Icon {
                                source: fullView.resolveIcon(groupBlock.modelData.icon)
                                isMask: true
                                color: fullView.iconColor
                                implicitWidth: fullView._iconSz
                                implicitHeight: fullView._iconSz
                                Layout.alignment: Qt.AlignVCenter
                            }

                            PlasmaComponents.Label {
                                text: groupBlock.modelData.groupLabel
                                font.bold: true
                                color: fullView.labelColor
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                Layout.alignment: Qt.AlignVCenter
                            }

                            PlasmaComponents.Label {
                                visible: !!groupBlock.modelData.aggregateValue
                                text: groupBlock.modelData.aggregateValue || ""
                                color: groupBlock.modelData.aggregateColor || fullView.labelColor
                                horizontalAlignment: Text.AlignRight
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Kirigami.Icon {
                                source: groupBlock.isExpanded ? "arrow-up" : "arrow-right"
                                isMask: true
                                color: fullView.baseTextColor
                                opacity: 0.45
                                implicitWidth: 10
                                implicitHeight: 10
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }

                        onClicked: fullView.toggleGroup(groupBlock.groupKey)
                    }

                    // Expanded Group Sub-sections & Metric List
                    Column {
                        width: parent.width
                        visible: groupBlock.isExpanded

                        Repeater {
                            model: groupBlock.modelData.sections

                            delegate: Column {
                                id: secBlock
                                required property var modelData
                                required property int index
                                width: parent.width

                                // Optional Sub-section header
                                PlasmaComponents.Label {
                                    visible: !!secBlock.modelData.sectionLabel
                                    text: secBlock.modelData.sectionLabel || ""
                                    font.bold: true
                                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                    color: fullView.labelColor
                                    opacity: 0.7
                                    leftPadding: Kirigami.Units.gridUnit
                                    topPadding: 4
                                    bottomPadding: 2
                                }

                                // Metric Items in this section
                                Repeater {
                                    model: secBlock.modelData.metrics

                                    delegate: PlasmaComponents.ItemDelegate {
                                        id: metricRow
                                        required property var modelData
                                        required property int index
                                        width: parent.width
                                        height: fullView._rowHeight

                                        contentItem: RowLayout {
                                            spacing: Kirigami.Units.smallSpacing
                                            anchors.verticalCenter: parent.verticalCenter

                                            // Pin checkmark indicator
                                            Kirigami.Icon {
                                                source: "dialog-ok-apply"
                                                isMask: true
                                                color: Kirigami.Theme.highlightColor
                                                implicitWidth: 12
                                                implicitHeight: 12
                                                opacity: metricRow.modelData.isPinned ? 1.0 : 0.0
                                                Layout.alignment: Qt.AlignVCenter
                                                Layout.leftMargin: 4
                                            }

                                            // Metric icon
                                            Kirigami.Icon {
                                                source: fullView.resolveIcon(metricRow.modelData.icon)
                                                isMask: true
                                                color: fullView.iconColor
                                                opacity: 0.65
                                                implicitWidth: fullView._iconSz
                                                implicitHeight: fullView._iconSz
                                                Layout.alignment: Qt.AlignVCenter
                                            }

                                            // Metric Sub-label
                                            PlasmaComponents.Label {
                                                text: metricRow.modelData.subLabel || metricRow.modelData.label
                                                color: fullView.labelColor
                                                opacity: 0.8
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                                Layout.alignment: Qt.AlignVCenter
                                            }

                                            // Metric Value
                                            PlasmaComponents.Label {
                                                text: metricRow.modelData.displayValue || "..."
                                                font.bold: fullView.fontBold
                                                color: metricRow.modelData.color || fullView.baseTextColor
                                                horizontalAlignment: Text.AlignRight
                                                Layout.alignment: Qt.AlignVCenter
                                                Layout.rightMargin: Kirigami.Units.smallSpacing
                                            }
                                        }

                                        onClicked: {
                                            fullView.toggleMetricPin(metricRow.modelData.id);
                                        }

                                        PlasmaComponents.ToolTip {
                                            text: metricRow.modelData.isPinned
                                                ? i18n("Click to unpin from panel")
                                                : i18n("Click to pin to panel")
                                            visible: metricRow.hovered
                                            delay: Kirigami.Units.toolTipDelay
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Footer separator
            Rectangle {
                width: parent.width
                height: 1
                color: fullView.baseTextColor
                opacity: 0.12
            }

            // Footer actions
            RowLayout {
                width: parent.width
                height: fullView._rowHeight
                spacing: 0

                Item { Layout.fillWidth: true }

                PlasmaComponents.ToolButton {
                    icon.name: "view-refresh-symbolic"
                    implicitWidth: fullView._rowHeight
                    implicitHeight: fullView._rowHeight
                    ToolTip.text: i18n("Refresh")
                    ToolTip.visible: hovered
                    ToolTip.delay: Kirigami.Units.toolTipDelay
                    onClicked: fullView.refreshRequested()
                }

                PlasmaComponents.ToolButton {
                    icon.name: "utilities-system-monitor"
                    implicitWidth: fullView._rowHeight
                    implicitHeight: fullView._rowHeight
                    ToolTip.text: i18n("System Monitor")
                    ToolTip.visible: hovered
                    ToolTip.delay: Kirigami.Units.toolTipDelay
                    onClicked: {
                        executable.exec("plasma-systemmonitor || ksysguard");
                    }
                }

                PlasmaComponents.ToolButton {
                    icon.name: "configure"
                    implicitWidth: fullView._rowHeight
                    implicitHeight: fullView._rowHeight
                    ToolTip.text: i18n("Configure KVitals...")
                    ToolTip.visible: hovered
                    ToolTip.delay: Kirigami.Units.toolTipDelay
                    onClicked: {
                        var act = Plasmoid.internalAction("configure") || Plasmoid.action("configure");
                        if (act) {
                            act.trigger();
                        }
                    }
                }

                PlasmaComponents.ToolButton {
                    icon.name: fullView.pinned ? "window-unpin" : "window-pin"
                    implicitWidth: fullView._rowHeight
                    implicitHeight: fullView._rowHeight
                    ToolTip.text: fullView.pinned ? i18n("Unpin window") : i18n("Keep window open")
                    ToolTip.visible: hovered
                    ToolTip.delay: Kirigami.Units.toolTipDelay
                    onClicked: fullView.togglePinned()
                }

                Item { Layout.fillWidth: true }
            }
        }
    }
}
