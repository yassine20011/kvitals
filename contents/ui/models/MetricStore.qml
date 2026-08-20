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

    // Normalizes input to a finite numeric scalar or NaN sentinel
    function _normalizeValue(val) {
        if (typeof val === "number" && isFinite(val) && !isNaN(val))
            return val;
        return NaN;
    }

    // Normalizes input to string
    function _normalizeString(val, fallback) {
        if (typeof val === "string")
            return val;
        if (val !== undefined && val !== null)
            return String(val);
        return fallback !== undefined ? fallback : "";
    }

    // Appends val to the chartKey ring buffer. Rejects non-finite numbers.
    function _pushHistory(key, val) {
        if (!key || typeof key !== "string") return false;
        if (typeof val !== "number" || isNaN(val) || !isFinite(val)) return false;
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
                if (m.hasChart && m.chartKey && typeof m.value === "number" && isFinite(m.value) && !isNaN(m.value)) {
                    if (root._pushHistory(m.chartKey, m.value))
                        changed = true;
                }
            }
            if (changed) root.chartVersion++;
        }
    }

    // Resolves color based on numeric value and threshold settings
    function _resolveMetricColor(numVal, thresholdType, thresholdKey) {
        if (!root.config || !root.config.enableThresholdColors || thresholdType === "none" || typeof numVal !== "number" || isNaN(numVal) || !isFinite(numVal))
            return root.baseTextColor;

        var warn = root.config.getWarningThreshold(thresholdKey);
        var crit = root.config.getCriticalThreshold(thresholdKey);
        var inverted = (thresholdType === "inverted");

        return Utils.resolveColor(numVal, warn, crit, root.config.warningColor, root.config.criticalColor, root.baseTextColor, inverted);
    }

    // Constructs a normalized metric object conforming to the Metric Contract
    function _createMetric(defId, overrides) {
        overrides = overrides || {};
        var def = Defs.DEFINITIONS[defId] || {};
        var cfg = root.config;
        var group = _normalizeString(overrides.group || def.group, "");
        var subKey = _normalizeString(overrides.subKey || def.subKey, "");
        var rawVal = _normalizeValue(overrides.value);
        var threshType = def.thresholdType || "none";
        var threshKey = def.thresholdKey || group;
        var clr = overrides.color !== undefined ? overrides.color : _resolveMetricColor(rawVal, threshType, threshKey);
        var defIcon = def.iconOverrideKey ? cfg[def.iconOverrideKey] : cfg.getGroupIcon(group);

        var displayVal = _normalizeString(overrides.displayValue, "");
        var popupDisplay = _normalizeString(overrides.popupDisplay, displayVal);
        var rawStr = _normalizeString(overrides.rawString, displayVal);
        var chartKey = overrides.chartKey !== undefined ? _normalizeString(overrides.chartKey, "") : (def.chartKey || "");
        var chartMax = typeof overrides.chartMax === "number" && isFinite(overrides.chartMax) ? overrides.chartMax : (def.chartMax || 0);
        var hasChart = Boolean(chartKey && chartKey.length > 0);

        var devId = _normalizeString(overrides.deviceId, "");
        var devName = _normalizeString(overrides.deviceName, "");

        return {
            id: _normalizeString(overrides.id, def.id || defId),
            defId: defId,
            group: group,
            subKey: subKey,
            deviceId: devId,
            deviceName: devName,
            label: _normalizeString(overrides.label, (group === "ram" && subKey === "percentage" ? cfg.ramLabel : (cfg.getGroupLabel(group) + " " + def.label))),
            groupLabel: _normalizeString(overrides.groupLabel, cfg.getGroupLabel(group)),
            subLabel: _normalizeString(overrides.subLabel !== undefined ? overrides.subLabel : (def.prefix || ""), ""),
            prefix: _normalizeString(overrides.prefix !== undefined ? overrides.prefix : (def.prefix || ""), ""),
            icon: overrides.icon || defIcon,
            secondaryIcon: overrides.secondaryIcon !== undefined ? overrides.secondaryIcon : (def.secondaryIcon ? cfg.tempIcon : ""),
            value: rawVal,
            displayValue: displayVal,
            popupDisplay: popupDisplay,
            rawString: rawStr,
            color: clr,
            status: _normalizeString(overrides.status, "ready"),
            chartKey: chartKey,
            chartMax: chartMax,
            hasChart: hasChart,
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
