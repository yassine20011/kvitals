import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation

    property bool showCpu: Plasmoid.configuration.showCpu
    property bool showRam: Plasmoid.configuration.showRam
    property bool showTemp: Plasmoid.configuration.showTemp
    property bool showBattery: Plasmoid.configuration.showBattery
    property bool showPower: Plasmoid.configuration.showPower
    property bool showNetwork: Plasmoid.configuration.showNetwork
    property string networkInterface: Plasmoid.configuration.networkInterface

    property string cpuText: "..."
    property string ramText: "..."
    property string tempText: "..."
    property string batText: "..."
    property string powerText: "..."
    property string netText: "..."

    Plasma5Support.DataSource {
        id: statsSource
        engine: "executable"

        property string scriptPath: Qt.resolvedUrl("../scripts/sys-stats.sh").toString().replace("file://", "")

        connectedSources: ["bash " + scriptPath + " " + root.networkInterface]

        interval: Plasmoid.configuration.updateInterval

        onNewData: function(source, data) {
            if (data["exit code"] !== 0) return;

            var stdout = data["stdout"].trim();
            if (stdout.length === 0) return;

            try {
                var stats = JSON.parse(stdout);

                root.cpuText = "CPU: " + stats.cpu + "%";
                root.ramText = "RAM: " + stats.ram_used + "/" + stats.ram_total + "G";

                if (stats.temp !== "N/A") {
                    root.tempText = "TEMP: " + stats.temp + "°C";
                } else {
                    root.tempText = "TEMP: --";
                }

                if (stats.bat !== "N/A") {
                    var batIcon = stats.bat_icon || "";
                    root.batText = batIcon + "BAT: " + stats.bat + "%";
                } else {
                    root.batText = "";
                }

                if (stats.power !== "N/A") {
                    var powerSign = stats.power_sign || "";
                    root.powerText = "PWR: " + powerSign + stats.power + "W";
                    console.log("KVitals: Power data parsed - " + root.powerText);
                } else {
                    root.powerText = "";
                    console.log("KVitals: No power data available");
                }

                root.netText = "NET: ↓" + stats.net_down + " ↑" + stats.net_up;
                console.log("KVitals: showPower=" + root.showPower + ", powerText=" + root.powerText);
            } catch (e) {
                console.log("sys-state parse error: " + e + " | raw: " + stdout);
            }
        }
    }

    compactRepresentation: RowLayout {
        id: compactRow
        spacing: 0

        PlasmaComponents.Label {
            id: statsLabel
            Layout.fillHeight: true
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            font.family: "monospace"
            color: Kirigami.Theme.textColor

            text: {
                var parts = [];
                if (root.showCpu && root.cpuText) parts.push(root.cpuText);
                if (root.showRam && root.ramText) parts.push(root.ramText);
                if (root.showTemp && root.tempText) parts.push(root.tempText);
                if (root.showBattery && root.batText) parts.push(root.batText);
                if (root.showPower && root.powerText) parts.push(root.powerText);
                if (root.showNetwork && root.netText) parts.push(root.netText);
                if (parts.length === 0) return "KVitals";
                return parts.join("  |  ");
            }
        }
    }

    fullRepresentation: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing
        Layout.preferredWidth: Kirigami.Units.gridUnit * 18
        Layout.preferredHeight: Kirigami.Units.gridUnit * 12

        PlasmaComponents.Label {
            text: "KVitals"
            font.bold: true
            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.2
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: Kirigami.Units.smallSpacing
        }

        Repeater {
            model: {
                var items = [];
                if (root.showCpu) items.push({ label: "CPU Usage", value: root.cpuText.replace("CPU: ", "") });
                if (root.showRam) items.push({ label: "Memory", value: root.ramText.replace("RAM: ", "") });
                if (root.showTemp) items.push({ label: "CPU Temp", value: root.tempText.replace("TEMP: ", "") });
                if (root.showBattery) items.push({ label: "Battery", value: root.batText.replace(/.*BAT: /, "") });
                if (root.showPower) items.push({ label: "Power", value: root.powerText.replace("PWR: ", "") });
                if (root.showNetwork) {
                    var netParts = root.netText.replace("NET: ", "").split(" ↑");
                    items.push({ label: "Network ↓", value: netParts[0].replace("↓", "") });
                    items.push({ label: "Network ↑", value: netParts[1] || "0K" });
                }
                return items;
            }

            delegate: RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.largeSpacing
                Layout.rightMargin: Kirigami.Units.largeSpacing

                PlasmaComponents.Label {
                    text: modelData.label
                    opacity: 0.7
                    Layout.fillWidth: true
                }
                PlasmaComponents.Label {
                    text: modelData.value
                    font.bold: true
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }

    toolTipMainText: "KVitals"
    toolTipSubText: {
        var parts = [];
        if (root.showCpu && root.cpuText) parts.push(root.cpuText);
        if (root.showRam && root.ramText) parts.push(root.ramText);
        if (root.showTemp && root.tempText) parts.push(root.tempText);
        if (root.showBattery && root.batText) parts.push(root.batText);
        if (root.showPower && root.powerText) parts.push(root.powerText);
        if (root.showNetwork && root.netText) parts.push(root.netText);
        return parts.join("\n");
    }
}
