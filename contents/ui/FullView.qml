import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: fullView
    spacing: Kirigami.Units.smallSpacing
    Layout.preferredWidth: Kirigami.Units.gridUnit * 18
    Layout.preferredHeight: Kirigami.Units.gridUnit * 12

    required property var metricsModel
    required property color baseTextColor

    PlasmaComponents.Label {
        text: "KVitals"
        font.bold: true
        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.2
        Layout.alignment: Qt.AlignHCenter
        Layout.bottomMargin: Kirigami.Units.smallSpacing
    }

    Repeater {
        model: fullView.metricsModel

        delegate: RowLayout {
            required property var modelData

            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing

            PlasmaComponents.Label {
                text: modelData.label
                color: fullView.baseTextColor
                opacity: 0.7
                Layout.fillWidth: true
            }
            PlasmaComponents.Label {
                text: modelData.value
                font.bold: true
                color: modelData.color
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
