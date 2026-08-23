import QtQuick
import org.kde.plasma.plasmoid
import "./MetricDefinitions.js" as Defs

QtObject {
    id: root

    property var target: Plasmoid.configuration
    property string propertyPrefix: ""

    // Icon fallback resolver
    function resolveIcon(name) {
        switch (name) {
        case "am-cpu-symbolic":
        case "nvidia-ram-symbolic":
        case "am-disk-utility-symbolic":
        case "am-fan-symbolic":
        case "gpu-symbolic":
            return Qt.resolvedUrl("../../icons/" + name + ".svg");
        default:
            return name;
        }
    }

    // Group enable flags
    readonly property bool cpuEnabled:    (target && target[propertyPrefix + "cpuEnabled"] !== undefined)    ? Boolean(target[propertyPrefix + "cpuEnabled"])    : false
    readonly property bool ramEnabled:    (target && target[propertyPrefix + "ramEnabled"] !== undefined)    ? Boolean(target[propertyPrefix + "ramEnabled"])    : false
    readonly property bool swapEnabled:   (target && target[propertyPrefix + "swapEnabled"] !== undefined)   ? Boolean(target[propertyPrefix + "swapEnabled"])   : false
    readonly property bool tempEnabled:   (target && target[propertyPrefix + "tempEnabled"] !== undefined)   ? Boolean(target[propertyPrefix + "tempEnabled"])   : false
    readonly property bool gpuEnabled:    (target && target[propertyPrefix + "gpuEnabled"] !== undefined)    ? Boolean(target[propertyPrefix + "gpuEnabled"])    : false
    readonly property bool batEnabled:    (target && target[propertyPrefix + "batEnabled"] !== undefined)    ? Boolean(target[propertyPrefix + "batEnabled"])    : false
    readonly property bool netEnabled:    (target && target[propertyPrefix + "netEnabled"] !== undefined)    ? Boolean(target[propertyPrefix + "netEnabled"])    : false
    readonly property bool diskEnabled:   (target && target[propertyPrefix + "diskEnabled"] !== undefined)   ? Boolean(target[propertyPrefix + "diskEnabled"])   : false
    readonly property bool fanEnabled:    (target && target[propertyPrefix + "fanEnabled"] !== undefined)    ? Boolean(target[propertyPrefix + "fanEnabled"])    : false
    readonly property bool uptimeEnabled: (target && target[propertyPrefix + "uptimeEnabled"] !== undefined) ? Boolean(target[propertyPrefix + "uptimeEnabled"]) : false

    readonly property var _enabledMap: ({
        cpu: cpuEnabled, ram: ramEnabled, swap: swapEnabled, temp: tempEnabled,
        gpu: gpuEnabled, bat: batEnabled, net: netEnabled, disk: diskEnabled,
        fan: fanEnabled, uptime: uptimeEnabled
    })

    function isGroupEnabled(group) {
        return _enabledMap[group] !== undefined ? _enabledMap[group] : false;
    }

    function setGroupEnabled(group, val) {
        var prop = propertyPrefix + group + "Enabled";
        if (target && target[prop] !== undefined) {
            target[prop] = Boolean(val);
        }
    }

    // Sub-metric settings
    readonly property string cpuSubMetrics:  (target && target[propertyPrefix + "cpuSubMetrics"])  || Defs.GROUPS.cpu.defaultSubMetrics
    readonly property string ramSubMetrics:  (target && target[propertyPrefix + "ramSubMetrics"])  || Defs.GROUPS.ram.defaultSubMetrics
    readonly property string swapSubMetrics: (target && target[propertyPrefix + "swapSubMetrics"]) || Defs.GROUPS.swap.defaultSubMetrics
    readonly property string gpuSubMetrics:  (target && target[propertyPrefix + "gpuSubMetrics"])  || Defs.GROUPS.gpu.defaultSubMetrics
    readonly property string batSubMetrics:  (target && target[propertyPrefix + "batSubMetrics"])  || Defs.GROUPS.bat.defaultSubMetrics
    readonly property string netSubMetrics:  (target && target[propertyPrefix + "netSubMetrics"])  || Defs.GROUPS.net.defaultSubMetrics
    readonly property string diskSubMetrics: (target && target[propertyPrefix + "diskSubMetrics"]) || Defs.GROUPS.disk.defaultSubMetrics

    readonly property var _subMetricsMap: ({
        cpu: cpuSubMetrics, ram: ramSubMetrics, swap: swapSubMetrics, gpu: gpuSubMetrics,
        bat: batSubMetrics, net: netSubMetrics, disk: diskSubMetrics
    })

    function getSubMetricsString(key) {
        if (_subMetricsMap[key] !== undefined) return _subMetricsMap[key];
        var grp = Defs.GROUPS[key];
        return grp ? (grp.defaultSubMetrics || "") : "";
    }

    function getSubMetrics(key) {
        var str = getSubMetricsString(key);
        if (!str) return [];
        return str.split(",").map(function(s){ return s.trim(); }).filter(function(s){ return s.length > 0; });
    }

    function setSubMetrics(key, values) {
        var str = Array.isArray(values) ? values.join(",") : String(values || "");
        var prop = propertyPrefix + key + "SubMetrics";
        if (target && target[prop] !== undefined) {
            target[prop] = str;
        }
    }

    function toggleSubMetric(key, subKey, enable) {
        var list = getSubMetrics(key);
        if (enable) {
            if (list.indexOf(subKey) < 0) list.push(subKey);
        } else {
            if (list.length <= 1) return;
            list = list.filter(function(s){ return s !== subKey; });
        }
        var grp = Defs.GROUPS[key];
        if (grp && grp.subs) {
            var canonical = grp.subs.map(function(s){ return s.key; });
            list.sort(function(a, b){ return canonical.indexOf(a) - canonical.indexOf(b); });
        }
        setSubMetrics(key, list);
    }

    // Visibility settings
    readonly property string cpuVisibility:    (target && target[propertyPrefix + "cpuVisibility"])    || "both"
    readonly property string ramVisibility:    (target && target[propertyPrefix + "ramVisibility"])    || "both"
    readonly property string swapVisibility:   (target && target[propertyPrefix + "swapVisibility"])   || "both"
    readonly property string tempVisibility:   (target && target[propertyPrefix + "tempVisibility"])   || "both"
    readonly property string gpuVisibility:    (target && target[propertyPrefix + "gpuVisibility"])    || "both"
    readonly property string batVisibility:    (target && target[propertyPrefix + "batVisibility"])    || "both"
    readonly property string netVisibility:    (target && target[propertyPrefix + "netVisibility"])    || "both"
    readonly property string diskVisibility:   (target && target[propertyPrefix + "diskVisibility"])   || "both"
    readonly property string fanVisibility:    (target && target[propertyPrefix + "fanVisibility"])    || "both"
    readonly property string uptimeVisibility: (target && target[propertyPrefix + "uptimeVisibility"]) || "both"

    readonly property var _visibilityMap: ({
        cpu: cpuVisibility, ram: ramVisibility, swap: swapVisibility, temp: tempVisibility,
        gpu: gpuVisibility, bat: batVisibility, net: netVisibility, disk: diskVisibility,
        fan: fanVisibility, uptime: uptimeVisibility
    })

    function getVisibility(group) {
        return _visibilityMap[group] || "both";
    }

    function getGroupVisibility(group) {
        return getVisibility(group);
    }

    function setVisibility(group, val) {
        var prop = propertyPrefix + group + "Visibility";
        if (target && target[prop] !== undefined) {
            target[prop] = val;
        }
    }

    function isSubMetricEnabled(group, subKey, deviceId) {
        var str = getSubMetricsString(group);
        if (!str) return true;

        if (str.indexOf(":") >= 0) {
            if (deviceId) {
                var pairs = str.split("|");
                for (var i = 0; i < pairs.length; i++) {
                    var sep = pairs[i].indexOf(":");
                    if (sep > 0 && pairs[i].substring(0, sep) === deviceId) {
                        var subs = pairs[i].substring(sep + 1).split(",").map(function(s){ return s.trim(); });
                        return subs.indexOf(subKey) >= 0;
                    }
                }
            }
            var allPairs = str.split("|");
            for (var j = 0; j < allPairs.length; j++) {
                var pSep = allPairs[j].indexOf(":");
                var pSubs = (pSep > 0 ? allPairs[j].substring(pSep + 1) : allPairs[j]).split(",").map(function(s){ return s.trim(); });
                if (pSubs.indexOf(subKey) >= 0) return true;
            }
            return false;
        }

        return str.split(",").map(function(s){ return s.trim(); }).indexOf(subKey) >= 0;
    }

    function isMetricVisible(group, subKey, view, deviceId) {
        if (!isGroupEnabled(group)) return false;
        var vis = getGroupVisibility(group);
        if (vis !== "both" && vis !== view) return false;

        if (view === "widget" && group === "ram" && ramWidgetShowBoth) {
            if (subKey === "percentage" || subKey === "used") return true;
        }

        return isSubMetricEnabled(group, subKey, deviceId);
    }

    // Labels
    readonly property string cpuLabel:   (target && target[propertyPrefix + "cpuLabel"])   || "CPU"
    readonly property string ramLabel:   (target && target[propertyPrefix + "ramLabel"])   || "RAM"
    readonly property string swapLabel:  (target && target[propertyPrefix + "swapLabel"])  || "SWAP"
    readonly property string tempLabel:  (target && target[propertyPrefix + "tempLabel"])  || "System"
    readonly property string netLabel:   (target && target[propertyPrefix + "netLabel"])   || "NET"
    readonly property string diskLabel:  (target && target[propertyPrefix + "diskLabel"])  || "DSK"
    readonly property string fanLabel:   (target && target[propertyPrefix + "fanLabel"])   || "FAN"
    readonly property string gpuLabels:  (target && target[propertyPrefix + "gpuLabels"])  || ""
    readonly property string diskLabels: (target && target[propertyPrefix + "diskLabels"]) || ""
    readonly property string fanLabels:  (target && target[propertyPrefix + "fanLabels"])  || ""

    readonly property var _labelMap: ({
        cpu: cpuLabel, ram: ramLabel, swap: swapLabel, temp: tempLabel,
        net: netLabel, disk: diskLabel, fan: fanLabel
    })

    function getGroupLabel(group) {
        if (_labelMap[group] !== undefined) return _labelMap[group];
        var grp = Defs.GROUPS[group];
        return grp ? grp.defaultLabel : group.toUpperCase();
    }

    function setGroupLabel(group, val) {
        var prop = propertyPrefix + group + "Label";
        if (target && target[prop] !== undefined) {
            target[prop] = val;
        }
    }

    // Icons
    readonly property string cpuIcon:     resolveIcon((target && target[propertyPrefix + "cpuIcon"])     || "am-cpu-symbolic")
    readonly property string ramIcon:     resolveIcon((target && target[propertyPrefix + "ramIcon"])     || "nvidia-ram-symbolic")
    readonly property string swapIcon:    resolveIcon((target && target[propertyPrefix + "swapIcon"])    || "nvidia-ram-symbolic")
    readonly property string tempIcon:    resolveIcon((target && target[propertyPrefix + "tempIcon"])    || "temperature-normal")
    readonly property string gpuIcon:     resolveIcon((target && target[propertyPrefix + "gpuIcon"])     || "gpu-symbolic")
    readonly property string batteryIcon: resolveIcon((target && target[propertyPrefix + "batteryIcon"]) || "battery-good")
    readonly property string powerIcon:   resolveIcon((target && target[propertyPrefix + "powerIcon"])   || "battery-charging-60")
    readonly property string networkIcon: resolveIcon((target && target[propertyPrefix + "networkIcon"]) || "network-wireless")
    readonly property string diskIcon:    resolveIcon((target && target[propertyPrefix + "diskIcon"])    || "am-disk-utility-symbolic")
    readonly property string fanIcon:     resolveIcon((target && target[propertyPrefix + "fanIcon"])     || "am-fan-symbolic")
    readonly property string uptimeIcon:  resolveIcon((target && target[propertyPrefix + "uptimeIcon"])  || "clock")

    readonly property var _iconMap: ({
        cpu: cpuIcon, ram: ramIcon, swap: swapIcon, temp: tempIcon, gpu: gpuIcon,
        bat: batteryIcon, net: networkIcon, disk: diskIcon, fan: fanIcon, uptime: uptimeIcon
    })

    function getGroupIcon(group) {
        return _iconMap[group] || "";
    }

    // Generic group descriptor
    function getGroup(key) {
        var grp = Defs.GROUPS[key] || {};
        return {
            id: key,
            name: grp.name || grp.defaultLabel || key,
            defaultLabel: grp.defaultLabel || key.toUpperCase(),
            label: getGroupLabel(key),
            icon: getGroupIcon(key),
            enabled: isGroupEnabled(key),
            visibility: getVisibility(key),
            subMetrics: getSubMetrics(key),
            subs: grp.subs || [],
            hasSubs: Boolean(grp.subs && grp.subs.length > 0)
        };
    }

    function setGroup(key, patch) {
        if (!patch || typeof patch !== "object") return;
        if (patch.enabled !== undefined) setGroupEnabled(key, patch.enabled);
        if (patch.visibility !== undefined) setVisibility(key, patch.visibility);
        if (patch.label !== undefined) setGroupLabel(key, patch.label);
        if (patch.subMetrics !== undefined) setSubMetrics(key, patch.subMetrics);
    }

    // Threshold colors
    readonly property bool enableThresholdColors: Boolean(target && target[propertyPrefix + "enableThresholdColors"])
    readonly property string warningColor:        (target && target[propertyPrefix + "warningColor"])  || "#e5a50a"
    readonly property string criticalColor:       (target && target[propertyPrefix + "criticalColor"]) || "#da4453"

    readonly property int cpuWarningThreshold:      (target && target[propertyPrefix + "cpuWarningThreshold"])      || 70
    readonly property int cpuCriticalThreshold:     (target && target[propertyPrefix + "cpuCriticalThreshold"])     || 90
    readonly property int tempWarningThreshold:     (target && target[propertyPrefix + "tempWarningThreshold"])     || 60
    readonly property int tempCriticalThreshold:    (target && target[propertyPrefix + "tempCriticalThreshold"])    || 85
    readonly property int systemWarningThreshold:   (target && target[propertyPrefix + "systemWarningThreshold"])   || 60
    readonly property int systemCriticalThreshold:  (target && target[propertyPrefix + "systemCriticalThreshold"])  || 85
    readonly property int ramWarningThreshold:      (target && target[propertyPrefix + "ramWarningThreshold"])      || 70
    readonly property int ramCriticalThreshold:     (target && target[propertyPrefix + "ramCriticalThreshold"])     || 90
    readonly property int swapWarningThreshold:     (target && target[propertyPrefix + "swapWarningThreshold"])     || 70
    readonly property int swapCriticalThreshold:    (target && target[propertyPrefix + "swapCriticalThreshold"])    || 90
    readonly property int ramTempWarningThreshold:  (target && target[propertyPrefix + "ramTempWarningThreshold"])  || 60
    readonly property int ramTempCriticalThreshold: (target && target[propertyPrefix + "ramTempCriticalThreshold"]) || 85
    readonly property int gpuWarningThreshold:      (target && target[propertyPrefix + "gpuWarningThreshold"])      || 70
    readonly property int gpuCriticalThreshold:     (target && target[propertyPrefix + "gpuCriticalThreshold"])     || 90
    readonly property int gpuTempWarningThreshold:  (target && target[propertyPrefix + "gpuTempWarningThreshold"])  || 60
    readonly property int gpuTempCriticalThreshold: (target && target[propertyPrefix + "gpuTempCriticalThreshold"]) || 85
    readonly property int batteryWarningThreshold:  (target && target[propertyPrefix + "batteryWarningThreshold"])  || 30
    readonly property int batteryCriticalThreshold: (target && target[propertyPrefix + "batteryCriticalThreshold"]) || 15
    readonly property int diskTempWarningThreshold: (target && target[propertyPrefix + "diskTempWarningThreshold"]) || 45
    readonly property int diskTempCriticalThreshold: (target && target[propertyPrefix + "diskTempCriticalThreshold"]) || 60

    function getWarningThreshold(key) {
        var prop = propertyPrefix + key + "WarningThreshold";
        var val = target ? target[prop] : undefined;
        return val !== undefined ? val : 70;
    }

    function getCriticalThreshold(key) {
        var prop = propertyPrefix + key + "CriticalThreshold";
        var val = target ? target[prop] : undefined;
        return val !== undefined ? val : 90;
    }

    // Units & hardware preferences
    readonly property int updateInterval:         (target && target[propertyPrefix + "updateInterval"])    || 2000
    readonly property string tempUnit:            (target && target[propertyPrefix + "tempUnit"])          || "C"
    readonly property string networkUnit:         (target && target[propertyPrefix + "networkUnit"])       || "bytes"
    readonly property string fanUnit:             (target && target[propertyPrefix + "fanUnit"])           || "rpm"
    readonly property int fanMaxRpm:              (target && target[propertyPrefix + "fanMaxRpm"])         || 2000
    readonly property bool ramWidgetShowBoth:     Boolean(target && target[propertyPrefix + "ramWidgetShowBoth"])
    readonly property string batteryDevice:       (target && target[propertyPrefix + "batteryDevice"])     || "auto"
    readonly property string networkInterface:    (target && target[propertyPrefix + "networkInterface"])  || "auto"
    readonly property bool showNetworkIp:         Boolean(target && target[propertyPrefix + "showNetworkIp"])
    readonly property string gpuSelection:        (target && target[propertyPrefix + "gpuSelection"])      || ""

    // Order
    readonly property string metricOrder: (target && target[propertyPrefix + "metricOrder"]) || "cpu,ram,temp,gpu,bat,net,disk,fan,uptime"
    readonly property var orderedKeys: {
        var all = Defs.ALL_GROUP_KEYS;
        var keys = metricOrder.split(",").map(function(k){ return k.trim(); }).filter(function(k){ return k.length > 0 && all.indexOf(k) >= 0; });
        for (var i = 0; i < all.length; i++) {
            if (keys.indexOf(all[i]) === -1) keys.push(all[i]);
        }
        return keys;
    }

    function moveMetric(fromIndex, toIndex) {
        var keys = orderedKeys.slice();
        if (fromIndex < 0 || fromIndex >= keys.length || toIndex < 0 || toIndex >= keys.length) return;
        var item = keys.splice(fromIndex, 1)[0];
        keys.splice(toIndex, 0, item);
        var prop = propertyPrefix + "metricOrder";
        if (target && target[prop] !== undefined) {
            target[prop] = keys.join(",");
        }
    }

    // Isolated device-specific configuration helpers: GPU
    function parseGpuLabels() {
        var str = gpuLabels;
        var result = {};
        if (!str) return result;
        str.split("|").forEach(function(pair) {
            var sep = pair.indexOf(":");
            if (sep > 0) result[pair.substring(0, sep)] = pair.substring(sep + 1);
        });
        return result;
    }

    function saveGpuLabel(gpuId, label) {
        var labels = parseGpuLabels();
        var trimmed = (label || "").trim();
        if (trimmed.length > 0) labels[gpuId] = trimmed;
        else delete labels[gpuId];
        var parts = [];
        for (var id in labels) parts.push(id + ":" + labels[id]);
        var prop = propertyPrefix + "gpuLabels";
        if (target && target[prop] !== undefined) {
            target[prop] = parts.join("|");
        }
    }

    function isGpuSelected(gpuId) {
        if (!gpuSelection || gpuSelection === "") return true;
        if (gpuSelection === "none") return false;
        return gpuSelection.split(",").indexOf(gpuId) >= 0;
    }

    function setGpuSelected(gpuId, checked, allGpuIds) {
        var ids;
        if (!gpuSelection || gpuSelection === "") {
            ids = (allGpuIds || []).slice();
        } else if (gpuSelection === "none") {
            ids = [];
        } else {
            ids = gpuSelection.split(",").filter(function(s){ return s.length > 0; });
        }
        if (checked) {
            if (ids.indexOf(gpuId) < 0) ids.push(gpuId);
        } else {
            ids = ids.filter(function(id){ return id !== gpuId; });
        }
        var all = allGpuIds || [];
        var allSelected = all.length > 0 && all.every(function(id){ return ids.indexOf(id) >= 0; });
        var val = "";
        if (allSelected)           val = "";
        else if (ids.length === 0) val = "none";
        else                       val = ids.join(",");

        var prop = propertyPrefix + "gpuSelection";
        if (target && target[prop] !== undefined) {
            target[prop] = val;
        }
    }

    function parseGpuSubMetricsMap() {
        var str = gpuSubMetrics;
        var result = {};
        if (!str) return result;
        if (str.indexOf(":") >= 0) {
            str.split("|").forEach(function(pair) {
                var sep = pair.indexOf(":");
                if (sep > 0) {
                    var gid = pair.substring(0, sep);
                    var subs = pair.substring(sep + 1).split(",").map(function(s){ return s.trim(); }).filter(function(s){ return s.length > 0; });
                    result[gid] = subs;
                }
            });
        }
        return result;
    }

    function getGpuSubMetrics(gpuId) {
        var map = parseGpuSubMetricsMap();
        if (map[gpuId] && map[gpuId].length > 0) {
            return map[gpuId];
        }
        if (gpuSubMetrics && gpuSubMetrics.indexOf(":") < 0) {
            return gpuSubMetrics.split(",").map(function(s){ return s.trim(); }).filter(function(s){ return s.length > 0; });
        }
        return Defs.GROUPS.gpu.defaultSubMetrics.split(",").map(function(s){ return s.trim(); }).filter(function(s){ return s.length > 0; });
    }

    function toggleGpuSubMetric(gpuId, subKey, checked, allGpuIds) {
        var map = parseGpuSubMetricsMap();
        var all = allGpuIds || [gpuId];
        for (var i = 0; i < all.length; i++) {
            var gid = all[i];
            if (!map[gid]) {
                map[gid] = getGpuSubMetrics(gid);
            }
        }
        var subs = map[gpuId] ? map[gpuId].slice() : getGpuSubMetrics(gpuId);
        if (checked) {
            if (subs.indexOf(subKey) < 0) subs.push(subKey);
        } else {
            if (subs.length > 1) {
                subs = subs.filter(function(s){ return s !== subKey; });
            }
        }
        map[gpuId] = subs;

        var parts = [];
        for (var id in map) {
            parts.push(id + ":" + map[id].join(","));
        }
        var prop = propertyPrefix + "gpuSubMetrics";
        if (target && target[prop] !== undefined) {
            target[prop] = parts.join("|");
        }
    }

    // Isolated device-specific configuration helpers: Disk
    function parseDiskLabels() {
        var str = diskLabels;
        var result = {};
        if (!str) return result;
        str.split("|").forEach(function(pair) {
            var sep = pair.indexOf(":");
            if (sep > 0) result[pair.substring(0, sep)] = pair.substring(sep + 1);
        });
        return result;
    }

    function saveDiskLabel(diskId, label) {
        var labels = parseDiskLabels();
        var trimmed = (label || "").trim();
        if (trimmed.length > 0) labels[diskId] = trimmed;
        else delete labels[diskId];
        var parts = [];
        for (var id in labels) parts.push(id + ":" + labels[id]);
        var prop = propertyPrefix + "diskLabels";
        if (target && target[prop] !== undefined) {
            target[prop] = parts.join("|");
        }
    }

    // Isolated device-specific configuration helpers: Fan
    function parseFanLabels() {
        var str = fanLabels;
        var result = Object.create(null);
        if (!str) return result;
        str.split("|").forEach(function(pair) {
            var sep = pair.indexOf(":");
            if (sep > 0) result[pair.substring(0, sep)] = pair.substring(sep + 1);
        });
        return result;
    }

    function saveFanLabel(fanId, label) {
        var labels = parseFanLabels();
        var trimmed = (label || "").replace(/\|/g, "").trim();
        if (trimmed.length > 0) labels[fanId] = trimmed;
        else delete labels[fanId];
        var parts = [];
        for (var id in labels) parts.push(id + ":" + labels[id]);
        var prop = propertyPrefix + "fanLabels";
        if (target && target[prop] !== undefined) {
            target[prop] = parts.join("|");
        }
    }
}
