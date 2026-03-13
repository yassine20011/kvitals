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
    required property bool expanded

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
                visible: index > 0
                text: "|"
                font.pixelSize: compactRow.effectiveFontSize
                font.family: compactRow.fontFamily
                color: Kirigami.Theme.textColor
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
                color: Kirigami.Theme.textColor
                Layout.alignment: Qt.AlignVCenter
            }

            PlasmaComponents.Label {
                text: modelData.value
                font.pixelSize: compactRow.effectiveFontSize
                font.family: compactRow.fontFamily
                color: Kirigami.Theme.textColor
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
