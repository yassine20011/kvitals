import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "./sensors"

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation

    // --- Configuration properties ---

    property bool showCpu: Plasmoid.configuration.showCpu
    property bool showRam: Plasmoid.configuration.showRam
    property bool showTemp: Plasmoid.configuration.showTemp
    property bool showGpu: Plasmoid.configuration.showGpu
    property bool showBattery: Plasmoid.configuration.showBattery
    property bool showPower: Plasmoid.configuration.showPower
    property bool showNetwork: Plasmoid.configuration.showNetwork
    property string networkInterface: Plasmoid.configuration.networkInterface
    property string batteryDevice: Plasmoid.configuration.batteryDevice
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

    property int updateInterval: Plasmoid.configuration.updateInterval || 2000

    // --- Color configuration properties ---

    property bool useCustomColors: Plasmoid.configuration.useCustomColors
    property string fontColor: Plasmoid.configuration.fontColor
    property bool enableThresholdColors: Plasmoid.configuration.enableThresholdColors
    property string warningColor: Plasmoid.configuration.warningColor || "#e5a50a"
    property string criticalColor: Plasmoid.configuration.criticalColor || "#da4453"

    property int cpuWarningThreshold: Plasmoid.configuration.cpuWarningThreshold
    property int cpuCriticalThreshold: Plasmoid.configuration.cpuCriticalThreshold
    property int tempWarningThreshold: Plasmoid.configuration.tempWarningThreshold
    property int tempCriticalThreshold: Plasmoid.configuration.tempCriticalThreshold
    property int ramWarningThreshold: Plasmoid.configuration.ramWarningThreshold
    property int ramCriticalThreshold: Plasmoid.configuration.ramCriticalThreshold
    property int gpuWarningThreshold: Plasmoid.configuration.gpuWarningThreshold
    property int gpuCriticalThreshold: Plasmoid.configuration.gpuCriticalThreshold
    property int gpuTempWarningThreshold: Plasmoid.configuration.gpuTempWarningThreshold
    property int gpuTempCriticalThreshold: Plasmoid.configuration.gpuTempCriticalThreshold
    property int batteryWarningThreshold: Plasmoid.configuration.batteryWarningThreshold
    property int batteryCriticalThreshold: Plasmoid.configuration.batteryCriticalThreshold

    // --- Computed base text color ---

    property color baseTextColor: (useCustomColors && fontColor !== "") ? fontColor : Kirigami.Theme.textColor

    // --- Pre-resolved per-metric colors (reactive properties) ---

    property color cpuColor: enableThresholdColors
        ? Utils.resolveColor(cpu.cpuNumericValue, cpuWarningThreshold, cpuCriticalThreshold,
                             warningColor, criticalColor, baseTextColor, false)
        : baseTextColor

    property color tempColor: enableThresholdColors
        ? Utils.resolveColor(temp.tempNumericValue, tempWarningThreshold, tempCriticalThreshold,
                             warningColor, criticalColor, baseTextColor, false)
        : baseTextColor

    property color ramColor: enableThresholdColors
        ? Utils.resolveColor(memory.ramPercentage, ramWarningThreshold, ramCriticalThreshold,
                             warningColor, criticalColor, baseTextColor, false)
        : baseTextColor

    property color gpuColor: enableThresholdColors
        ? Utils.resolveColor(gpu.gpuUsageNumber, gpuWarningThreshold, gpuCriticalThreshold,
                             warningColor, criticalColor, baseTextColor, false)
        : baseTextColor

    property color gpuTempColor: enableThresholdColors
        ? Utils.resolveColor(gpu.gpuTempNumber, gpuTempWarningThreshold, gpuTempCriticalThreshold,
                             warningColor, criticalColor, baseTextColor, false)
        : baseTextColor

    property color batteryColor: enableThresholdColors
        ? Utils.resolveColor(battery.batNumericValue, batteryWarningThreshold, batteryCriticalThreshold,
                             warningColor, criticalColor, baseTextColor, true)
        : baseTextColor

    // --- Sensor components ---

    CpuSensors {
        id: cpu
        updateInterval: root.updateInterval
    }

    MemorySensors {
        id: memory
        updateInterval: root.updateInterval
    }

    TempSensors {
        id: temp
        updateInterval: root.updateInterval
    }

    GpuSensors {
        id: gpu
        updateInterval: root.updateInterval
    }

    BatterySensors {
        id: battery
        updateInterval: root.updateInterval
        batteryDevice: root.batteryDevice || "auto"
    }

    NetworkSensors {
        id: network
        updateInterval: root.updateInterval
        networkInterface: root.networkInterface
    }

    // --- Representations ---

    compactRepresentation: CompactView {
        metricsModel: {
            var items = [];
            for (var i = 0; i < root.orderedKeys.length; i++) {
                var key = root.orderedKeys[i];
                if (key === "cpu" && root.showCpu && cpu.cpuValue)
                    items.push({ icon: root.cpuIcon, label: "CPU:", value: cpu.cpuValue,
                                 color: root.cpuColor });
                else if (key === "ram" && root.showRam && memory.ramValue)
                    items.push({ icon: root.ramIcon, label: "RAM:", value: memory.ramValue,
                                 color: root.ramColor });
                else if (key === "temp" && root.showTemp && temp.tempValue && temp.tempValue !== "--")
                    items.push({ icon: root.tempIcon, label: "TEMP:", value: temp.tempValue,
                                 color: root.tempColor });
                else if (key === "gpu" && root.showGpu && gpu.hasGpuData) {
                    var gpuSegs = [];
                    if (gpu.hasGpuUsageData)
                        gpuSegs.push({ value: gpu.gpuValue,   color: root.gpuColor });
                    if (gpu.hasGpuVramData)
                        gpuSegs.push({ value: gpu.gpuRamValue, color: root.baseTextColor });
                    if (gpu.hasGpuTempData)
                        gpuSegs.push({ value: gpu.gpuTempValue, color: root.gpuTempColor });
                    items.push({ icon: root.gpuIcon, label: "GPU:", segments: gpuSegs,
                                 color: root.gpuColor });
                }
                else if (key === "bat" && root.showBattery && battery.batValue)
                    items.push({ icon: root.batteryIcon, label: "BAT:", value: battery.batValue,
                                 color: root.batteryColor });
                else if (key === "pwr" && root.showPower && battery.powerValue)
                    items.push({ icon: root.powerIcon, label: "PWR:", value: battery.powerValue,
                                 color: root.baseTextColor });
                else if (key === "net" && root.showNetwork)
                    items.push({ icon: root.networkIcon, label: "NET:", value: "↓" + network.netDownValue + " ↑" + network.netUpValue,
                                 color: root.baseTextColor });
            }
            return items;
        }
        useIcons: root.useIcons
        useText: root.useText
        effectiveFontSize: root.effectiveFontSize
        fontFamily: root.fontFamily
        iconSize: root.iconSize
        baseTextColor: root.baseTextColor
        onToggleExpanded: root.expanded = !root.expanded
    }

    fullRepresentation: FullView {
        baseTextColor: root.baseTextColor
        metricsModel: {
            var items = [];
            for (var i = 0; i < root.orderedKeys.length; i++) {
                var key = root.orderedKeys[i];
                if (key === "cpu" && root.showCpu)
                    items.push({ label: "CPU Usage", value: cpu.cpuValue,
                                 color: root.cpuColor });
                else if (key === "ram" && root.showRam)
                    items.push({ label: "Memory", value: memory.ramValue,
                                 color: root.ramColor });
                else if (key === "temp" && root.showTemp && temp.tempValue !== "--")
                    items.push({ label: "CPU Temp", value: temp.tempValue,
                                 color: root.tempColor });
                else if (key === "gpu" && root.showGpu) {
                    if (gpu.hasGpuUsageData) items.push({ label: "GPU Usage", value: gpu.gpuValue,
                                                          color: root.gpuColor });
                    if (gpu.hasGpuVramData) items.push({ label: "GPU VRAM", value: gpu.gpuRamValue,
                                                         color: root.baseTextColor });
                    if (gpu.hasGpuTempData) items.push({ label: "GPU Temp", value: gpu.gpuTempValue,
                                                         color: root.gpuTempColor });
                }
                else if (key === "bat" && root.showBattery && battery.batValue)
                    items.push({ label: "Battery", value: battery.batValue,
                                 color: root.batteryColor });
                else if (key === "pwr" && root.showPower && battery.powerValue)
                    items.push({ label: "Power", value: battery.powerValue,
                                 color: root.baseTextColor });
                else if (key === "net" && root.showNetwork) {
                    items.push({ label: "Network ↓", value: network.netDownValue, color: root.baseTextColor });
                    items.push({ label: "Network ↑", value: network.netUpValue, color: root.baseTextColor });
                }
            }
            return items;
        }
    }

    // --- Tooltip ---

    toolTipMainText: "KVitals"
    toolTipSubText: {
        var parts = [];
        for (var i = 0; i < root.orderedKeys.length; i++) {
            var key = root.orderedKeys[i];
            if (key === "cpu" && root.showCpu && cpu.cpuValue)
                parts.push("CPU: " + cpu.cpuValue);
            else if (key === "ram" && root.showRam && memory.ramValue)
                parts.push("RAM: " + memory.ramValue);
            else if (key === "temp" && root.showTemp && temp.tempValue && temp.tempValue !== "--")
                parts.push("TEMP: " + temp.tempValue);
            else if (key === "gpu" && root.showGpu && gpu.hasGpuData) {
                if (gpu.hasGpuUsageData) parts.push("GPU: " + gpu.gpuValue);
                if (gpu.hasGpuVramData) parts.push("VRAM: " + gpu.gpuRamValue);
                if (gpu.hasGpuTempData) parts.push("GPU TEMP: " + gpu.gpuTempValue);
            }
            else if (key === "bat" && root.showBattery && battery.batValue)
                parts.push("BAT: " + battery.batValue);
            else if (key === "pwr" && root.showPower && battery.powerValue)
                parts.push("PWR: " + battery.powerValue);
            else if (key === "net" && root.showNetwork)
                parts.push("NET: ↓" + network.netDownValue + " ↑" + network.netUpValue);
        }
        return parts.join("\n");
    }
}
