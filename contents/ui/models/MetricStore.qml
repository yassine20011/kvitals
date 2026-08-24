import QtQuick
import "../sensors"
import "./MetricDefinitions.js" as Defs

Item {
    id: root

    required property var config
    required property var sensors
    required property bool sensorsReady
    required property color baseTextColor

    // Debounced metrics array: rebuilt once per flushTimer tick, not per sensor change.
    // Consumers should bind to this property, not to individual sensor values.
    property var metrics: []

    function _normalizeValue(val) {
        if (typeof val === "number" && isFinite(val) && !isNaN(val))
            return val;
        return NaN;
    }

    function _normalizeString(val, fallback) {
        if (typeof val === "string")
            return val;
        if (val !== undefined && val !== null)
            return String(val);
        return fallback !== undefined ? fallback : "";
    }

    function _rebuildMetrics() {
        if (!sensorsReady || !sensors || !config) {
            metrics = [];
            return;
        }
        metrics = _computeMetrics();
    }

    // Single flush timer: fires once per update interval and rebuilds metrics.
    // This prevents N partial rebuilds when N sensors update in quick succession.
    Timer {
        id: flushTimer
        interval: root.config ? root.config.updateInterval : 2000
        repeat: true
        running: root.sensorsReady
        triggeredOnStart: true
        onTriggered: {
            root._rebuildMetrics();
        }
    }

    onSensorsReadyChanged: {
        if (sensorsReady) root._rebuildMetrics();
    }

    Connections {
        target: root.config
        function onPinnedListChanged() { root._rebuildMetrics(); }
        function onCpuLabelChanged() { root._rebuildMetrics(); }
        function onRamLabelChanged() { root._rebuildMetrics(); }
        function onSwapLabelChanged() { root._rebuildMetrics(); }
        function onTempLabelChanged() { root._rebuildMetrics(); }
        function onNetLabelChanged() { root._rebuildMetrics(); }
        function onDiskLabelChanged() { root._rebuildMetrics(); }
        function onFanLabelChanged() { root._rebuildMetrics(); }
        function onBatLabelChanged() { root._rebuildMetrics(); }
        function onGpuLabelsChanged() { root._rebuildMetrics(); }
        function onDiskLabelsChanged() { root._rebuildMetrics(); }
        function onFanLabelsChanged() { root._rebuildMetrics(); }
        function onGpuSelectionChanged() { root._rebuildMetrics(); }
        function onNetworkInterfaceChanged() { root._rebuildMetrics(); }
        function onBatteryDeviceChanged() { root._rebuildMetrics(); }
        function onEnableThresholdColorsChanged() { root._rebuildMetrics(); }
        function onWarningColorChanged() { root._rebuildMetrics(); }
        function onCriticalColorChanged() { root._rebuildMetrics(); }
    }

    function _resolveMetricColor(numVal, thresholdType, thresholdKey) {
        if (!root.config || !root.config.enableThresholdColors || thresholdType === "none" || typeof numVal !== "number" || isNaN(numVal) || !isFinite(numVal))
            return root.baseTextColor;

        var warn = root.config.getWarningThreshold(thresholdKey);
        var crit = root.config.getCriticalThreshold(thresholdKey);
        var inverted = (thresholdType === "inverted");

        return Utils.resolveColor(numVal, warn, crit, root.config.warningColor, root.config.criticalColor, root.baseTextColor, inverted);
    }

    function _createMetric(defId, overrides) {
        overrides = overrides || {};
        var def = Defs.DEFINITIONS[defId] || {};
        var cfg = root.config;
        var group = _normalizeString(overrides.group || def.group, "");
        var subKey = _normalizeString(overrides.subKey || def.subKey, "");
        var devId = _normalizeString(overrides.deviceId, "");
        var devName = _normalizeString(overrides.deviceName, "");
        var instanceId = _normalizeString(overrides.id, Defs.buildInstanceId(group, devId, subKey));

        var rawVal = _normalizeValue(overrides.value);
        var threshType = def.thresholdType || "none";
        var threshKey = def.thresholdKey || group;
        var clr = overrides.color !== undefined ? overrides.color : _resolveMetricColor(rawVal, threshType, threshKey);
        var defIcon = def.icon ? cfg.resolveIcon(def.icon) : (def.iconOverrideKey ? cfg[def.iconOverrideKey] : cfg.getGroupIcon(group));

        var displayVal = _normalizeString(overrides.displayValue, "");
        var popupDisplay = _normalizeString(overrides.popupDisplay, displayVal);
        var rawStr = _normalizeString(overrides.rawString, displayVal);
        var isPinned = cfg ? cfg.isPinned(instanceId) : false;

        return {
            id: instanceId,
            defId: defId,
            group: group,
            subKey: subKey,
            deviceId: devId,
            deviceName: devName,
            label: _normalizeString(overrides.label, (cfg ? cfg.getGroupLabel(group) : (def.label || group.toUpperCase()))),
            groupLabel: _normalizeString(overrides.groupLabel, cfg.getGroupLabel(group)),
            subLabel: _normalizeString(overrides.subLabel !== undefined ? overrides.subLabel : (def.label || ""), ""),
            prefix: _normalizeString(overrides.prefix !== undefined ? overrides.prefix : (def.prefix || ""), ""),
            icon: overrides.icon || defIcon,
            secondaryIcon: overrides.secondaryIcon !== undefined ? overrides.secondaryIcon : (def.secondaryIcon ? cfg.tempIcon : ""),
            value: rawVal,
            displayValue: displayVal,
            popupDisplay: popupDisplay,
            rawString: rawStr,
            color: clr,
            status: _normalizeString(overrides.status, "ready"),
            isPinned: isPinned
        };
    }

    function _computeMetrics() {
        if (!sensorsReady || !sensors || !config) return [];

        var list = [];
        var s = sensors;
        var cfg = config;

        // CPU
        if (s.cpu) {
            list.push(_createMetric("cpu.usage", {
                value: s.cpu.cpuNumericValue,
                displayValue: s.cpu.cpuValue,
                label: cfg.cpuLabel,
                subLabel: "Usage",
                status: !isNaN(s.cpu.cpuNumericValue) ? "ready" : "loading"
            }));

            if (s.cpu.cpuFreqValue) {
                list.push(_createMetric("cpu.freq", {
                    displayValue: s.cpu.cpuFreqValue,
                    label: cfg.cpuLabel,
                    subLabel: "Frequency",
                    status: s.cpu.cpuFreqValue !== "..." ? "ready" : "loading"
                }));
            }

            if (s.cpu.cpuLoad1Value && s.cpu.cpuLoad1Value !== "...") {
                list.push(_createMetric("cpu.load1", {
                    value: s.cpu.cpuLoad1Raw,
                    displayValue: s.cpu.cpuLoad1Value,
                    status: !isNaN(s.cpu.cpuLoad1Raw) ? "ready" : "loading"
                }));
            }

            if (s.cpu.cpuLoad5Value && s.cpu.cpuLoad5Value !== "...") {
                list.push(_createMetric("cpu.load5", {
                    value: s.cpu.cpuLoad5Raw,
                    displayValue: s.cpu.cpuLoad5Value,
                    status: !isNaN(s.cpu.cpuLoad5Raw) ? "ready" : "loading"
                }));
            }

            if (s.cpu.cpuLoad15Value && s.cpu.cpuLoad15Value !== "...") {
                list.push(_createMetric("cpu.load15", {
                    value: s.cpu.cpuLoad15Raw,
                    displayValue: s.cpu.cpuLoad15Value,
                    status: !isNaN(s.cpu.cpuLoad15Raw) ? "ready" : "loading"
                }));
            }

            if (s.temp && s.temp.cpuTempValue && s.temp.cpuTempValue !== "--") {
                list.push(_createMetric("cpu.temp", {
                    value: s.temp.cpuTempNumericValue,
                    displayValue: s.temp.cpuTempValue,
                    label: "CPU",
                    subLabel: "CPU",
                    status: !isNaN(s.temp.cpuTempNumericValue) ? "ready" : "unavailable"
                }));
            }

            if (s.cpu.coreDataList && s.cpu.coreDataList.length > 0) {
                var cList = s.cpu.coreDataList;
                for (var ci = 0; ci < cList.length; ci++) {
                    var cd = cList[ci];
                    list.push(_createMetric("cpu.core", {
                        deviceId: cd.id,
                        deviceName: cd.name,
                        label: cd.name,
                        groupLabel: cfg.cpuLabel,
                        subLabel: cd.name,
                        value: cd.usageNumber,
                        displayValue: cd.usage,
                        status: !isNaN(cd.usageNumber) ? "ready" : "loading"
                    }));
                }
            }
        }

        // RAM
        if (s.memory) {
            list.push(_createMetric("ram.percentage", {
                value: s.memory.ramPercentage,
                displayValue: s.memory.ramPercentValue,
                label: cfg.ramLabel,
                subLabel: "Percentage",
                status: !isNaN(s.memory.ramPercentage) ? "ready" : "loading"
            }));

            list.push(_createMetric("ram.used", {
                displayValue: s.memory.ramValue,
                label: cfg.ramLabel,
                subLabel: "Used / Total",
                status: s.memory.ramValue !== "..." ? "ready" : "loading"
            }));

            if (s.temp && s.temp.ramTempExists && s.temp.ramTempValue !== "--") {
                list.push(_createMetric("ram.temp", {
                    value: s.temp.ramTempNumericValue,
                    displayValue: s.temp.ramTempValue,
                    label: "RAM",
                    subLabel: "RAM",
                    status: !isNaN(s.temp.ramTempNumericValue) ? "ready" : "unavailable"
                }));
            }
        }

        // Swap
        if (s.swap && s.swap.swapAvailable) {
            list.push(_createMetric("swap.percent", {
                value: s.swap.swapPercentage,
                displayValue: s.swap.swapPercentValue,
                label: cfg.swapLabel,
                subLabel: "Usage (%)",
                status: !isNaN(s.swap.swapPercentage) ? "ready" : "loading"
            }));

            list.push(_createMetric("swap.used", {
                value: s.swap.swapUsedRaw,
                displayValue: s.swap.swapUsedValue,
                label: cfg.swapLabel,
                subLabel: "Used",
                status: !isNaN(s.swap.swapUsedRaw) ? "ready" : "loading"
            }));

            list.push(_createMetric("swap.free", {
                value: s.swap.swapFreeRaw,
                displayValue: s.swap.swapFreeValue,
                label: cfg.swapLabel,
                subLabel: "Free",
                status: !isNaN(s.swap.swapFreeRaw) ? "ready" : "loading"
            }));

            list.push(_createMetric("swap.total", {
                value: s.swap.swapTotalRaw,
                displayValue: s.swap.swapTotalValue,
                label: cfg.swapLabel,
                subLabel: "Total",
                status: !isNaN(s.swap.swapTotalRaw) ? "ready" : "loading"
            }));
        }

        // System Temperature
        if (s.temp && s.temp.tempValue && s.temp.tempValue !== "--") {
            list.push(_createMetric("temp.system", {
                value: s.temp.tempNumericValue,
                displayValue: s.temp.tempValue,
                label: cfg.tempLabel,
                subLabel: "System",
                status: !isNaN(s.temp.tempNumericValue) ? "ready" : "unavailable"
            }));
        }

        // GPU instances
        if (s.gpu) {
            var gList = s.gpu.gpuDataList;
            if (gList && gList.length > 0) {
                for (var gi = 0; gi < gList.length; gi++) {
                    var gd = gList[gi];
                    var gpuName = gd.name || ("GPU " + (gi + 1));

                    if (gd.usage) {
                        list.push(_createMetric("gpu.usage", {
                            deviceId: gd.id, deviceName: gpuName,
                            label: gpuName, groupLabel: gpuName,
                            subLabel: "Usage",
                            value: gd.usageNumber, displayValue: gd.usage,
                            status: !isNaN(gd.usageNumber) ? "ready" : "loading"
                        }));
                    }
                    if (gd.vram) {
                        list.push(_createMetric("gpu.vram", {
                            deviceId: gd.id, deviceName: gpuName,
                            label: gpuName, groupLabel: gpuName,
                            subLabel: "VRAM",
                            displayValue: gd.vram,
                            status: "ready"
                        }));
                    }
                    if (gd.temp) {
                        list.push(_createMetric("gpu.temp", {
                            deviceId: gd.id, deviceName: gpuName,
                            label: gpuName, groupLabel: gpuName,
                            subLabel: gpuName,
                            value: gd.tempNumber, displayValue: gd.temp,
                            status: !isNaN(gd.tempNumber) ? "ready" : "unavailable"
                        }));
                    }
                    if (gd.freq) {
                        list.push(_createMetric("gpu.freq", {
                            deviceId: gd.id, deviceName: gpuName,
                            label: gpuName + " Frequency", groupLabel: gpuName,
                            subLabel: "Frequency",
                            value: gd.freqNumber, displayValue: gd.freq,
                            status: !isNaN(gd.freqNumber) ? "ready" : "loading"
                        }));
                    }
                    if (gd.power) {
                        list.push(_createMetric("gpu.power", {
                            deviceId: gd.id, deviceName: gpuName,
                            label: gpuName + " Power", groupLabel: gpuName,
                            subLabel: "Power",
                            value: gd.powerNumber, displayValue: gd.power,
                            status: !isNaN(gd.powerNumber) ? "ready" : "loading"
                        }));
                    }
                }
            }
        }

        // Battery
        if (s.battery && s.battery.hasBattery) {
            list.push(_createMetric("bat.percentage", {
                value: s.battery.batNumericValue,
                displayValue: s.battery.batValue || "...",
                label: cfg.batLabel || "BAT",
                subLabel: "Percentage",
                status: !isNaN(s.battery.batNumericValue) ? "ready" : "loading"
            }));
            if (s.battery.powerValue) {
                list.push(_createMetric("bat.power", {
                    displayValue: s.battery.powerValue,
                    label: cfg.batLabel || "BAT",
                    subLabel: "Power",
                    status: "ready"
                }));
            }
            if (s.battery.batHealthValue) {
                list.push(_createMetric("bat.health", {
                    value: s.battery.batHealthNumericValue,
                    displayValue: s.battery.batHealthValue,
                    label: (cfg.batLabel || "BAT") + " Health",
                    subLabel: "Health",
                    status: !isNaN(s.battery.batHealthNumericValue) ? "ready" : "loading"
                }));
            }
        }

        // Network
        if (s.network) {
            list.push(_createMetric("net.down", {
                value: s.network.netDownRaw,
                displayValue: s.network.netDownValue,
                label: cfg.netLabel,
                subLabel: "Download",
                icon: cfg.resolveIcon("network-download-symbolic"),
                status: !isNaN(s.network.netDownRaw) ? "ready" : "loading"
            }));
            list.push(_createMetric("net.up", {
                value: s.network.netUpRaw,
                displayValue: s.network.netUpValue,
                label: cfg.netLabel,
                subLabel: "Upload",
                icon: cfg.resolveIcon("network-upload-symbolic"),
                status: !isNaN(s.network.netUpRaw) ? "ready" : "loading"
            }));
            if (s.network.netTotalDownValue && s.network.netTotalDownValue !== "..." && !isNaN(s.network.netTotalDownRaw)) {
                list.push(_createMetric("net.totalDown", {
                    value: s.network.netTotalDownRaw,
                    displayValue: s.network.netTotalDownValue,
                    label: cfg.netLabel + " Total ↓",
                    subLabel: "Total Downloaded",
                    icon: cfg.resolveIcon("network-download-symbolic"),
                    status: "ready"
                }));
            }
            if (s.network.netTotalUpValue && s.network.netTotalUpValue !== "..." && !isNaN(s.network.netTotalUpRaw)) {
                list.push(_createMetric("net.totalUp", {
                    value: s.network.netTotalUpRaw,
                    displayValue: s.network.netTotalUpValue,
                    label: cfg.netLabel + " Total ↑",
                    subLabel: "Total Uploaded",
                    icon: cfg.resolveIcon("network-upload-symbolic"),
                    status: "ready"
                }));
            }
            if (s.network.hasWifiSignal && !isNaN(s.network.netSignalRaw)) {
                list.push(_createMetric("net.signal", {
                    value: s.network.netSignalRaw,
                    displayValue: s.network.netSignalValue,
                    label: cfg.netLabel + " Signal",
                    subLabel: "Wi-Fi Signal",
                    icon: cfg.resolveIcon("network-wireless-symbolic"),
                    status: "ready"
                }));
            }
            if (s.network.netIpValue && s.network.netIpValue !== "..." && s.network.netIpValue !== "") {
                list.push(_createMetric("net.ip", {
                    displayValue: s.network.netIpValue,
                    label: cfg.netLabel,
                    subLabel: "IP address",
                    icon: cfg.resolveIcon("network-symbolic"),
                    status: "ready"
                }));
            }
        }

        // Disk instances
        if (s.disk) {
            var dList = s.disk.diskDataList;
            if (dList && dList.length > 0) {
                for (var di = 0; di < dList.length; di++) {
                    var dd = dList[di];
                    var dName = dd.name || dd.id;
                    list.push(_createMetric("disk.read", {
                        deviceId: dd.id, deviceName: dName,
                        label: dName, groupLabel: dName,
                        subLabel: "Read",
                        icon: cfg.resolveIcon("network-download-symbolic"),
                        displayValue: dd.read,
                        status: "ready"
                    }));
                    list.push(_createMetric("disk.write", {
                        deviceId: dd.id, deviceName: dName,
                        label: dName, groupLabel: dName,
                        subLabel: "Write",
                        icon: cfg.resolveIcon("network-upload-symbolic"),
                        displayValue: dd.write,
                        status: "ready"
                    }));
                }
            }

            if (s.disk.diskUsedPercentValue) {
                list.push(_createMetric("disk.usage", {
                    value: s.disk.diskUsedPercentRaw,
                    displayValue: s.disk.diskUsedPercentValue,
                    label: cfg.diskLabel + " Usage",
                    status: !isNaN(s.disk.diskUsedPercentRaw) ? "ready" : "loading"
                }));
            }

            if (s.disk.diskSpaceValue) {
                list.push(_createMetric("disk.space", {
                    value: s.disk.diskUsedRaw,
                    displayValue: s.disk.diskSpaceValue,
                    label: cfg.diskLabel + " Space",
                    status: !isNaN(s.disk.diskUsedRaw) ? "ready" : "loading"
                }));
            }

            if (s.disk.diskTempValue) {
                var firstDiskId = (dList && dList.length > 0) ? dList[0].id : "";
                var firstDiskName = (dList && dList.length > 0 && dList[0].name) ? dList[0].name : "Disk";
                list.push(_createMetric("disk.temp", {
                    deviceId: firstDiskId,
                    deviceName: firstDiskName,
                    value: s.disk.diskTempNumber,
                    displayValue: s.disk.diskTempValue,
                    label: firstDiskName,
                    groupLabel: firstDiskName,
                    subLabel: firstDiskName,
                    status: !isNaN(s.disk.diskTempNumber) ? "ready" : "unavailable"
                }));
            }
        }

        // Fan instances
        if (s.fans && s.fans.hasFanData) {
            var fList = s.fans.fanDataList;
            for (var fi = 0; fi < fList.length; fi++) {
                var fd = fList[fi];
                var fName = fd.name || ("Fan " + fd.number);
                list.push(_createMetric("fan.speed", {
                    deviceId: fd.id, deviceName: fName,
                    label: fName,
                    groupLabel: cfg.fanLabel,
                    subLabel: fName,
                    value: fd.valueNumber,
                    displayValue: (fd.isEstimated ? "~" : "") + fd.value,
                    popupDisplay: fd.rpmValue,
                    status: !isNaN(fd.valueNumber) ? "ready" : "loading"
                }));
            }
        }

        // Uptime
        if (s.uptime && s.uptime.uptimeValue) {
            list.push(_createMetric("uptime.uptime", {
                label: "Uptime",
                groupLabel: "Uptime",
                subLabel: "Uptime",
                displayValue: s.uptime.uptimeValue,
                status: "ready"
            }));
        }

        return list;
    }
}
