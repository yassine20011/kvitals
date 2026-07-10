import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

// Root is a plain Item that only sizes to its content — no layout bias
// so Plasma can draw the panel background at the correct size.
Item {
    id: compactRow

    required property var metricsModel
    required property bool useIcons
    required property bool useText
    required property int effectiveFontSize
    required property string fontFamily
    required property bool fontBold
    required property int iconSize
    required property color baseTextColor
    required property string layoutType
    property int compactSpacing: 0

    readonly property bool isRow:    layoutType === "horizontal"
    readonly property bool isColumn: layoutType !== "horizontal"

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
                    opacity: 0.5
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

    // ── Horizontal layout: all items in one row ──────────────────────────

    Component {
        id: rowLayoutComponent

        RowLayout {
            spacing: Kirigami.Units.smallSpacing
            Repeater {
                model: compactRow.metricsModel
                delegate: RowLayout {
                    spacing: 2
                    Layout.fillHeight: true

                    required property var modelData
                    required property int index

                    PlasmaComponents.Label {
                        visible: index > 0 && !modelData.hideSeparator
                        text: "|"
                        font.pixelSize: compactRow.effectiveFontSize
                        font.family: compactRow.fontFamily
                        color: compactRow.baseTextColor
                        opacity: 0.4
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Kirigami.Icon {
                        visible: compactRow.useIcons
                        source: modelData.icon
                        isMask: true
                        color: modelData.iconColor || compactRow.baseTextColor
                        Layout.preferredWidth: compactRow.iconSize
                        Layout.preferredHeight: compactRow.iconSize
                        Layout.alignment: Qt.AlignVCenter
                    }

                    PlasmaComponents.Label {
                        visible: compactRow.useText
                        text: modelData.label
                        font.pixelSize: compactRow.effectiveFontSize
                        font.family: compactRow.fontFamily
                        color: compactRow.baseTextColor
                        Layout.alignment: Qt.AlignVCenter
                    }

                    PlasmaComponents.Label {
                        visible: !modelData.segments
                        text: modelData.value || ""
                        font.pixelSize: compactRow.effectiveFontSize
                        font.family: compactRow.fontFamily
                        font.bold: compactRow.fontBold
                        color: modelData.color || compactRow.baseTextColor
                        Layout.alignment: Qt.AlignVCenter
                    }

                    SegmentsRow {
                        visible: !!modelData.segments
                        segments: modelData.segments || []
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }
    }

    // ── Column layout: each item on its own row, stacked vertically ──────

    Component {
        id: columnLayoutComponent

        ColumnLayout {
            spacing: compactRow.compactSpacing
            Repeater {
                model: compactRow.metricsModel
                delegate: RowLayout {
                    spacing: 2

                    required property var modelData

                    Kirigami.Icon {
                        visible: compactRow.useIcons
                        source: modelData.icon
                        isMask: true
                        color: modelData.iconColor || compactRow.baseTextColor
                        Layout.preferredWidth: compactRow.iconSize
                        Layout.preferredHeight: compactRow.iconSize
                        Layout.alignment: Qt.AlignVCenter
                    }

                    PlasmaComponents.Label {
                        visible: compactRow.useText
                        text: modelData.label
                        font.pixelSize: compactRow.effectiveFontSize
                        font.family: compactRow.fontFamily
                        color: compactRow.baseTextColor
                        Layout.alignment: Qt.AlignVCenter
                    }

                    PlasmaComponents.Label {
                        visible: !modelData.segments
                        text: modelData.value || ""
                        font.pixelSize: compactRow.effectiveFontSize
                        font.family: compactRow.fontFamily
                        font.bold: compactRow.fontBold
                        color: modelData.color || compactRow.baseTextColor
                        Layout.alignment: Qt.AlignVCenter
                    }

                    SegmentsRow {
                        visible: !!modelData.segments
                        segments: modelData.segments || []
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }
    }

    // ── Outer container switched by layoutType ───────────────────────────

    // Inner loader sizes to its content; the outer Item sizes to the loader.
    Loader {
        id: inner
        sourceComponent: compactRow.isRow ? rowLayoutComponent : columnLayoutComponent
    }

    // Expose inner layout size so Plasma background fills correctly
    implicitWidth:  inner.implicitWidth
    implicitHeight: inner.implicitHeight
}
