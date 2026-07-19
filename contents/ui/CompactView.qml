import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

RowLayout {
    id: compactRow
    spacing: Kirigami.Units.smallSpacing

    required property var metricsModel
    required property bool useIcons
    required property bool useText
    required property int effectiveFontSize
    required property string fontFamily
    required property bool fontBold
    required property int iconSize
    required property color baseTextColor
    required property color labelColor
    required property color iconColor
    required property string layoutType
    required property real labelOpacity
    required property real separatorOpacity

    readonly property bool isVertical: layoutType === "vertical"

    signal toggleExpanded()

    TapHandler {
        onTapped: compactRow.toggleExpanded()
    }

    // Shared segments renderer
    component SegmentsRow: Row {
        required property var segments
        spacing: 2

        Repeater {
            model: segments
            delegate: Row {
                required property var modelData
                required property int index
                spacing: 2

                PlasmaComponents.Label {
                    visible: index > 0
                    text: "·"
                    font.pixelSize: compactRow.effectiveFontSize
                    font.family: compactRow.fontFamily
                    font.bold: compactRow.fontBold
                    color: compactRow.baseTextColor
                    opacity: compactRow.separatorOpacity
                }
                PlasmaComponents.Label {
                    text: modelData.value
                    font.pixelSize: compactRow.effectiveFontSize
                    font.family: compactRow.fontFamily
                    font.bold: compactRow.fontBold
                    color: modelData.color
                }
            }
        }
    }

    Repeater {
        model: compactRow.metricsModel

        delegate: Item {
            required property var modelData
            required property int index

            implicitWidth:  loader.implicitWidth
            implicitHeight: loader.implicitHeight

            Loader {
                id: loader
                anchors.fill: parent
                sourceComponent: compactRow.isVertical ? verticalDelegate : horizontalDelegate

                property var itemData:  modelData
                property int itemIndex: index
            }
        }
    }

    // ── Horizontal delegate (unchanged behaviour) ──────────────────────────

    Component {
        id: horizontalDelegate

        RowLayout {
            spacing: 2
            Layout.fillHeight: true

            PlasmaComponents.Label {
                visible: itemIndex > 0 && !itemData.hideSeparator
                text: "|"
                font.pixelSize: compactRow.effectiveFontSize
                font.family: compactRow.fontFamily
                color: compactRow.baseTextColor
                opacity: compactRow.separatorOpacity
                Layout.alignment: Qt.AlignVCenter
            }

            Row {
                visible: compactRow.useIcons
                spacing: 1
                Layout.alignment: Qt.AlignVCenter
                Repeater {
                    model: {
                        var src = itemData.icon;
                        if (!src) return [];
                        return typeof src === "string" ? [src] : src;
                    }
                    delegate: Kirigami.Icon {
                        source: modelData
                        isMask: true
                        color: compactRow.iconColor
                        width: compactRow.iconSize
                        height: compactRow.iconSize
                    }
                }
            }

            PlasmaComponents.Label {
                visible: compactRow.useText
                text: itemData.label
                font.pixelSize: compactRow.effectiveFontSize
                font.family: compactRow.fontFamily
                color: compactRow.labelColor
                opacity: compactRow.labelOpacity
                Layout.alignment: Qt.AlignVCenter
            }

            PlasmaComponents.Label {
                visible: !itemData.segments
                text: itemData.value || ""
                font.pixelSize: compactRow.effectiveFontSize
                font.family: compactRow.fontFamily
                font.bold: compactRow.fontBold
                color: itemData.color || compactRow.baseTextColor
                Layout.alignment: Qt.AlignVCenter
            }

            SegmentsRow {
                visible: !!itemData.segments
                segments: itemData.segments || []
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    // ── Vertical delegate (value on top, icon+label below) ─────────────────

    Component {
        id: verticalDelegate

        RowLayout {
            spacing: Kirigami.Units.smallSpacing
            Layout.fillHeight: true

            // Thin line separator between metrics
            Rectangle {
                visible: itemIndex > 0 && !itemData.hideSeparator
                width: 1
                Layout.fillHeight: true
                color: compactRow.baseTextColor
                opacity: compactRow.separatorOpacity
            }

            ColumnLayout {
                spacing: 1
                Layout.alignment: Qt.AlignVCenter

                // Top: value(s)
                RowLayout {
                    spacing: 0
                    Layout.alignment: Qt.AlignHCenter

                    PlasmaComponents.Label {
                        visible: !itemData.segments
                        text: itemData.value || ""
                        font.pixelSize: compactRow.effectiveFontSize
                        font.family: compactRow.fontFamily
                        font.bold: compactRow.fontBold
                        color: itemData.color || compactRow.baseTextColor
                        horizontalAlignment: Text.AlignHCenter
                    }

                    SegmentsRow {
                        visible: !!itemData.segments
                        segments: itemData.segments || []
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                // Bottom: icon + label
                RowLayout {
                    visible: compactRow.useIcons || compactRow.useText
                    spacing: 2
                    Layout.alignment: Qt.AlignHCenter

                    Row {
                        visible: compactRow.useIcons
                        spacing: 1
                        Layout.alignment: Qt.AlignVCenter
                        Repeater {
                            model: {
                                var src = itemData.icon;
                                if (!src) return [];
                                return typeof src === "string" ? [src] : src;
                            }
                            delegate: Kirigami.Icon {
                                source: modelData
                                isMask: true
                                color: compactRow.iconColor
                                width:  Math.round(compactRow.iconSize * 0.85)
                                height: Math.round(compactRow.iconSize * 0.85)
                            }
                        }
                    }

                    PlasmaComponents.Label {
                        visible: compactRow.useText
                        text: {
                            var lbl = itemData.label || "";
                            return lbl.endsWith(":") ? lbl.slice(0, -1) : lbl;
                        }
                        font.pixelSize: Math.max(8, compactRow.effectiveFontSize - 2)
                        font.family: compactRow.fontFamily
                        color: compactRow.labelColor
                        opacity: compactRow.labelOpacity
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }
    }
}
