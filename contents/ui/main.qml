import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support
import "./sensors"

PlasmoidItem {
    id: root
    property bool _dbg: { console.warn("[KVitals] main.qml: constructing..."); return true; }

    property bool transparentBackground: Plasmoid.configuration.transparentBackground
    Plasmoid.backgroundHints: root.transparentBackground ? PlasmaCore.Types.NoBackground : PlasmaCore.Types.DefaultBackground

    preferredRepresentation: compactRepresentation

    // --- Configuration properties ---

    property bool showCpu: Plasmoid.configuration.showCpu
    property bool showRam: Plasmoid.configuration.showRam
    property bool showTemp: Plasmoid.configuration.showTemp
    property bool showGpu: Plasmoid.configuration.showGpu
    property bool showBattery: Plasmoid.configuration.showBattery
    property bool showPower: Plasmoid.configuration.showPower
    property bool showNetwork: Plasmoid.configuration.showNetwork
    property bool showDisk: Plasmoid.configuration.showDisk
    property bool showFan: Plasmoid.configuration.showFan
    property bool compactShowCpu: Plasmoid.configuration.compactShowCpu
    property bool compactShowRam: Plasmoid.configuration.compactShowRam
    property bool compactShowTemp: Plasmoid.configuration.compactShowTemp
    property bool compactShowGpu: Plasmoid.configuration.compactShowGpu
    property bool compactShowBattery: Plasmoid.configuration.compactShowBattery
    property bool compactShowPower: Plasmoid.configuration.compactShowPower
    property bool compactShowNetwork: Plasmoid.configuration.compactShowNetwork
    property bool compactShowDisk: Plasmoid.configuration.compactShowDisk
    property bool compactShowFan: Plasmoid.configuration.compactShowFan
    property string networkInterface: Plasmoid.configuration.networkInterface
    property string batteryDevice: Plasmoid.configuration.batteryDevice
    property string gpuSelection: Plasmoid.configuration.gpuSelection
    property string gpuLabels: Plasmoid.configuration.gpuLabels
    property string displayMode: Plasmoid.configuration.displayMode
    property string layoutType: Plasmoid.configuration.layoutType
    property bool mergeCpuTemp: Plasmoid.configuration.mergeCpuTemp
    property bool mergeCpuFreq: Plasmoid.configuration.mergeCpuFreq
    property bool showCpuFreq: Plasmoid.configuration.showCpuFreq
    property bool showCpuPower: Plasmoid.configuration.showCpuPower
    // RAPL CPU power draw state
    property real cpuPowerWatts: 0
    property real _prevEnergyUJ: -1
    property real _prevTimestampUSec: 0
    property bool cpuPowerSupported: false
    property bool mergeBatPwr: Plasmoid.configuration.mergeBatPwr
    property bool splitGpu: Plasmoid.configuration.splitGpu
    property string gpuMetrics: Plasmoid.configuration.gpuMetrics
    property int iconSize: Plasmoid.configuration.iconSize
    property int compactSpacing: Plasmoid.configuration.compactSpacing
    property string cpuIcon: Plasmoid.configuration.cpuIcon
    property string ramIcon: Plasmoid.configuration.ramIcon
    property string tempIcon: Plasmoid.configuration.tempIcon
    property string gpuIcon: Plasmoid.configuration.gpuIcon
    property string batteryIcon: Plasmoid.configuration.batteryIcon
    property string powerIcon: Plasmoid.configuration.powerIcon
    property string networkIcon: Plasmoid.configuration.networkIcon
    property string diskDevice: Plasmoid.configuration.diskDevice
    property string diskIcon: Plasmoid.configuration.diskIcon
    property string fanIcon: Plasmoid.configuration.fanIcon
    property string fontFamily: Plasmoid.configuration.fontFamily
    property int fontSize: Plasmoid.configuration.fontSize
    property bool fontBold: Plasmoid.configuration.fontBold
    property int effectiveFontSize: fontSize > 0 ? fontSize : Kirigami.Theme.smallFont.pixelSize

    property bool useIcons: displayMode === "icons" || displayMode === "icons+text"
    property bool useText: displayMode === "text" || displayMode === "icons+text"

    property string metricOrder: Plasmoid.configuration.metricOrder || "cpu,ram,temp,gpu,bat,pwr,net,disk"
    property var orderedKeys: metricOrder.split(",").map(function (k) {
        return k.trim();
    })

    property int updateInterval: Plasmoid.configuration.updateInterval || 2000
    property string tempUnit: Plasmoid.configuration.tempUnit || "C"
    property string networkUnit: Plasmoid.configuration.networkUnit || "bytes"
    property string fanUnit: Plasmoid.configuration.fanUnit || "rpm"

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
    property int diskTempWarningThreshold: Plasmoid.configuration.diskTempWarningThreshold
    property int diskTempCriticalThreshold: Plasmoid.configuration.diskTempCriticalThreshold

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

    property color diskTempColor: enableThresholdColors
        ? Utils.resolveColor(disk.diskTempNumber, diskTempWarningThreshold, diskTempCriticalThreshold,
            warningColor, criticalColor, baseTextColor, false)
        : baseTextColor

    // --- Deferred sensor loading ---
    // Sensors are loaded AFTER the window attachment is complete to avoid
    // triggering a SIGSEGV in KirigamiPlasmaStyle's PlasmaTheme::syncColors()
    // during the recursive QQuickItemPrivate::refWindow() walk at boot.
    // See: https://github.com/nicehash/KVitals/issues/42

    property bool _sensorsReady: sensorLoader.status === Loader.Ready
    property var cpu:     _sensorsReady ? sensorLoader.item.cpu     : _nullCpu
    property var memory:  _sensorsReady ? sensorLoader.item.memory  : _nullMemory
    property var temp:    _sensorsReady ? sensorLoader.item.temp    : _nullTemp
    property var gpu:     _sensorsReady ? sensorLoader.item.gpu     : _nullGpu
    property var battery: _sensorsReady ? sensorLoader.item.battery : _nullBattery
    property var network: _sensorsReady ? sensorLoader.item.network : _nullNetwork
    property var disk:    _sensorsReady ? sensorLoader.item.disk    : _nullDisk
    property var fans:    _sensorsReady ? sensorLoader.item.fans    : _nullFans

    // Safe defaults so bindings don't error before sensors load
    QtObject {
        id: _nullCpu
        property string cpuValue: ""
        property string cpuFreqValue: ""
        property real cpuNumericValue: NaN
    }
    QtObject {
        id: _nullMemory
        property string ramValue: ""
        property real ramPercentage: NaN
    }
    QtObject {
        id: _nullTemp
        property string tempValue: "--"
        property real tempNumericValue: NaN
    }
    QtObject {
        id: _nullGpu
        property real gpuUsageNumber: NaN
        property real gpuTempNumber: NaN
        property string gpuValue: ""
        property string gpuRamValue: ""
        property string gpuTempValue: ""
        property string gpuDisplayValue: ""
        property bool hasGpuData: false
        property bool hasGpuUsageData: false
        property bool hasGpuVramData: false
        property bool hasGpuTempData: false
        property var gpuDataList: []
        property var discoveredGpus: []
    }
    QtObject {
        id: _nullBattery
        property string batValue: ""
        property string powerValue: ""
        property real batNumericValue: NaN
    }
    QtObject {
        id: _nullNetwork
        property string netDownValue: "0"
        property string netUpValue: "0"
    }
    QtObject {
        id: _nullDisk
        property string diskReadValue: "0"
        property string diskWriteValue: "0"
        property string diskUsedValue: "..."
        property string diskTotalValue: "..."
        property string diskTempValue: ""
        property real diskTempNumber: NaN
    }
    QtObject {
        id: _nullFans
        property string fanValue: ""
        property bool hasFanData: false
    }

    Loader {
        id: sensorLoader
        active: false
        sourceComponent: Item {
            property alias cpu:     _cpu
            property alias memory:  _memory
            property alias temp:    _temp
            property alias gpu:     _gpu
            property alias battery: _battery
            property alias network: _network
            property alias disk:    _disk
            property alias fans:    _fans

            CpuSensors {
                id: _cpu
                updateInterval: root.updateInterval
            }

            MemorySensors {
                id: _memory
                updateInterval: root.updateInterval
            }

            TempSensors {
                id: _temp
                updateInterval: root.updateInterval
                tempUnit: root.tempUnit
            }

            GpuSensors {
                id: _gpu
                updateInterval: root.updateInterval
                gpuSelection: root.gpuSelection
                gpuLabels: root.gpuLabels
                tempUnit: root.tempUnit
                gpuMetrics: root.gpuMetrics
            }

            BatterySensors {
                id: _battery
                updateInterval: root.updateInterval
                batteryDevice: root.batteryDevice || "auto"
            }

            NetworkSensors {
                id: _network
                updateInterval: root.updateInterval
                networkInterface: root.networkInterface
                networkUnit: root.networkUnit
            }

            DiskSensors {
                id: _disk
                updateInterval: root.updateInterval
                enabled: root.showDisk
                tempUnit: root.tempUnit
                networkUnit: root.networkUnit
                diskDevice: root.diskDevice
            }

            FanSensors {
                id: _fans
                updateInterval: root.updateInterval
                fanUnit: root.fanUnit
            }
        }
    }

    // Activate the sensor loader after the initial refWindow() walk is complete.
    // The SIGSEGV in PlasmaTheme::syncColors() happens synchronously during
    // ShellCorona::load() → refWindow(), so deferring to the next event loop
    // iteration (Timer interval: 0) guarantees we're past the dangerous window.
    Timer {
        id: sensorActivationTimer
        interval: 0
        repeat: false
        onTriggered: {
            console.warn("[KVitals] main.qml: deferred load — activating sensors...");
            sensorLoader.active = true;
        }
    }

    // --- CPU Power Draw (RAPL) ---

    Plasma5Support.DataSource {
        id: cpuPowerSource
        engine: "executable"

        onNewData: function(sourceName, data) {
            disconnectSource(sourceName);
            if (data["exit code"] !== 0) return;

            var energyStr = (data["stdout"] || "").trim();
            if (energyStr.length === 0) return;

            var currentEnergy = parseInt(energyStr);
            if (isNaN(currentEnergy) || currentEnergy < 0) return;

            var currentTimestamp = new Date().getTime() * 1000; // microseconds

            if (root._prevEnergyUJ <= 0) {
                root._prevEnergyUJ = currentEnergy;
                root._prevTimestampUSec = currentTimestamp;
                root.cpuPowerSupported = true;
                root.cpuPowerWatts = 0;
            } else {
                var energyDelta = currentEnergy - root._prevEnergyUJ;
                var timeDelta = currentTimestamp - root._prevTimestampUSec;
                if (timeDelta > 0) {
                    root.cpuPowerWatts = energyDelta / timeDelta;
                    root._prevEnergyUJ = currentEnergy;
                    root._prevTimestampUSec = currentTimestamp;
                }
            }
        }

        function poll() {
            var cmd = "cat /sys/class/powercap/intel-rapl:0/energy_uj 2>/dev/null || echo -1";
            connectSource(cmd);
        }
    }

    Timer {
        id: cpuPowerTimer
        interval: root.updateInterval
        repeat: true
        running: root.showCpuPower && root._sensorsReady
        onTriggered: cpuPowerSource.poll()
    }

    Component.onCompleted: {
        console.warn("[KVitals] main.qml: ready. config: showCpu=" + showCpu + " showGpu=" + showGpu + " showBattery=" + showBattery + " showNetwork=" + showNetwork + " showDisk=" + showDisk + " showCpuPower=" + showCpuPower);
        sensorActivationTimer.start();
        if (root.showCpuPower) cpuPowerSource.poll();
    }

    // --- Representations ---

    compactRepresentation: CompactView {
        metricsModel: {
            var items = [];
            for (var i = 0; i < root.orderedKeys.length; i++) {
                var key = root.orderedKeys[i];
                if (key === "cpu" && root.showCpu && root.compactShowCpu && cpu.cpuValue) {
                    var cpuSegs = [{value: cpu.cpuValue, color: root.cpuColor}];
                    if (root.mergeCpuFreq && root.showCpuFreq)
                        cpuSegs.push({value: cpu.cpuFreqValue, color: root.baseTextColor});
                    if (root.showCpuPower && root.cpuPowerSupported)
                        cpuSegs.push({value: root.cpuPowerWatts.toFixed(1) + "W", color: root.baseTextColor});
                    if (root.mergeCpuTemp && root.showTemp && root.compactShowTemp && temp.tempValue && temp.tempValue !== "--") {
                        cpuSegs.push({value: temp.tempValue, color: root.tempColor});
                    }
                    if (cpuSegs.length === 1)
                        items.push({icon: root.cpuIcon, label: "CPU:", value: cpu.cpuValue, color: root.cpuColor, iconColor: root.cpuColor});
                    else
                        items.push({icon: root.cpuIcon, label: "CPU:", color: root.cpuColor, segments: cpuSegs, iconColor: root.cpuColor});
                } else if (key === "ram" && root.showRam && root.compactShowRam && memory.ramValue)
                    items.push({
                        icon: root.ramIcon, label: "RAM:", value: memory.ramValue,
                        color: root.ramColor, iconColor: root.ramColor
                    });
                else if (key === "temp" && root.showTemp && root.compactShowTemp && temp.tempValue && temp.tempValue !== "--"
                    && !(root.mergeCpuTemp && root.showCpu && root.compactShowCpu))
                    items.push({
                        icon: root.tempIcon, label: "TEMP:", value: temp.tempValue,
                        color: root.tempColor, iconColor: root.tempColor
                    });
                else if (key === "gpu" && root.showGpu && root.compactShowGpu && gpu.hasGpuData) {
                    var multiGpu = gpu.gpuDataList.length > 1;
                    if (multiGpu) {
                        // Show each GPU as a separate entry
                        for (var g = 0; g < gpu.gpuDataList.length; g++) {
                            var gd = gpu.gpuDataList[g];
                            var label = (gd.name.length > 0 ? gd.name : gd.id) + ":";
                            if (root.splitGpu) {
                                if (gd.usage) items.push({icon: root.gpuIcon, label: label, value: gd.usage, color: root.gpuColor, iconColor: root.gpuColor});
                                if (gd.vram)  items.push({icon: root.gpuIcon, label: "VRAM:", value: gd.vram, color: root.baseTextColor, iconColor: root.gpuColor});
                                if (gd.temp)  items.push({icon: root.gpuIcon, label: "GTEMP:", value: gd.temp, color: root.gpuTempColor, iconColor: root.gpuTempColor});
                            } else {
                                var segs2 = [];
                                if (gd.usage) segs2.push({value: gd.usage, color: root.gpuColor});
                                if (gd.vram)  segs2.push({value: gd.vram,  color: root.baseTextColor});
                                if (gd.temp)  segs2.push({value: gd.temp,  color: root.gpuTempColor});
                                if (segs2.length > 0)
                                    items.push({icon: root.gpuIcon, label: label, segments: segs2, color: root.gpuColor, iconColor: root.gpuColor});
                            }
                        }
                    } else if (root.splitGpu) {
                        if (gpu.hasGpuUsageData)
                            items.push({icon: root.gpuIcon, label: "GPU:", value: gpu.gpuValue, color: root.gpuColor, iconColor: root.gpuColor});
                        if (gpu.hasGpuVramData)
                            items.push({
                                icon: root.gpuIcon,
                                label: "VRAM:",
                                value: gpu.gpuRamValue,
                                color: root.baseTextColor,
                                iconColor: root.gpuColor
                            });
                        if (gpu.hasGpuTempData)
                            items.push({
                                icon: root.gpuIcon,
                                label: "GTEMP:",
                                value: gpu.gpuTempValue,
                                color: root.gpuTempColor,
                                iconColor: root.gpuTempColor
                            });
                    } else {
                        var gpuSegs = [];
                        if (gpu.hasGpuUsageData)
                            gpuSegs.push({value: gpu.gpuValue, color: root.gpuColor});
                        if (gpu.hasGpuVramData)
                            gpuSegs.push({value: gpu.gpuRamValue, color: root.baseTextColor});
                        if (gpu.hasGpuTempData)
                            gpuSegs.push({value: gpu.gpuTempValue, color: root.gpuTempColor});
                        items.push({
                            icon: root.gpuIcon, label: "GPU:", segments: gpuSegs,
                            color: root.gpuColor, iconColor: root.gpuColor
                        });
                    }
                } else if (key === "bat" && root.showBattery && root.compactShowBattery && battery.batValue) {
                    if (root.mergeBatPwr && root.showPower && root.compactShowPower && battery.powerValue) {
                        items.push({
                            icon: root.batteryIcon, label: "BAT:",
                            color: root.batteryColor,
                            segments: [
                                {value: battery.batValue, color: root.batteryColor},
                                {value: battery.powerValue, color: root.baseTextColor}
                            ],
                            iconColor: root.batteryColor
                        });
                    } else {
                        items.push({
                            icon: root.batteryIcon, label: "BAT:", value: battery.batValue,
                            color: root.batteryColor, iconColor: root.batteryColor
                        });
                    }
                } else if (key === "pwr" && root.showPower && root.compactShowPower && battery.powerValue
                    && !(root.mergeBatPwr && root.showBattery && root.compactShowBattery))
                    items.push({
                        icon: root.powerIcon, label: "PWR:", value: battery.powerValue,
                        color: root.baseTextColor, iconColor: root.baseTextColor
                    });
                else if (key === "net" && root.showNetwork && root.compactShowNetwork)
                    items.push({
                        icon: root.networkIcon, label: "NET:",
                        value: "↓" + network.netDownValue + " ↑" + network.netUpValue,
                        color: root.baseTextColor, iconColor: root.baseTextColor
                    });
                else if (key === "disk" && root.showDisk && root.compactShowDisk) {
                    var diskSegs = [];
                    if (disk.diskUsedValue && disk.diskTotalValue && disk.diskUsedValue !== "...")
                        diskSegs.push({value: disk.diskUsedValue + "/" + disk.diskTotalValue, color: root.baseTextColor});
                    diskSegs.push({value: "↓" + disk.diskReadValue, color: root.baseTextColor},
                                  {value: "↑" + disk.diskWriteValue, color: root.baseTextColor});
                    if (disk.diskTempValue)
                        diskSegs.push({value: disk.diskTempValue, color: root.diskTempColor});
                    items.push({icon: root.diskIcon, label: "DSK:", segments: diskSegs, color: root.baseTextColor, iconColor: root.baseTextColor});
                }
                else if (key === "fan" && root.showFan && root.compactShowFan && fans.hasFanData) {
                    items.push({
                        icon: root.fanIcon, label: "FAN:", value: fans.fanValue,
                        color: root.baseTextColor, iconColor: root.baseTextColor
                    });
                }
            }
            // Fallback: if nothing is shown in compact, show first available metric so widget isn't invisible
            if (items.length === 0) {
                for (var f = 0; f < root.orderedKeys.length; f++) {
                    var fkey = root.orderedKeys[f];
                    var kv = {icon: root.cpuIcon, label: "KV:", value: "...",
                              color: root.baseTextColor, iconColor: root.baseTextColor};
                    if (fkey === "cpu" && cpu.cpuValue)        { kv.value = cpu.cpuValue; kv.icon = root.cpuIcon; break; }
                    if (fkey === "ram" && memory.ramValue)      { kv.value = memory.ramValue; kv.icon = root.ramIcon; break; }
                    if (fkey === "temp" && temp.tempValue !== "--") { kv.value = temp.tempValue; kv.icon = root.tempIcon; break; }
                    if (fkey === "bat" && battery.batValue)    { kv.value = battery.batValue; kv.icon = root.batteryIcon; break; }
                    if (fkey === "gpu" && gpu.hasGpuData)     { kv.value = gpu.gpuValue; kv.icon = root.gpuIcon; break; }
                }
                items.push(kv);
            }
            return items;
        }
        layoutType: root.layoutType
        useIcons: root.useIcons
        useText: root.useText
        effectiveFontSize: root.effectiveFontSize
        fontFamily: root.fontFamily
        fontBold: root.fontBold
        iconSize: root.iconSize
        baseTextColor: root.baseTextColor
        compactSpacing: root.compactSpacing
        onToggleExpanded: root.expanded = !root.expanded
    }

    fullRepresentation: FullView {
        baseTextColor: root.baseTextColor
        fontBold: root.fontBold
        metricsModel: {
            var items = [];
            for (var i = 0; i < root.orderedKeys.length; i++) {
                var key = root.orderedKeys[i];
                if (key === "cpu" && root.showCpu)
                    items.push({
                        label: "CPU Usage", value: cpu.cpuValue,
                        color: root.cpuColor
                    });
                if (key === "cpu" && root.showCpu && root.showCpuFreq)
                    items.push({
                        label: "CPU Frequency", value: cpu.cpuFreqValue,
                        color: root.baseTextColor
                    });
                if (key === "cpu" && root.showCpuPower && root.cpuPowerSupported)
                    items.push({
                        label: "CPU Power", value: root.cpuPowerWatts.toFixed(1) + "W",
                        color: root.baseTextColor
                    });
                else if (key === "ram" && root.showRam)
                    items.push({
                        label: "Memory", value: memory.ramValue,
                        color: root.ramColor
                    });
                else if (key === "temp" && root.showTemp && temp.tempValue !== "--")
                    items.push({
                        label: "CPU Temp", value: temp.tempValue,
                        color: root.tempColor
                    });
                else if (key === "gpu" && root.showGpu) {
                    if (gpu.gpuDataList.length > 1) {
                        for (var g = 0; g < gpu.gpuDataList.length; g++) {
                            var gd = gpu.gpuDataList[g];
                            var label = gd.name || gd.id;
                            if (gd.usage) items.push({label: label + " Usage", value: gd.usage, color: root.gpuColor});
                            if (gd.vram)  items.push({label: label + " VRAM",  value: gd.vram,  color: root.baseTextColor});
                            if (gd.temp)  items.push({label: label + " Temp",  value: gd.temp,  color: root.gpuTempColor});
                        }
                    } else {
                        if (gpu.hasGpuUsageData) items.push({
                            label: "GPU Usage", value: gpu.gpuValue,
                            color: root.gpuColor
                        });
                        if (gpu.hasGpuVramData) items.push({
                            label: "GPU VRAM", value: gpu.gpuRamValue,
                            color: root.baseTextColor
                        });
                        if (gpu.hasGpuTempData) items.push({
                            label: "GPU Temp", value: gpu.gpuTempValue,
                            color: root.gpuTempColor
                        });
                    }
                } else if (key === "bat" && root.showBattery && battery.batValue)
                    items.push({
                        label: "Battery", value: battery.batValue,
                        color: root.batteryColor
                    });
                else if (key === "pwr" && root.showPower && battery.powerValue)
                    items.push({
                        label: "Power", value: battery.powerValue,
                        color: root.baseTextColor
                    });
                else if (key === "net" && root.showNetwork) {
                    items.push({label: "Network ↓", value: network.netDownValue, color: root.baseTextColor});
                    items.push({label: "Network ↑", value: network.netUpValue, color: root.baseTextColor});
                }
                else if (key === "disk" && root.showDisk) {
                    if (disk.diskUsedValue && disk.diskTotalValue && disk.diskUsedValue !== "...")
                        items.push({label: "Disk Usage", value: disk.diskUsedValue + "/" + disk.diskTotalValue, color: root.baseTextColor});
                    items.push({label: "Disk Read",  value: disk.diskReadValue,  color: root.baseTextColor});
                    items.push({label: "Disk Write", value: disk.diskWriteValue, color: root.baseTextColor});
                    if (disk.diskTempValue)
                        items.push({label: "Disk Temp", value: disk.diskTempValue, color: root.diskTempColor});
                }
                else if (key === "fan" && root.showFan && fans.hasFanData) {
                    items.push({label: "Fans", value: fans.fanValue, color: root.baseTextColor});
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
            if (key === "cpu" && root.showCpu && cpu.cpuValue) {
                var cpuParts = [cpu.cpuValue];
                if (root.showCpuPower && root.cpuPowerSupported)
                    cpuParts.push(root.cpuPowerWatts.toFixed(1) + "W");
                parts.push("CPU: " + cpuParts.join(" "));
            }
            else if (key === "ram" && root.showRam && memory.ramValue)
                parts.push("RAM: " + memory.ramValue);
            else if (key === "temp" && root.showTemp && temp.tempValue && temp.tempValue !== "--")
                parts.push("TEMP: " + temp.tempValue);
            else if (key === "gpu" && root.showGpu && gpu.hasGpuData) {
                if (gpu.gpuDataList.length > 1) {
                    for (var g = 0; g < gpu.gpuDataList.length; g++) {
                        var gd = gpu.gpuDataList[g];
                        var label = gd.name || gd.id;
                        var vals = [gd.usage, gd.vram, gd.temp].filter(function(v) { return v; });
                        if (vals.length > 0) parts.push(label + ": " + vals.join(" "));
                    }
                } else {
                    if (gpu.hasGpuUsageData) parts.push("GPU: " + gpu.gpuValue);
                    if (gpu.hasGpuVramData) parts.push("VRAM: " + gpu.gpuRamValue);
                    if (gpu.hasGpuTempData) parts.push("GPU TEMP: " + gpu.gpuTempValue);
                }
            } else if (key === "bat" && root.showBattery && battery.batValue)
                parts.push("BAT: " + battery.batValue);
            else if (key === "pwr" && root.showPower && battery.powerValue)
                parts.push("PWR: " + battery.powerValue);
            else if (key === "net" && root.showNetwork)
                parts.push("NET: ↓" + network.netDownValue + " ↑" + network.netUpValue);
            else if (key === "disk" && root.showDisk) {
                var dParts = [];
                if (disk.diskUsedValue && disk.diskTotalValue && disk.diskUsedValue !== "...")
                    dParts.push(disk.diskUsedValue + "/" + disk.diskTotalValue);
                dParts.push("↓" + disk.diskReadValue, "↑" + disk.diskWriteValue);
                if (disk.diskTempValue) dParts.push(disk.diskTempValue);
                parts.push("DSK: " + dParts.join(" "));
            }
            else if (key === "fan" && root.showFan && fans.hasFanData) {
                parts.push("FAN: " + fans.fanValue);
            }
        }
        return parts.join("\n");
    }
}
