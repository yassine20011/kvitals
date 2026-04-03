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
    required property int iconSize
    required property color baseTextColor


    signal toggleExpanded()

    TapHandler {
        onTapped: compactRow.toggleExpanded()
    }

    Repeater {
        model: compactRow.metricsModel

        delegate: RowLayout {
            required property var modelData
            required property int index

            spacing: 2
            Layout.fillHeight: true

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
                text: modelData.value || ""
                visible: !modelData.segments
                font.pixelSize: compactRow.effectiveFontSize
                font.family: compactRow.fontFamily
                color: modelData.color
                Layout.alignment: Qt.AlignVCenter
            }

            Row {
                visible: !!modelData.segments
                spacing: 2
                Layout.alignment: Qt.AlignVCenter

                Repeater {
                    model: modelData.segments || []
                    delegate: Row {
                        required property var modelData
                        required property int index
                        spacing: 2

                        PlasmaComponents.Label {
                            visible: index > 0
                            text: "·"
                            font.pixelSize: compactRow.effectiveFontSize
                            font.family: compactRow.fontFamily
                            color: compactRow.baseTextColor
                            opacity: 0.5
                        }

                        PlasmaComponents.Label {
                            text: modelData.value
                            font.pixelSize: compactRow.effectiveFontSize
                            font.family: compactRow.fontFamily
                            color: modelData.color
                        }
                    }
                }
            }
        }
    }
}
