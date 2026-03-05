import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation

    property bool showCpu: Plasmoid.configuration.showCpu
    property bool showRam: Plasmoid.configuration.showRam
    property bool showTemp: Plasmoid.configuration.showTemp
    property bool showGpu: Plasmoid.configuration.showGpu
    property bool showBattery: Plasmoid.configuration.showBattery
    property bool showPower: Plasmoid.configuration.showPower
    property bool showNetwork: Plasmoid.configuration.showNetwork
    property string networkInterface: Plasmoid.configuration.networkInterface
    property string batteryDevice: ""
    property string displayMode: Plasmoid.configuration.displayMode
    property int iconSize: Plasmoid.configuration.iconSize
    property string cpuIcon: Plasmoid.configuration.cpuIcon
    property string ramIcon: Plasmoid.configuration.ramIcon
    property string tempIcon: Plasmoid.configuration.tempIcon
    property string gpuIcon: Plasmoid.configuration.gpuIcon
    property string batteryIcon: Plasmoid.configuration.batteryIcon
    property string powerIcon: Plasmoid.configuration.powerIcon
    property string networkIcon: Plasmoid.configuration.networkIcon
    property string fontFamily: Plasmoid.configuration.fontFamily
    property int fontSize: Plasmoid.configuration.fontSize
    property int effectiveFontSize: fontSize > 0 ? fontSize : Kirigami.Theme.smallFont.pixelSize

    property bool useIcons: displayMode === "icons" || displayMode === "icons+text"
    property bool useText:  displayMode === "text"  || displayMode === "icons+text"

    property string metricOrder: Plasmoid.configuration.metricOrder || "cpu,ram,temp,gpu,bat,pwr,net"
    property var orderedKeys: metricOrder.split(",").map(function(k) { return k.trim(); })

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
        id: gpuUsageAllSensor
        sensorId: "gpu/all/usage"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuUsage0Sensor
        sensorId: "gpu/gpu0/usage"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuUsage1Sensor
        sensorId: "gpu/gpu1/usage"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuUsage2Sensor
        sensorId: "gpu/gpu2/usage"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuUsage3Sensor
        sensorId: "gpu/gpu3/usage"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuVramUsedAllSensor
        sensorId: "gpu/all/usedVram"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuVramTotalAllSensor
        sensorId: "gpu/all/totalVram"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuVramUsedLegacySensor
        sensorId: "gpu/all/memory/used"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuVramTotalLegacySensor
        sensorId: "gpu/all/memory/total"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuVramUsed0Sensor
        sensorId: "gpu/gpu0/usedVram"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuVramTotal0Sensor
        sensorId: "gpu/gpu0/totalVram"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuVramUsed1Sensor
        sensorId: "gpu/gpu1/usedVram"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuVramTotal1Sensor
        sensorId: "gpu/gpu1/totalVram"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuVramUsed2Sensor
        sensorId: "gpu/gpu2/usedVram"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuVramTotal2Sensor
        sensorId: "gpu/gpu2/totalVram"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuVramUsed3Sensor
        sensorId: "gpu/gpu3/usedVram"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuVramTotal3Sensor
        sensorId: "gpu/gpu3/totalVram"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuTempAllSensor
        sensorId: "gpu/all/temperature"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuTemp0Sensor
        sensorId: "gpu/gpu0/temperature"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuTemp1Sensor
        sensorId: "gpu/gpu1/temperature"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuTemp2Sensor
        sensorId: "gpu/gpu2/temperature"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuTemp3Sensor
        sensorId: "gpu/gpu3/temperature"
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

    Plasma5Support.DataSource {
        id: batDeviceDetector
        engine: "executable"
        connectedSources: ["qdbus6 --literal org.kde.ksystemstats1 /org/kde/ksystemstats1 org.kde.ksystemstats1.allSensors"]
        onNewData: function(source, data) {
            if (data["exit code"] !== 0) return;
            var match = data["stdout"].match(/"power\/([^\/]+)\/chargePercentage"/);
            if (match) root.batteryDevice = match[1];
        }
    }

    Sensors.Sensor {
        id: batChargeSensor
        sensorId: "power/" + root.batteryDevice + "/chargePercentage"
        updateRateLimit: root.updateInterval > 5000 ? root.updateInterval : 5000
    }

    Sensors.Sensor {
        id: batRateSensor
        sensorId: "power/" + root.batteryDevice + "/chargeRate"
        updateRateLimit: root.updateInterval > 5000 ? root.updateInterval : 5000
    }

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

    function sensorValueOrNaN(sensor) {
        if (!sensor || sensor.status !== Sensors.Sensor.Ready)
            return NaN;
        if (typeof sensor.value !== "number" || isNaN(sensor.value))
            return NaN;
        return sensor.value;
    }

    function firstReadyNumber(sensors, requirePositive) {
        for (var i = 0; i < sensors.length; i++) {
            var value = sensorValueOrNaN(sensors[i]);
            if (isNaN(value))
                continue;
            if (requirePositive && value <= 0)
                continue;
            return value;
        }
        return NaN;
    }

    function maxReadyNumber(sensors, requirePositive) {
        var maxValue = NaN;
        for (var i = 0; i < sensors.length; i++) {
            var value = sensorValueOrNaN(sensors[i]);
            if (isNaN(value))
                continue;
            if (requirePositive && value <= 0)
                continue;
            if (isNaN(maxValue) || value > maxValue)
                maxValue = value;
        }
        return maxValue;
    }

    function firstReadyVramPair(pairs) {
        for (var i = 0; i < pairs.length; i++) {
            var used = sensorValueOrNaN(pairs[i].used);
            var total = sensorValueOrNaN(pairs[i].total);
            if (isNaN(used) || isNaN(total))
                continue;
            if (total <= 0 || used < 0)
                continue;
            return { used: used, total: total };
        }
        return null;
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

    property real gpuUsageNumber: {
        var aggregateUsage = firstReadyNumber([gpuUsageAllSensor], false);
        if (!isNaN(aggregateUsage))
            return aggregateUsage;
        return maxReadyNumber([gpuUsage0Sensor, gpuUsage1Sensor, gpuUsage2Sensor, gpuUsage3Sensor], false);
    }

    property var gpuVramPair: {
        return firstReadyVramPair([
            { used: gpuVramUsedAllSensor, total: gpuVramTotalAllSensor },
            { used: gpuVramUsedLegacySensor, total: gpuVramTotalLegacySensor },
            { used: gpuVramUsed0Sensor, total: gpuVramTotal0Sensor },
            { used: gpuVramUsed1Sensor, total: gpuVramTotal1Sensor },
            { used: gpuVramUsed2Sensor, total: gpuVramTotal2Sensor },
            { used: gpuVramUsed3Sensor, total: gpuVramTotal3Sensor }
        ]);
    }

    property real gpuTempNumber: {
        var aggregateTemp = firstReadyNumber([gpuTempAllSensor], true);
        if (!isNaN(aggregateTemp))
            return aggregateTemp;
        return maxReadyNumber([gpuTemp0Sensor, gpuTemp1Sensor, gpuTemp2Sensor, gpuTemp3Sensor], true);
    }

    property string gpuValue: {
        if (isNaN(gpuUsageNumber))
            return "";
        return Math.round(gpuUsageNumber) + "%";
    }

    property string gpuRamValue: {
        if (!gpuVramPair)
            return "";
        return formatBytes(gpuVramPair.used) + "/" + formatBytes(gpuVramPair.total) + "G";
    }

    property string gpuTempValue: {
        if (isNaN(gpuTempNumber))
            return "";
        return Math.round(gpuTempNumber) + "°C";
    }

    property string gpuDisplayValue: {
        var parts = [];
        if (gpuValue)
            parts.push(gpuValue);
        if (gpuRamValue)
            parts.push(gpuRamValue);
        if (gpuTempValue)
            parts.push(gpuTempValue);
        return parts.join(" ");
    }

    property bool hasGpuData: gpuDisplayValue.length > 0

    property bool hasGpuUsageData: gpuValue.length > 0
    property bool hasGpuVramData: gpuRamValue.length > 0
    property bool hasGpuTempData: gpuTempValue.length > 0

    property string batValue: {
        if (batChargeSensor.status !== Sensors.Sensor.Ready) return "";
        return Math.round(batChargeSensor.value) + "%";
    }

    property string batIcon: {
        if (batRateSensor.status !== Sensors.Sensor.Ready) return "";
        return batRateSensor.value > 0 ? "⚡" : "🔋";
    }

    property string powerValue: {
        if (batRateSensor.status !== Sensors.Sensor.Ready) return "";
        var watts = Math.abs(batRateSensor.value);
        if (watts < 0.01) return "0.0W";
        var sign = batRateSensor.value > 0 ? "+" : "-";
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

        TapHandler {
            onTapped: root.expanded = !root.expanded
        }

        property var metricsModel: {
            var items = [];
            for (var i = 0; i < root.orderedKeys.length; i++) {
                var key = root.orderedKeys[i];
                if (key === "cpu" && root.showCpu && root.cpuValue)
                    items.push({ icon: root.cpuIcon, label: "CPU:", value: root.cpuValue });
                else if (key === "ram" && root.showRam && root.ramValue)
                    items.push({ icon: root.ramIcon, label: "RAM:", value: root.ramValue });
                else if (key === "temp" && root.showTemp && root.tempValue && root.tempValue !== "--")
                    items.push({ icon: root.tempIcon, label: "TEMP:", value: root.tempValue });
                else if (key === "gpu" && root.showGpu && root.hasGpuData)
                    items.push({ icon: root.gpuIcon, label: "GPU:", value: root.gpuDisplayValue });
                else if (key === "bat" && root.showBattery && root.batValue)
                    items.push({ icon: root.batteryIcon, label: "BAT:", value: root.batValue });
                else if (key === "pwr" && root.showPower && root.powerValue)
                    items.push({ icon: root.powerIcon, label: "PWR:", value: root.powerValue });
                else if (key === "net" && root.showNetwork)
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
                for (var i = 0; i < root.orderedKeys.length; i++) {
                    var key = root.orderedKeys[i];
                    if (key === "cpu" && root.showCpu)
                        items.push({ label: "CPU Usage", value: root.cpuValue });
                    else if (key === "ram" && root.showRam)
                        items.push({ label: "Memory", value: root.ramValue });
                    else if (key === "temp" && root.showTemp && root.tempValue !== "--")
                        items.push({ label: "CPU Temp", value: root.tempValue });
                    else if (key === "gpu" && root.showGpu) {
                        if (root.hasGpuUsageData) items.push({ label: "GPU Usage", value: root.gpuValue });
                        if (root.hasGpuVramData) items.push({ label: "GPU VRAM", value: root.gpuRamValue });
                        if (root.hasGpuTempData) items.push({ label: "GPU Temp", value: root.gpuTempValue });
                    }
                    else if (key === "bat" && root.showBattery && root.batValue)
                        items.push({ label: "Battery", value: root.batValue });
                    else if (key === "pwr" && root.showPower && root.powerValue)
                        items.push({ label: "Power", value: root.powerValue });
                    else if (key === "net" && root.showNetwork) {
                        items.push({ label: "Network ↓", value: root.netDownValue });
                        items.push({ label: "Network ↑", value: root.netUpValue });
                    }
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
        for (var i = 0; i < root.orderedKeys.length; i++) {
            var key = root.orderedKeys[i];
            if (key === "cpu" && root.showCpu && root.cpuValue)
                parts.push("CPU: " + root.cpuValue);
            else if (key === "ram" && root.showRam && root.ramValue)
                parts.push("RAM: " + root.ramValue);
            else if (key === "temp" && root.showTemp && root.tempValue && root.tempValue !== "--")
                parts.push("TEMP: " + root.tempValue);
            else if (key === "gpu" && root.showGpu && root.hasGpuData) {
                if (root.hasGpuUsageData) parts.push("GPU: " + root.gpuValue);
                if (root.hasGpuVramData) parts.push("VRAM: " + root.gpuRamValue);
                if (root.hasGpuTempData) parts.push("GPU TEMP: " + root.gpuTempValue);
            }
            else if (key === "bat" && root.showBattery && root.batValue)
                parts.push("BAT: " + root.batValue);
            else if (key === "pwr" && root.showPower && root.powerValue)
                parts.push("PWR: " + root.powerValue);
            else if (key === "net" && root.showNetwork)
                parts.push("NET: ↓" + root.netDownValue + " ↑" + root.netUpValue);
        }
        return parts.join("\n");
    }
}
