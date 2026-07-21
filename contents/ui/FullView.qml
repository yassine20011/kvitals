import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: fullView
    spacing: Kirigami.Units.smallSpacing
    Layout.preferredWidth: Kirigami.Units.gridUnit * 24
    Layout.preferredHeight: Kirigami.Units.gridUnit * 14

    required property var metricsModel
    required property color baseTextColor
    required property color labelColor
    required property color iconColor
    required property bool fontBold
    required property var chartHistory
    required property int chartVersion
    required property bool pinned
    signal togglePinned()
    required property bool dgpuToggleVisible
    required property bool dgpuActive
    required property string dgpuIcon
    signal toggleDgpu()

    RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: Kirigami.Units.smallSpacing
        PlasmaComponents.Label {
            text: "KVitals"
            font.bold: true
            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.2
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
        }
        PlasmaComponents.ToolButton {
            visible: fullView.dgpuToggleVisible
            icon.name: fullView.dgpuIcon
            icon.color: Kirigami.Theme.textColor
            checkable: true
            checked: fullView.dgpuActive
            opacity: checked ? 1.0 : 0.5
            onToggled: fullView.toggleDgpu()
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            PlasmaComponents.ToolTip.text: checked
                ? i18n("Discrete GPU monitoring active (uses power)")
                : i18n("Discrete GPU monitoring paused (power saving)")
            PlasmaComponents.ToolTip.visible: hovered
        }
        PlasmaComponents.ToolButton {
            icon.name: fullView.pinned ? "window-unpin" : "window-pin"
            onClicked: fullView.togglePinned()
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        }
    }

    Repeater {
        model: fullView.metricsModel

        delegate: RowLayout {
            id: metricRow
            required property var modelData

            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing

            // chartVersion appears in the binding so it re-evaluates when the
            // history arrays (mutated in place) receive new samples.
            readonly property var _history: fullView.chartVersion >= 0
                && modelData.chartKey && fullView.chartHistory[modelData.chartKey]
                ? fullView.chartHistory[modelData.chartKey] : []
            readonly property bool _hasChart: _history.length > 1

            Row {
                visible: !!modelData.icon
                spacing: 1
                Layout.alignment: Qt.AlignVCenter
                Repeater {
                    model: {
                        var src = modelData.icon;
                        if (!src) return [];
                        return typeof src === "string" ? [src] : src;
                    }
                    delegate: Kirigami.Icon {
                        source: modelData
                        isMask: true
                        color: fullView.iconColor
                        width: Kirigami.Units.iconSizes.small
                        height: Kirigami.Units.iconSizes.small
                    }
                }
            }

            PlasmaComponents.Label {
                text: modelData.label
                color: fullView.labelColor
                opacity: 0.7
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            // Sparkline: last maxChartPoints samples, right-aligned so the
            // newest sample is always at the right edge. Rows with a fixed
            // range (percentages, temps: chartMax) scale to it so flat lines
            // sit at their true level; rates scale to the window's maximum.
            Canvas {
                visible: metricRow._hasChart
                Layout.preferredWidth: 80
                Layout.preferredHeight: 24
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: Kirigami.Units.smallSpacing

                property int _trigger: fullView.chartVersion
                on_TriggerChanged: requestPaint()

                onPaint: {
                    var ctx = getContext("2d");
                    if (!ctx) return;
                    ctx.reset();

                    var data = metricRow._history;
                    if (data.length < 2) return;

                    var maxPts = 60;
                    var maxVal = Math.max(Math.max.apply(null, data), modelData.chartMax || 1);
                    var step = width / (maxPts - 1);
                    var offset = maxPts - data.length;
                    var c = modelData.color;

                    ctx.strokeStyle = Qt.rgba(c.r, c.g, c.b, 1);
                    ctx.lineWidth = 1.5;
                    ctx.beginPath();
                    for (var i = 0; i < data.length; i++) {
                        var x = (offset + i) * step;
                        var y = height - (data[i] / maxVal) * (height - 4) - 2;
                        if (i === 0) ctx.moveTo(x, y);
                        else ctx.lineTo(x, y);
                    }
                    ctx.stroke();
                }
            }

            PlasmaComponents.Label {
                text: modelData.value
                font.bold: fullView.fontBold
                color: modelData.color
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
