import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors

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
    property string displayMode: Plasmoid.configuration.displayMode
    property int iconSize: Plasmoid.configuration.iconSize
    property string cpuIcon: Plasmoid.configuration.cpuIcon
    property string ramIcon: Plasmoid.configuration.ramIcon
    property string tempIcon: Plasmoid.configuration.tempIcon
    property string batteryIcon: Plasmoid.configuration.batteryIcon
    property string powerIcon: Plasmoid.configuration.powerIcon
    property string networkIcon: Plasmoid.configuration.networkIcon
    property string fontFamily: Plasmoid.configuration.fontFamily
    property int fontSize: Plasmoid.configuration.fontSize
    property int effectiveFontSize: fontSize > 0 ? fontSize : Kirigami.Theme.smallFont.pixelSize

    property bool useIcons: displayMode === "icons" || displayMode === "icons+text"
    property bool useText:  displayMode === "text"  || displayMode === "icons+text"

    // KSysGuard Sensors

    property int updateInterval: Plasmoid.configuration.updateInterval || 2000

    readonly property string netIfacePath: {
        if (networkInterface === "" || networkInterface === "auto")
            return "all";
        return networkInterface;
    }

    Sensors.Sensor {
        id: cpuSensor
        sensorId: "cpu/all/usage"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: ramUsedSensor
        sensorId: "memory/physical/used"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: ramTotalSensor
        sensorId: "memory/physical/total"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: tempSensor
        sensorId: "cpu/all/averageTemperature"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: netDownSensor
        sensorId: "network/" + root.netIfacePath + "/download"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: netUpSensor
        sensorId: "network/" + root.netIfacePath + "/upload"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: bat0ChargeSensor
        sensorId: "power/battery_BAT0/chargePercentage"
        updateRateLimit: root.updateInterval > 5000 ? root.updateInterval : 5000
    }

    Sensors.Sensor {
        id: bat0RateSensor
        sensorId: "power/battery_BAT0/chargeRate"
        updateRateLimit: root.updateInterval > 5000 ? root.updateInterval : 5000
    }

    // Fallback for laptops that use BAT1 instead of BAT0
    Sensors.Sensor {
        id: bat1ChargeSensor
        sensorId: "power/battery_BAT1/chargePercentage"
        updateRateLimit: root.updateInterval > 5000 ? root.updateInterval : 5000
    }

    Sensors.Sensor {
        id: bat1RateSensor
        sensorId: "power/battery_BAT1/chargeRate"
        updateRateLimit: root.updateInterval > 5000 ? root.updateInterval : 5000
    }

    property var activeBatChargeSensor: bat0ChargeSensor.status === Sensors.Sensor.Ready || bat1ChargeSensor.status !== Sensors.Sensor.Ready ? bat0ChargeSensor : bat1ChargeSensor
    property var activeBatRateSensor: bat0RateSensor.status === Sensors.Sensor.Ready || bat1RateSensor.status !== Sensors.Sensor.Ready ? bat0RateSensor : bat1RateSensor

    // --- Formatting helpers ---

    function formatBytes(bytes) {
        if (typeof bytes !== "number" || isNaN(bytes))
            return "...";
        var gb = bytes / (1024 * 1024 * 1024);
        return gb.toFixed(1);
    }

    function formatRate(bytesPerSec) {
        if (typeof bytesPerSec !== "number" || isNaN(bytesPerSec))
            return "...";
        var kbps = bytesPerSec / 1024;
        if (kbps >= 1024) {
            return (kbps / 1024).toFixed(1) + "M";
        }
        return Math.max(0, kbps).toFixed(1) + "K";
    }

    // --- Derived display values ---

    property string cpuValue: {
        if (cpuSensor.status !== Sensors.Sensor.Ready) return "...";
        return Math.round(cpuSensor.value) + "%";
    }

    property string ramValue: {
        if (ramUsedSensor.status !== Sensors.Sensor.Ready || ramTotalSensor.status !== Sensors.Sensor.Ready)
            return "...";
        return formatBytes(ramUsedSensor.value) + "/" + formatBytes(ramTotalSensor.value) + "G";
    }

    property string tempValue: {
        if (tempSensor.status !== Sensors.Sensor.Ready) return "--";
        return Math.round(tempSensor.value) + "°C";
    }

    property string batValue: {
        if (activeBatChargeSensor.status !== Sensors.Sensor.Ready) return "";
        return Math.round(activeBatChargeSensor.value) + "%";
    }

    property string batIcon: {
        if (activeBatRateSensor.status !== Sensors.Sensor.Ready) return "";
        return activeBatRateSensor.value > 0 ? "⚡" : "🔋";
    }

    property string powerValue: {
        if (activeBatRateSensor.status !== Sensors.Sensor.Ready) return "";
        var watts = Math.abs(activeBatRateSensor.value);
        if (watts < 0.01) return "";
        var sign = activeBatRateSensor.value > 0 ? "+" : "-";
        return sign + watts.toFixed(1) + "W";
    }

    property string netDownValue: {
        if (netDownSensor.status !== Sensors.Sensor.Ready) return "...";
        return formatRate(netDownSensor.value);
    }

    property string netUpValue: {
        if (netUpSensor.status !== Sensors.Sensor.Ready) return "...";
        return formatRate(netUpSensor.value);
    }

    compactRepresentation: RowLayout {
        id: compactRow
        spacing: Kirigami.Units.smallSpacing

        property var metricsModel: {
            var items = [];
            if (root.showCpu && root.cpuValue)
                items.push({ icon: root.cpuIcon, label: "CPU:", value: root.cpuValue });
            if (root.showRam && root.ramValue)
                items.push({ icon: root.ramIcon, label: "RAM:", value: root.ramValue });
            if (root.showTemp && root.tempValue && root.tempValue !== "--")
                items.push({ icon: root.tempIcon, label: "TEMP:", value: root.tempValue });
            if (root.showBattery && root.batValue)
                items.push({ icon: root.batteryIcon, label: "BAT:", value: root.batValue });
            if (root.showPower && root.powerValue)
                items.push({ icon: root.powerIcon, label: "PWR:", value: root.powerValue });
            if (root.showNetwork) {
                items.push({ icon: root.networkIcon, label: "NET:", value: "↓" + root.netDownValue + " ↑" + root.netUpValue });
            }
            return items;
        }

        Repeater {
            model: compactRow.metricsModel

            delegate: RowLayout {
                spacing: 2
                Layout.fillHeight: true

                // Separator
                PlasmaComponents.Label {
                    visible: index > 0
                    text: "|"
                    font.pixelSize: root.effectiveFontSize
                    font.family: root.fontFamily
                    color: Kirigami.Theme.textColor
                    opacity: 0.4
                    Layout.alignment: Qt.AlignVCenter
                }

                // Icon
                Kirigami.Icon {
                    visible: root.useIcons
                    source: modelData.icon
                    isMask: true
                    Layout.preferredWidth: root.iconSize
                    Layout.preferredHeight: root.iconSize
                    Layout.alignment: Qt.AlignVCenter
                }

                // Text label
                PlasmaComponents.Label {
                    visible: root.useText
                    text: modelData.label
                    font.pixelSize: root.effectiveFontSize
                    font.family: root.fontFamily
                    color: Kirigami.Theme.textColor
                    Layout.alignment: Qt.AlignVCenter
                }

                // Value
                PlasmaComponents.Label {
                    text: modelData.value
                    font.pixelSize: root.effectiveFontSize
                    font.family: root.fontFamily
                    color: Kirigami.Theme.textColor
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: root.expanded = !root.expanded
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
                if (root.showCpu) items.push({ label: "CPU Usage", value: root.cpuValue });
                if (root.showRam) items.push({ label: "Memory", value: root.ramValue });
                if (root.showTemp && root.tempValue !== "--") items.push({ label: "CPU Temp", value: root.tempValue });
                if (root.showBattery && root.batValue) items.push({ label: "Battery", value: root.batValue });
                if (root.showPower && root.powerValue) items.push({ label: "Power", value: root.powerValue });
                if (root.showNetwork) {
                    items.push({ label: "Network ↓", value: root.netDownValue });
                    items.push({ label: "Network ↑", value: root.netUpValue });
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
        if (root.showCpu && root.cpuValue) parts.push("CPU: " + root.cpuValue);
        if (root.showRam && root.ramValue) parts.push("RAM: " + root.ramValue);
        if (root.showTemp && root.tempValue && root.tempValue !== "--") parts.push("TEMP: " + root.tempValue);
        if (root.showBattery && root.batValue) parts.push("BAT: " + root.batValue);
        if (root.showPower && root.powerValue) parts.push("PWR: " + root.powerValue);
        if (root.showNetwork) parts.push("NET: ↓" + root.netDownValue + " ↑" + root.netUpValue);
        return parts.join("\n");
    }
}
