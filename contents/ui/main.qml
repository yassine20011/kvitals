import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "./sensors"

PlasmoidItem {
    id: root
    property bool _dbg: { console.warn("[KVitals] main.qml: constructing..."); return true; }

    preferredRepresentation: compactRepresentation

    property bool pinned: false
    hideOnWindowDeactivate: !pinned

    // These names only exist in third-party icon themes (e.g. Win11/Win11-dark)
    // some users have installed; on Breeze or any other theme they resolve to
    // nothing and the icon silently disappears. Fall back to the package's own
    // bundled copy so the default look never depends on the active icon theme.
    function resolveIcon(name) {
        switch (name) {
        case "am-cpu-symbolic":
        case "nvidia-ram-symbolic":
        case "am-disk-utility-symbolic":
        case "am-fan-symbolic":
        case "gpu-symbolic":
            return Qt.resolvedUrl("../icons/" + name + ".svg");
        default:
            return name;
        }
    }

    // --- Configuration properties ---

    property bool cpuEnabled:  Plasmoid.configuration.cpuEnabled
    property string cpuSubMetrics:  Plasmoid.configuration.cpuSubMetrics  || "usage,freq,temp"
    property string cpuLabel:       Plasmoid.configuration.cpuLabel       || "CPU"

    property bool ramEnabled:       Plasmoid.configuration.ramEnabled
    property string ramSubMetrics:  Plasmoid.configuration.ramSubMetrics  || "percentage"
    property string ramLabel:       Plasmoid.configuration.ramLabel       || "RAM"
    // Popup-only override: show both Percentage and Used/Total in the widget
    // window regardless of which one is toggled for the compact panel.
    property bool ramWidgetShowBoth: Plasmoid.configuration.ramWidgetShowBoth

    property bool tempEnabled:      Plasmoid.configuration.tempEnabled
    property string tempLabel:      Plasmoid.configuration.tempLabel || "System"

    property bool gpuEnabled:      Plasmoid.configuration.gpuEnabled
    property string gpuMetrics:    Plasmoid.configuration.gpuMetrics || ""
    property string gpuSelection:  Plasmoid.configuration.gpuSelection  || ""
    property string gpuLabels:     Plasmoid.configuration.gpuLabels     || ""

    property bool batEnabled:      Plasmoid.configuration.batEnabled
    property string batSubMetrics: Plasmoid.configuration.batSubMetrics || "percentage,power"

    property bool netEnabled:      Plasmoid.configuration.netEnabled
    property string netSubMetrics: Plasmoid.configuration.netSubMetrics || "down,up"
    property string netLabel:       Plasmoid.configuration.netLabel     || "NET"
    property string networkInterface: Plasmoid.configuration.networkInterface
    property bool showNetworkIp:   Plasmoid.configuration.showNetworkIp

    property bool diskEnabled:     Plasmoid.configuration.diskEnabled
    property string diskSubMetrics: Plasmoid.configuration.diskSubMetrics || "read,write"
    property string diskLabel:      Plasmoid.configuration.diskLabel      || "DSK"
    property string diskLabels:     Plasmoid.configuration.diskLabels     || ""

    property bool fanEnabled:    Plasmoid.configuration.fanEnabled
    property bool uptimeEnabled: Plasmoid.configuration.uptimeEnabled

    property string batteryDevice: Plasmoid.configuration.batteryDevice || "auto"

    property string displayMode: Plasmoid.configuration.displayMode
    property string layoutType:  Plasmoid.configuration.layoutType
    property int iconSize:       Plasmoid.configuration.iconSize
    property string cpuIcon:     resolveIcon(Plasmoid.configuration.cpuIcon)
    property string ramIcon:     resolveIcon(Plasmoid.configuration.ramIcon)
    property string tempIcon:    Plasmoid.configuration.tempIcon
    property string gpuIcon:     resolveIcon(Plasmoid.configuration.gpuIcon)
    property string batteryIcon: Plasmoid.configuration.batteryIcon
    property string powerIcon:   Plasmoid.configuration.powerIcon
    property string networkIcon: Plasmoid.configuration.networkIcon
    property string diskIcon:    resolveIcon(Plasmoid.configuration.diskIcon)
    property string fanIcon:     resolveIcon(Plasmoid.configuration.fanIcon)
    property string uptimeIcon:  Plasmoid.configuration.uptimeIcon
    property string fontFamily: Plasmoid.configuration.fontFamily
    property int fontSize:      Plasmoid.configuration.fontSize
    property bool fontBold:     Plasmoid.configuration.fontBold
    property real labelOpacity:    Plasmoid.configuration.labelOpacity
    property real separatorOpacity: Plasmoid.configuration.separatorOpacity
    property int effectiveFontSize: fontSize > 0 ? fontSize : Kirigami.Theme.smallFont.pixelSize

    property bool useIcons: displayMode === "icons" || displayMode === "icons+text"
    property bool useText:  displayMode === "text"  || displayMode === "icons+text"

    property string metricOrder: Plasmoid.configuration.metricOrder || "cpu,ram,temp,gpu,bat,net,disk,fan,uptime"
    property var allKeys: ["cpu", "ram", "temp", "gpu", "bat", "net", "disk", "fan", "uptime"]
    property var orderedKeys: {
        var keys = metricOrder.split(",").map(function (k) { return k.trim(); }).filter(function(k) { return k.length > 0 && allKeys.indexOf(k) >= 0; });
        for (var i = 0; i < allKeys.length; i++) {
            if (keys.indexOf(allKeys[i]) === -1) keys.push(allKeys[i]);
        }
        return keys;
    }

    property int updateInterval: Plasmoid.configuration.updateInterval || 2000
    property string tempUnit:    Plasmoid.configuration.tempUnit    || "C"
    property string networkUnit: Plasmoid.configuration.networkUnit || "bytes"
    property string fanUnit:     Plasmoid.configuration.fanUnit     || "rpm"

    // --- Per-metric visibility ---

    property string cpuVisibility:    Plasmoid.configuration.cpuVisibility    || "both"
    property string ramVisibility:    Plasmoid.configuration.ramVisibility    || "both"
    property string tempVisibility:   Plasmoid.configuration.tempVisibility   || "both"
    property string gpuVisibility:    Plasmoid.configuration.gpuVisibility    || "both"
    property string batVisibility:    Plasmoid.configuration.batVisibility    || "both"
    property string netVisibility:    Plasmoid.configuration.netVisibility    || "both"
    property string diskVisibility:   Plasmoid.configuration.diskVisibility   || "both"
    property string fanVisibility:    Plasmoid.configuration.fanVisibility    || "both"
    property string uptimeVisibility: Plasmoid.configuration.uptimeVisibility || "both"

    function isShownIn(key, view) {
        var v = this[key + "Visibility"] || "both";
        return v === "both" || v === view;
    }

    // --- Helpers ---

    function subs(key) {
        switch (key) {
            case "cpu":  return cpuSubMetrics;
            case "ram":  return ramSubMetrics;
            case "bat":  return batSubMetrics;
            case "net":  return netSubMetrics;
            case "disk": return diskSubMetrics;
            default:     return "";
        }
    }

    function hasSub(key, sub) {
        return subs(key).split(",").indexOf(sub) >= 0;
    }

    function isEnabled(key) {
        switch (key) {
            case "cpu":    return cpuEnabled   && cpu.cpuValue;
            case "ram":    return ramEnabled   && memory.ramValue;
            case "temp":   return tempEnabled && temp.tempValue && temp.tempValue !== "--";
            case "gpu":    return gpuEnabled   && gpu.hasGpuData;
            case "bat":    return batEnabled   && battery.batValue;
            case "net":    return netEnabled;
            case "disk":   return diskEnabled;
            case "fan":    return fanEnabled   && fans.hasFanData;
            case "uptime": return uptimeEnabled && uptime.uptimeValue;
        }
        return false;
    }

    // --- Color configuration properties ---

    property bool useCustomColors: Plasmoid.configuration.useCustomColors
    property string fontColor: Plasmoid.configuration.fontColor
    property string labelColor: Plasmoid.configuration.labelColor || ""
    property color resolvedLabelColor: (useCustomColors && labelColor) ? labelColor : baseTextColor
    property string iconColor: Plasmoid.configuration.iconColor || ""
    property color resolvedIconColor: (useCustomColors && iconColor) ? iconColor : resolvedLabelColor
    property bool enableThresholdColors: Plasmoid.configuration.enableThresholdColors
    property string warningColor: Plasmoid.configuration.warningColor || "#e5a50a"
    property string criticalColor: Plasmoid.configuration.criticalColor || "#da4453"

    property int cpuWarningThreshold: Plasmoid.configuration.cpuWarningThreshold
    property int cpuCriticalThreshold: Plasmoid.configuration.cpuCriticalThreshold
    property int tempWarningThreshold: Plasmoid.configuration.tempWarningThreshold
    property int tempCriticalThreshold: Plasmoid.configuration.tempCriticalThreshold
    property int systemWarningThreshold: Plasmoid.configuration.systemWarningThreshold
    property int systemCriticalThreshold: Plasmoid.configuration.systemCriticalThreshold
    property int ramWarningThreshold: Plasmoid.configuration.ramWarningThreshold
    property int ramCriticalThreshold: Plasmoid.configuration.ramCriticalThreshold
    property int ramTempWarningThreshold: Plasmoid.configuration.ramTempWarningThreshold
    property int ramTempCriticalThreshold: Plasmoid.configuration.ramTempCriticalThreshold
    property int gpuWarningThreshold: Plasmoid.configuration.gpuWarningThreshold
    property int gpuCriticalThreshold: Plasmoid.configuration.gpuCriticalThreshold
    property int gpuTempWarningThreshold: Plasmoid.configuration.gpuTempWarningThreshold
    property int gpuTempCriticalThreshold: Plasmoid.configuration.gpuTempCriticalThreshold
    property int batteryWarningThreshold: Plasmoid.configuration.batteryWarningThreshold
    property int batteryCriticalThreshold: Plasmoid.configuration.batteryCriticalThreshold
    property int diskTempWarningThreshold: Plasmoid.configuration.diskTempWarningThreshold
    property int diskTempCriticalThreshold: Plasmoid.configuration.diskTempCriticalThreshold

    property color baseTextColor: (useCustomColors && fontColor !== "") ? fontColor : Kirigami.Theme.textColor

    // --- Pre-resolved per-metric colors ---

    property color cpuColor: enableThresholdColors
        ? Utils.resolveColor(cpu.cpuNumericValue, cpuWarningThreshold, cpuCriticalThreshold,
            warningColor, criticalColor, baseTextColor, false)
        : baseTextColor

    property color cpuTempColor: enableThresholdColors
        ? Utils.resolveColor(temp.cpuTempNumericValue, tempWarningThreshold, tempCriticalThreshold,
            warningColor, criticalColor, baseTextColor, false)
        : baseTextColor

    property color ramTempColor: enableThresholdColors
        ? Utils.resolveColor(temp.ramTempNumericValue, ramTempWarningThreshold, ramTempCriticalThreshold,
            warningColor, criticalColor, baseTextColor, false)
        : baseTextColor

    property color systemColor: enableThresholdColors
        ? Utils.resolveColor(temp.tempNumericValue, systemWarningThreshold, systemCriticalThreshold,
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

    property bool _sensorsReady: sensorLoader.status === Loader.Ready
    property var cpu:     _sensorsReady ? sensorLoader.item.cpu     : _nullCpu
    property var memory:  _sensorsReady ? sensorLoader.item.memory  : _nullMemory
    property var temp:    _sensorsReady ? sensorLoader.item.temp    : _nullTemp
    property var gpu:     _sensorsReady ? sensorLoader.item.gpu     : _nullGpu
    property var battery: _sensorsReady ? sensorLoader.item.battery : _nullBattery
    property var network: _sensorsReady ? sensorLoader.item.network : _nullNetwork
    property var disk:    _sensorsReady ? sensorLoader.item.disk    : _nullDisk
    property var fans:    _sensorsReady ? sensorLoader.item.fans    : _nullFans
    property var uptime:  _sensorsReady ? sensorLoader.item.uptime  : _nullUptime

    // --- Chart history ---

    property var chartHistory: ({cpu: [], ram: [], temp: [], cpuTemp: [], ramTemp: [], diskTemp: [], netDown: [], netUp: [], bat: []})
    property int maxChartPoints: 60
    property int chartVersion: 0

    Timer {
        id: chartTimer
        interval: root.updateInterval
        repeat: true
        running: root._sensorsReady
        onTriggered: {
            var h = root.chartHistory;
            var changed = false;

            var push = function(arr, val) {
                if (typeof val === "number" && !isNaN(val) && val >= 0) {
                    arr.push(val);
                    if (arr.length > root.maxChartPoints) arr.shift();
                    return true;
                }
                return false;
            };

            if (push(h.cpu, root.cpu.cpuNumericValue)) changed = true;
            if (push(h.ram, root.memory.ramPercentage)) changed = true;
            if (push(h.temp, root.temp.tempNumericValue)) changed = true;
            if (push(h.cpuTemp, root.temp.cpuTempNumericValue)) changed = true;
            if (push(h.ramTemp, root.temp.ramTempNumericValue)) changed = true;
            if (push(h.diskTemp, root.disk.diskTempNumber)) changed = true;
            if (push(h.netDown, root.network.netDownRaw)) changed = true;
            if (push(h.netUp, root.network.netUpRaw)) changed = true;
            if (push(h.bat, root.battery.batNumericValue)) changed = true;

            var gl = root.gpu.gpuDataList;
            for (var i = 0; i < gl.length; i++) {
                var uKey = "gpu:" + gl[i].id;
                var tKey = "gpuTemp:" + gl[i].id;
                if (!h[uKey]) h[uKey] = [];
                if (!h[tKey]) h[tKey] = [];
                if (push(h[uKey], gl[i].usageNumber)) changed = true;
                if (push(h[tKey], gl[i].tempNumber)) changed = true;
            }

            if (changed) root.chartVersion++;
        }
    }

    // Safe defaults
    QtObject {
        id: _nullCpu
        property string cpuValue: ""
        property string cpuFreqValue: ""
        property real cpuNumericValue: NaN
    }
    QtObject {
        id: _nullMemory
        property string ramValue: ""
        property string ramPercentValue: "..."
        property real ramPercentage: NaN
    }
    QtObject {
        id: _nullTemp
        property string tempValue: "--"
        property string cpuTempValue: "--"
        property real tempNumericValue: NaN
        property bool sysIsFallback: false
        property string ramTempValue: "--"
        property real ramTempNumericValue: NaN
        property bool ramTempExists: false
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
        property string netIpValue: ""
    }
    QtObject {
        id: _nullDisk
        property string diskReadValue: "0"
        property string diskWriteValue: "0"
        property string diskTempValue: ""
        property real diskTempNumber: NaN
        property bool multiDisk: false
        property var diskDataList: []
    }
    QtObject {
        id: _nullFans
        property string fanValue: ""
        property bool hasFanData: false
    }
    QtObject {
        id: _nullUptime
        property string uptimeValue: ""
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
            property alias uptime:  _uptime

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
                gpuMetrics: root.gpuMetrics
                gpuSelection: root.gpuSelection
                gpuLabels: root.gpuLabels
                tempUnit: root.tempUnit
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
                enabled: root.diskEnabled
                tempUnit: root.tempUnit
                networkUnit: root.networkUnit
                diskLabels: root.diskLabels
            }

            FanSensors {
                id: _fans
                updateInterval: root.updateInterval
                fanUnit: root.fanUnit
            }

            UptimeSensors {
                id: _uptime
                updateInterval: root.updateInterval
            }
        }
    }

    Timer {
        id: sensorActivationTimer
        interval: 0
        repeat: false
        onTriggered: {
            console.warn("[KVitals] main.qml: deferred load — activating sensors...");
            sensorLoader.active = true;
        }
    }

    Binding {
        target: Plasmoid.configuration
        property: "_tempFallbackActive"
        value: temp.sysIsFallback
        when: _sensorsReady
    }

    Binding {
        target: Plasmoid.configuration
        property: "_ramTempDetected"
        value: temp.ramTempExists
        when: _sensorsReady
    }

    Component.onCompleted: {
        console.warn("[KVitals] main.qml: ready.");
        sensorActivationTimer.start();
    }

    // === Compact model helper: build segments from sub-metrics ===

    function _compactSegments(key, subsList, colorMap) {
        var segs = [];
        for (var si = 0; si < subsList.length; si++) {
            var s = subsList[si];
            var val = _compactSubValue(key, s);
            if (val === null) continue;
            segs.push({value: val, color: colorMap[s] || root.baseTextColor});
        }
        return segs.length > 0 ? segs : null;
    }

    function _compactSubValue(key, sub) {
        switch (key) {
            case "cpu":
                if (sub === "usage") return cpu.cpuValue;
                if (sub === "freq")  return cpu.cpuFreqValue;
                if (sub === "temp")  return temp.cpuTempValue !== "--" ? temp.cpuTempValue : null;
                break;
            case "ram":
                if (sub === "percentage") return memory.ramPercentValue;
                if (sub === "used") return memory.ramValue;
                if (sub === "temp") return temp.ramTempValue !== "--" ? temp.ramTempValue : null;
                break;
            case "gpu":
                if (sub === "usage") return gpu.gpuValue;
                if (sub === "vram")  return gpu.gpuRamValue;
                if (sub === "temp")  return gpu.gpuTempValue;
                break;
            case "bat":
                if (sub === "percentage") return battery.batValue;
                if (sub === "power")      return battery.powerValue;
                break;
            case "net":
                if (sub === "down") return "↓" + network.netDownValue;
                if (sub === "up")   return "↑" + network.netUpValue;
                if (sub === "ip" && showNetworkIp && network.netIpValue && network.netIpValue !== "..." && network.netIpValue !== "")
                    return network.netIpValue;
                break;
            case "disk":
                if (sub === "read")  return "↓" + disk.diskReadValue;
                if (sub === "write") return "↑" + disk.diskWriteValue;
                if (sub === "temp" && disk.diskTempValue) return disk.diskTempValue;
                break;
        }
        return null;
    }

    // --- Representations ---

    compactRepresentation: CompactView {
        metricsModel: {
            var items = [];
            for (var i = 0; i < root.orderedKeys.length; i++) {
                var key = root.orderedKeys[i];
                if (!root.isEnabled(key)) continue;
                if (!root.isShownIn(key, "compact")) continue;

                var sm = root.subs(key).split(",").filter(function(s){ return s.length > 0; });
                var colorMap = {
                    "usage": root.cpuColor, "freq": root.baseTextColor,
                    "temp": root.tempColor, "percentage": root.ramColor,
                    "used": root.baseTextColor, "vram": root.baseTextColor,
                    "power": root.baseTextColor, "down": root.baseTextColor,
                    "up": root.baseTextColor, "ip": root.baseTextColor,
                    "read": root.baseTextColor, "write": root.baseTextColor
                };

                if (key === "cpu") {
                    var cpuMap = Object.assign({}, colorMap, {"temp": root.cpuTempColor});
                    var segs = root._compactSegments("cpu", sm, cpuMap);
                    if (segs) items.push({
                        icon: root.cpuIcon, label: root.cpuLabel + ":",
                        segments: segs, color: root.cpuColor
                    });
                }
                else if (key === "ram") {
                    if (sm.length === 1 && sm[0] === "percentage")
                        items.push({icon: root.ramIcon, label: root.ramLabel + ":", value: memory.ramPercentValue, color: root.ramColor});
                    else if (sm.length === 1 && sm[0] === "used")
                        items.push({icon: root.ramIcon, label: root.ramLabel + ":", value: memory.ramValue, color: root.baseTextColor});
                    else {
                        var ramMap = Object.assign({}, colorMap, {"temp": root.ramTempColor});
                        var rsegs = root._compactSegments("ram", sm, ramMap);
                        if (rsegs) items.push({icon: root.ramIcon, label: root.ramLabel + ":", segments: rsegs, color: root.ramColor});
                    }
                }
                else if (key === "temp") {
                    if (temp.tempValue && temp.tempValue !== "--")
                        items.push({icon: root.tempIcon, label: root.tempLabel + ":", value: temp.tempValue, color: root.systemColor});
                }
                else if (key === "gpu") {
                    if (gpu.gpuDataList.length > 1) {
                        for (var g = 0; g < gpu.gpuDataList.length; g++) {
                            var gd = gpu.gpuDataList[g];
                            var gsegs = [];
                            if (gd.usage) gsegs.push({value: gd.usage, color: root.gpuColor});
                            if (gd.vram)  gsegs.push({value: gd.vram, color: root.baseTextColor});
                            if (gd.temp)  gsegs.push({value: gd.temp, color: root.gpuTempColor});
                            if (gsegs.length > 0)
                                items.push({icon: root.gpuIcon, label: (gd.name || gd.id) + ":", segments: gsegs, color: root.gpuColor});
                        }
                    } else {
                        var gsegs2 = [];
                        if (gpu.hasGpuUsageData) gsegs2.push({value: gpu.gpuValue, color: root.gpuColor});
                        if (gpu.hasGpuVramData)  gsegs2.push({value: gpu.gpuRamValue, color: root.baseTextColor});
                        if (gpu.hasGpuTempData)  gsegs2.push({value: gpu.gpuTempValue, color: root.gpuTempColor});
                        var gpuLabel = gpu.gpuDataList.length > 0 && gpu.gpuDataList[0].name
                            ? gpu.gpuDataList[0].name + ":"
                            : "GPU:";
                        if (gsegs2.length > 0) items.push({icon: root.gpuIcon, label: gpuLabel, segments: gsegs2, color: root.gpuColor});
                    }
                }
                else if (key === "bat") {
                    if (sm.length === 1 && sm[0] === "percentage")
                        items.push({icon: root.batteryIcon, label: "BAT:", value: battery.batValue, color: root.batteryColor});
                    else if (sm.length === 1 && sm[0] === "power")
                        items.push({icon: root.powerIcon, label: "PWR:", value: battery.powerValue, color: root.baseTextColor});
                    else {
                        var bsegs = root._compactSegments("bat", sm, colorMap);
                        if (bsegs) items.push({
                            icon: root.batteryIcon, label: "BAT:", segments: bsegs,
                            color: root.batteryColor
                        });
                    }
                }
                else if (key === "net") {
                    var nsegs = root._compactSegments("net", sm, colorMap);
                    if (nsegs) items.push({
                        icon: root.networkIcon, label: root.netLabel + ":",
                        segments: nsegs, color: root.baseTextColor
                    });
                }
                else if (key === "disk") {
                    var dsegs = root._compactSegments("disk", sm, colorMap);
                    if (dsegs) items.push({
                        icon: root.diskIcon, label: root.diskLabel + ":",
                        segments: dsegs, color: root.baseTextColor
                    });
                }
                else if (key === "fan")
                    items.push({icon: root.fanIcon, label: "FAN:", value: fans.fanValue, color: root.baseTextColor});
                else if (key === "uptime")
                    items.push({icon: root.uptimeIcon, label: "UPTIME:", value: uptime.uptimeValue, color: root.baseTextColor});
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
        labelColor: root.resolvedLabelColor
        iconColor: root.resolvedIconColor
        labelOpacity: root.labelOpacity
        separatorOpacity: root.separatorOpacity
        onToggleExpanded: root.expanded = !root.expanded
    }

    fullRepresentation: FullView {
        baseTextColor: root.baseTextColor
        labelColor: root.resolvedLabelColor
        iconColor: root.resolvedIconColor
        fontBold: root.fontBold
        chartHistory: root.chartHistory
        chartVersion: root.chartVersion
        pinned: root.pinned
        onTogglePinned: root.pinned = !root.pinned
        metricsModel: {
            var items = [];
            for (var i = 0; i < root.orderedKeys.length; i++) {
                var key = root.orderedKeys[i];
                if (!root.isShownIn(key, "widget")) continue;

                var addMetric = function(label, value, color, icon, chartKey, chartMax) {
                    items.push({
                        label: label, value: value, color: color,
                        icon: icon || "", chartKey: chartKey || "",
                        chartMax: chartMax || 0
                    });
                };

                if (key === "cpu" && root.cpuEnabled && cpu.cpuValue) {
                    if (root.hasSub("cpu", "usage"))
                        addMetric(root.cpuLabel + " Usage", cpu.cpuValue, root.cpuColor, root.cpuIcon, "cpu", 100);
                    if (root.hasSub("cpu", "freq") && cpu.cpuFreqValue)
                        addMetric(root.cpuLabel + " Frequency", cpu.cpuFreqValue, root.baseTextColor, root.cpuIcon);
                    if (root.hasSub("cpu", "temp") && temp.cpuTempValue !== "--")
                        addMetric(root.cpuLabel + " Temperature", temp.cpuTempValue, root.cpuTempColor, [root.cpuIcon, root.tempIcon], "cpuTemp", 100);
                }
                else if (key === "ram" && root.ramEnabled) {
                    if ((root.ramWidgetShowBoth || root.hasSub("ram", "percentage")) && memory.ramPercentValue !== "...")
                        addMetric(root.ramLabel, memory.ramPercentValue, root.ramColor, root.ramIcon, "ram", 100);
                    if ((root.ramWidgetShowBoth || root.hasSub("ram", "used")) && memory.ramValue !== "...")
                        addMetric(root.ramLabel + " Usage", memory.ramValue, root.baseTextColor, root.ramIcon);
                    if (root.hasSub("ram", "temp") && temp.ramTempValue !== "--")
                        addMetric(root.ramLabel + " Temperature", temp.ramTempValue, root.ramTempColor, [root.ramIcon, root.tempIcon], "ramTemp", 100);
                }
                else if (key === "temp" && root.tempEnabled && temp.tempValue !== "--")
                    addMetric(root.tempLabel, temp.tempValue, root.systemColor, root.tempIcon, "temp", 100);
                else if (key === "gpu" && root.gpuEnabled) {
                    if (gpu.gpuDataList.length > 1) {
                        for (var g = 0; g < gpu.gpuDataList.length; g++) {
                            var gd = gpu.gpuDataList[g];
                            var label = gd.name || gd.id;
                            if (gd.usage)
                                addMetric(label + " Usage", gd.usage, root.gpuColor, root.gpuIcon, "gpu:" + gd.id, 100);
                            if (gd.vram)
                                addMetric(label + " VRAM", gd.vram, root.baseTextColor, root.gpuIcon);
                            if (gd.temp)
                                addMetric(label + " Temperature", gd.temp, root.gpuTempColor, [root.gpuIcon, root.tempIcon], "gpuTemp:" + gd.id, 100);
                        }
                    } else {
                        var _gpuName = gpu.gpuDataList.length > 0 ? gpu.gpuDataList[0].name : "GPU";
                        if (gpu.hasGpuUsageData)
                            addMetric(_gpuName + " Usage", gpu.gpuValue, root.gpuColor, root.gpuIcon,
                                gpu.gpuDataList.length > 0 ? "gpu:" + gpu.gpuDataList[0].id : "", 100);
                        if (gpu.hasGpuVramData)
                            addMetric(_gpuName + " VRAM", gpu.gpuRamValue, root.baseTextColor, root.gpuIcon);
                        if (gpu.hasGpuTempData)
                            addMetric(_gpuName + " Temperature", gpu.gpuTempValue, root.gpuTempColor,
                                [root.gpuIcon, root.tempIcon],
                                gpu.gpuDataList.length > 0 ? "gpuTemp:" + gpu.gpuDataList[0].id : "", 100);
                    }
                }
                else if (key === "bat" && root.batEnabled && battery.batValue) {
                    if (root.hasSub("bat", "percentage"))
                        addMetric("Battery", battery.batValue, root.batteryColor, root.batteryIcon, "bat", 100);
                    if (root.hasSub("bat", "power") && battery.powerValue)
                        addMetric("Power", battery.powerValue, root.baseTextColor, root.powerIcon);
                }
                else if (key === "net" && root.netEnabled) {
                    if (root.hasSub("net", "down"))
                        addMetric(root.netLabel + " ↓", network.netDownValue, root.baseTextColor, root.networkIcon, "netDown");
                    if (root.hasSub("net", "up"))
                        addMetric(root.netLabel + " ↑", network.netUpValue, root.baseTextColor, root.networkIcon, "netUp");
                    if (root.hasSub("net", "ip") && root.showNetworkIp && network.netIpValue && network.netIpValue !== "..." && network.netIpValue !== "")
                        addMetric("Local IP", network.netIpValue, root.baseTextColor, root.networkIcon);
                }
                else if (key === "disk" && root.diskEnabled) {
                    if (disk.multiDisk) {
                        for (var dk = 0; dk < disk.diskDataList.length; dk++) {
                            var dd = disk.diskDataList[dk];
                            var dkLabel = dd.name || dd.id;
                            if (root.hasSub("disk", "read") && root.hasSub("disk", "write"))
                                addMetric(dkLabel, "↓" + dd.read + " ↑" + dd.write, root.baseTextColor, root.diskIcon);
                            else if (root.hasSub("disk", "read"))
                                addMetric(dkLabel + " ↓", dd.read, root.baseTextColor, root.diskIcon);
                            else if (root.hasSub("disk", "write"))
                                addMetric(dkLabel + " ↑", dd.write, root.baseTextColor, root.diskIcon);
                        }
                        if (root.hasSub("disk", "temp") && disk.diskTempValue)
                            addMetric("Disk Temperature", disk.diskTempValue, root.diskTempColor, [root.diskIcon, root.tempIcon], "diskTemp", 100);
                    } else {
                        if (root.hasSub("disk", "read") && root.hasSub("disk", "write"))
                            addMetric(root.diskLabel, "↓" + disk.diskReadValue + " ↑" + disk.diskWriteValue, root.baseTextColor, root.diskIcon);
                        else if (root.hasSub("disk", "read"))
                            addMetric(root.diskLabel + " ↓", disk.diskReadValue, root.baseTextColor, root.diskIcon);
                        else if (root.hasSub("disk", "write"))
                            addMetric(root.diskLabel + " ↑", disk.diskWriteValue, root.baseTextColor, root.diskIcon);
                        if (root.hasSub("disk", "temp") && disk.diskTempValue)
                            addMetric(root.diskLabel + " Temperature", disk.diskTempValue, root.diskTempColor, [root.diskIcon, root.tempIcon], "diskTemp", 100);
                    }
                }
                else if (key === "fan" && root.fanEnabled && fans.hasFanData)
                    addMetric("Fans", fans.fanValue, root.baseTextColor, root.fanIcon);
                else if (key === "uptime" && root.uptimeEnabled && uptime.uptimeValue)
                    addMetric("System Uptime", uptime.uptimeValue, root.baseTextColor, root.uptimeIcon);
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
            if (!root.isEnabled(key)) continue;
            if (!root.isShownIn(key, "compact")) continue;

            if (key === "cpu") {
                var cpuLine = root.cpuLabel + ": " + cpu.cpuValue;
                if (root.hasSub("cpu", "temp") && temp.cpuTempValue && temp.cpuTempValue !== "--")
                    cpuLine += " " + temp.cpuTempValue;
                parts.push(cpuLine);
            } else if (key === "ram") {
                var ramLine = root.ramLabel + ": " + memory.ramValue;
                if (root.hasSub("ram", "temp"))
                    ramLine += " " + temp.ramTempValue;
                parts.push(ramLine);
            }
            else if (key === "temp")
                parts.push(root.tempLabel + ": " + temp.tempValue);
            else if (key === "gpu") {
                if (gpu.gpuDataList.length > 1) {
                    for (var g = 0; g < gpu.gpuDataList.length; g++) {
                        var gd = gpu.gpuDataList[g];
                        var label = gd.name || gd.id;
                        var vals = [];
                        if (gd.usage) vals.push(gd.usage);
                        if (gd.vram)  vals.push(gd.vram);
                        if (gd.temp)  vals.push(gd.temp);
                        if (vals.length > 0) parts.push(label + ": " + vals.join(" "));
                    }
                } else {
                    var _gpuName = gpu.gpuDataList.length > 0 ? gpu.gpuDataList[0].name : "GPU";
                    var gpuParts = [];
                    if (gpu.hasGpuUsageData) gpuParts.push(gpu.gpuValue);
                    if (gpu.hasGpuVramData)  gpuParts.push(gpu.gpuRamValue);
                    if (gpu.hasGpuTempData)  gpuParts.push(gpu.gpuTempValue);
                    if (gpuParts.length > 0) parts.push(_gpuName + ": " + gpuParts.join(" "));
                }
            } else if (key === "bat") {
                if (root.hasSub("bat", "power") && battery.powerValue)
                    parts.push("BAT: " + battery.batValue + " " + battery.powerValue);
                else
                    parts.push("BAT: " + battery.batValue);
            } else if (key === "net") {
                var ipStr = (root.hasSub("net", "ip") && showNetworkIp && network.netIpValue && network.netIpValue !== "..." && network.netIpValue !== "") ? " " + network.netIpValue : "";
                parts.push(root.netLabel + ": ↓" + network.netDownValue + " ↑" + network.netUpValue + ipStr);
            } else if (key === "disk") {
                var dParts = [];
                if (root.hasSub("disk", "read"))  dParts.push("↓" + disk.diskReadValue);
                if (root.hasSub("disk", "write")) dParts.push("↑" + disk.diskWriteValue);
                if (root.hasSub("disk", "temp") && disk.diskTempValue) dParts.push(disk.diskTempValue);
                if (dParts.length > 0) parts.push(root.diskLabel + ": " + dParts.join(" "));
            } else if (key === "fan")
                parts.push("FAN: " + fans.fanValue);
            else if (key === "uptime")
                parts.push("UPTIME: " + uptime.uptimeValue);
        }
        return parts.join("\n");
    }
}
