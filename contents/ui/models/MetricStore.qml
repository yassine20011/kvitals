// MetricStore aggregates live sensor values into a flat list of metric objects.
// Views (CompactView, FullView) never read sensor components directly; they only
// consume the metrics list and chartHistory exposed here.
//
// Data flow:
//   Sensor QML components -> MetricStore.metrics (recalculated on each sensor change)
//   chartTimer -> MetricStore.chartHistory (sampled every updateInterval ms)
//   ViewHelpers.js -> presentation items consumed by the views
import QtQuick
import "../sensors"
import "./MetricDefinitions.js" as Defs

Item {
    id: root

    required property var config
    required property var sensors
    required property bool sensorsReady
    required property color baseTextColor

    // Chart history buffer keyed by chartKey. Each entry is a sliding window of
    // up to maxChartPoints numeric samples collected by chartTimer.
    property var chartHistory: ({})
    property int chartVersion: 0
    property int maxChartPoints: 60

    // Returns the sample array for a chartKey, or [] if none exists yet.
    function getHistory(key) {
        if (!key || !chartHistory[key]) return [];
        return chartHistory[key];
    }

    // Appends val to the chartKey ring buffer. Returns false without writing if
    // val is not a finite non-negative number.
    function _pushHistory(key, val) {
        if (!key) return false;
        if (typeof val !== "number" || isNaN(val) || val < 0) return false;
        if (!chartHistory[key]) chartHistory[key] = [];
        chartHistory[key].push(val);
        if (chartHistory[key].length > maxChartPoints) chartHistory[key].shift();
        return true;
    }

    Timer {
        id: chartTimer
        interval: root.config ? root.config.updateInterval : 2000
        repeat: true
        running: root.sensorsReady
        onTriggered: {
            var list = root.metrics;
            var changed = false;
            for (var i = 0; i < list.length; i++) {
                var m = list[i];
                if (m.hasChart && m.chartKey && typeof m.value === "number") {
                    if (root._pushHistory(m.chartKey, m.value))
                        changed = true;
                }
            }
            if (changed) root.chartVersion++;
        }
    }

    // _resolveMetricColor picks a color based on the numeric value and the
    // metric's threshold settings. Returns baseTextColor when threshold colors
    // are off, the type is "none", or the value is not a number.
    function _resolveMetricColor(numVal, thresholdType, thresholdKey) {
        if (!root.config || !root.config.enableThresholdColors || thresholdType === "none" || isNaN(numVal))
            return root.baseTextColor;

        var warn = root.config.getWarningThreshold(thresholdKey);
        var crit = root.config.getCriticalThreshold(thresholdKey);
        var inverted = (thresholdType === "inverted");

        return Utils.resolveColor(numVal, warn, crit, root.config.warningColor, root.config.criticalColor, root.baseTextColor, inverted);
    }

    // _createMetric builds one metric object from a DEFINITIONS entry and a set
    // of runtime overrides from the sensor layer. Override fields always win.
    //
    // The returned object shape is the metric "struct" used everywhere else:
    //   id, defId, group, subKey, deviceId, deviceName
    //   label, groupLabel, subLabel, prefix
    //   icon, secondaryIcon
    //   value (numeric), displayValue (string), popupDisplay, rawString
    //   color, status
    //   chartKey, chartMax, hasChart
    //   visibleInCompact, visibleInPopup
    function _createMetric(defId, overrides) {
        var def = Defs.DEFINITIONS[defId] || {};
        var cfg = root.config;
        var group = overrides.group || def.group;
        var subKey = overrides.subKey || def.subKey;
        var rawVal = overrides.value !== undefined ? overrides.value : NaN;
        var threshType = def.thresholdType || "none";
        var threshKey = def.thresholdKey || group;
        var clr = overrides.color !== undefined ? overrides.color : _resolveMetricColor(rawVal, threshType, threshKey);
        var defIcon = def.iconOverrideKey ? cfg[def.iconOverrideKey] : cfg.getGroupIcon(group);

        var devId = overrides.deviceId || "";
        return {
            id: overrides.id || def.id,
            defId: defId,
            group: group,
            subKey: subKey,
            deviceId: devId,
            deviceName: overrides.deviceName || "",
            label: overrides.label || (group === "ram" && subKey === "percentage" ? cfg.ramLabel : (cfg.getGroupLabel(group) + " " + def.label)),
            groupLabel: overrides.groupLabel || cfg.getGroupLabel(group),
            subLabel: overrides.subLabel !== undefined ? overrides.subLabel : (def.prefix || ""),
            prefix: overrides.prefix !== undefined ? overrides.prefix : (def.prefix || ""),
            icon: overrides.icon || defIcon,
            secondaryIcon: overrides.secondaryIcon !== undefined ? overrides.secondaryIcon : (def.secondaryIcon ? cfg.tempIcon : ""),
            value: rawVal,
            displayValue: overrides.displayValue || "",
            popupDisplay: overrides.popupDisplay || overrides.displayValue || "",
            rawString: overrides.rawString || overrides.displayValue || "",
            color: clr,
            status: overrides.status || "ready",
            chartKey: overrides.chartKey !== undefined ? overrides.chartKey : (def.chartKey || ""),
            chartMax: overrides.chartMax !== undefined ? overrides.chartMax : (def.chartMax || 0),
            hasChart: def.chartKey && def.chartKey.length > 0,
            visibleInCompact: cfg.isMetricVisible(group, subKey, "compact", devId),
            visibleInPopup: cfg.isMetricVisible(group, subKey, "widget", devId)
        };
    }

    readonly property var metrics: {
        if (!sensorsReady || !sensors || !config) return [];

        var list = [];
        var s = sensors;
        var cfg = config;

        // CPU
        if (cfg.isGroupEnabled("cpu") && s.cpu) {
            list.push(_createMetric("cpu.usage", {
                value: s.cpu.cpuNumericValue,
                displayValue: s.cpu.cpuValue,
                status: !isNaN(s.cpu.cpuNumericValue) ? "ready" : "loading"
            }));

            if (s.cpu.cpuFreqValue) {
                list.push(_createMetric("cpu.freq", {
                    displayValue: s.cpu.cpuFreqValue,
                    status: s.cpu.cpuFreqValue !== "..." ? "ready" : "loading"
                }));
            }

            if (s.temp && s.temp.cpuTempValue && s.temp.cpuTempValue !== "--") {
                list.push(_createMetric("cpu.temp", {
                    value: s.temp.cpuTempNumericValue,
                    displayValue: s.temp.cpuTempValue,
                    status: !isNaN(s.temp.cpuTempNumericValue) ? "ready" : "unavailable"
                }));
            }
        }

        // RAM
        if (cfg.isGroupEnabled("ram") && s.memory) {
            list.push(_createMetric("ram.percentage", {
                value: s.memory.ramPercentage,
                displayValue: s.memory.ramPercentValue,
                label: cfg.ramLabel,
                status: !isNaN(s.memory.ramPercentage) ? "ready" : "loading"
            }));

            list.push(_createMetric("ram.used", {
                displayValue: s.memory.ramValue,
                label: cfg.ramLabel + " Usage",
                status: s.memory.ramValue !== "..." ? "ready" : "loading"
            }));

            if (s.temp && s.temp.ramTempExists && s.temp.ramTempValue !== "--") {
                list.push(_createMetric("ram.temp", {
                    value: s.temp.ramTempNumericValue,
                    displayValue: s.temp.ramTempValue,
                    status: !isNaN(s.temp.ramTempNumericValue) ? "ready" : "unavailable"
                }));
            }
        }

        // System Temperature
        if (cfg.isGroupEnabled("temp") && s.temp && s.temp.tempValue && s.temp.tempValue !== "--") {
            list.push(_createMetric("temp.system", {
                value: s.temp.tempNumericValue,
                displayValue: s.temp.tempValue,
                label: cfg.tempLabel,
                status: !isNaN(s.temp.tempNumericValue) ? "ready" : "unavailable"
            }));
        }

        // GPU instances
        if (cfg.isGroupEnabled("gpu") && s.gpu) {
            var gList = s.gpu.gpuDataList;
            if (gList && gList.length > 0) {
                for (var gi = 0; gi < gList.length; gi++) {
                    var gd = gList[gi];
                    var gpuName = gd.name || ("GPU " + (gi + 1));

                    if (gd.usage) {
                        list.push(_createMetric("gpu.usage", {
                            id: "gpu:" + gd.id + ".usage",
                            deviceId: gd.id, deviceName: gpuName,
                            label: gpuName + " Usage", groupLabel: gpuName,
                            value: gd.usageNumber, displayValue: gd.usage,
                            chartKey: "gpu:" + gd.id,
                            status: !isNaN(gd.usageNumber) ? "ready" : "loading"
                        }));
                    }
                    if (gd.vram) {
                        list.push(_createMetric("gpu.vram", {
                            id: "gpu:" + gd.id + ".vram",
                            deviceId: gd.id, deviceName: gpuName,
                            label: gpuName + " VRAM", groupLabel: gpuName,
                            displayValue: gd.vram,
                            status: "ready"
                        }));
                    }
                    if (gd.temp) {
                        list.push(_createMetric("gpu.temp", {
                            id: "gpu:" + gd.id + ".temp",
                            deviceId: gd.id, deviceName: gpuName,
                            label: gpuName + " Temperature", groupLabel: gpuName,
                            value: gd.tempNumber, displayValue: gd.temp,
                            chartKey: "gpuTemp:" + gd.id,
                            status: !isNaN(gd.tempNumber) ? "ready" : "unavailable"
                        }));
                    }
                }
            }
        }

        // Battery
        if (cfg.isGroupEnabled("bat") && s.battery) {
            if (s.battery.batValue) {
                list.push(_createMetric("bat.percentage", {
                    value: s.battery.batNumericValue,
                    displayValue: s.battery.batValue,
                    status: !isNaN(s.battery.batNumericValue) ? "ready" : "loading"
                }));
            }
            if (s.battery.powerValue) {
                list.push(_createMetric("bat.power", {
                    displayValue: s.battery.powerValue,
                    status: "ready"
                }));
            }
        }

        // Network
        if (cfg.isGroupEnabled("net") && s.network) {
            list.push(_createMetric("net.down", {
                value: s.network.netDownRaw,
                displayValue: s.network.netDownValue,
                label: cfg.netLabel + " ↓",
                status: !isNaN(s.network.netDownRaw) ? "ready" : "loading"
            }));
            list.push(_createMetric("net.up", {
                value: s.network.netUpRaw,
                displayValue: s.network.netUpValue,
                label: cfg.netLabel + " ↑",
                status: !isNaN(s.network.netUpRaw) ? "ready" : "loading"
            }));
            if (cfg.showNetworkIp && s.network.netIpValue && s.network.netIpValue !== "..." && s.network.netIpValue !== "") {
                list.push(_createMetric("net.ip", {
                    displayValue: s.network.netIpValue,
                    status: "ready"
                }));
            }
        }

        // Disk instances
        if (cfg.isGroupEnabled("disk") && s.disk) {
            if (s.disk.multiDisk && s.disk.diskDataList.length > 0) {
                for (var di = 0; di < s.disk.diskDataList.length; di++) {
                    var dd = s.disk.diskDataList[di];
                    var dName = dd.name || dd.id;
                    list.push(_createMetric("disk.read", {
                        id: "disk:" + dd.id + ".read",
                        deviceId: dd.id, deviceName: dName,
                        label: dName + " ↓", groupLabel: dName,
                        displayValue: dd.read,
                        status: "ready"
                    }));
                    list.push(_createMetric("disk.write", {
                        id: "disk:" + dd.id + ".write",
                        deviceId: dd.id, deviceName: dName,
                        label: dName + " ↑", groupLabel: dName,
                        displayValue: dd.write,
                        status: "ready"
                    }));
                }
            } else {
                list.push(_createMetric("disk.read", {
                    displayValue: s.disk.diskReadValue,
                    label: cfg.diskLabel + " ↓",
                    status: "ready"
                }));
                list.push(_createMetric("disk.write", {
                    displayValue: s.disk.diskWriteValue,
                    label: cfg.diskLabel + " ↑",
                    status: "ready"
                }));
            }

            if (s.disk.diskTempValue) {
                list.push(_createMetric("disk.temp", {
                    value: s.disk.diskTempNumber,
                    displayValue: s.disk.diskTempValue,
                    label: cfg.diskLabel + " Temperature",
                    status: !isNaN(s.disk.diskTempNumber) ? "ready" : "unavailable"
                }));
            }
        }

        // Fan instances
        if (cfg.isGroupEnabled("fan") && s.fans && s.fans.hasFanData) {
            var fList = s.fans.fanDataList;
            for (var fi = 0; fi < fList.length; fi++) {
                var fd = fList[fi];
                list.push(_createMetric("fan.speed", {
                    id: "fan:" + fd.id,
                    deviceId: fd.id, deviceName: fd.name || ("Fan " + fd.number),
                    label: fd.number + ": " + (fd.name || fd.id),
                    groupLabel: cfg.fanLabel,
                    subLabel: s.fans.multiFan ? (fd.number + ":") : "",
                    value: fd.valueNumber,
                    displayValue: (fd.isEstimated ? "~" : "") + fd.value,
                    popupDisplay: fd.rpmValue,
                    chartKey: "fan:" + fd.id,
                    status: !isNaN(fd.valueNumber) ? "ready" : "loading"
                }));
            }
        }

        // Uptime
        if (cfg.isGroupEnabled("uptime") && s.uptime && s.uptime.uptimeValue) {
            list.push(_createMetric("uptime.uptime", {
                displayValue: s.uptime.uptimeValue,
                status: "ready"
            }));
        }

        return list;
    }
}
