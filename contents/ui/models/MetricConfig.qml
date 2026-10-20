import QtQuick
import org.kde.plasma.plasmoid
import "./MetricDefinitions.js" as Defs
import "./ConfigLogic.js" as ConfigLogic

QtObject {
    id: root

    property var target: Plasmoid.configuration
    property string propertyPrefix: ""

    // Icon fallback resolver
    function resolveIcon(name) {
        if (!name) return "configure";
        var str = String(name);
        if (Defs.isBundledIcon(str)) {
            return Qt.resolvedUrl("../../icons/" + str + ".svg");
        }
        return name;
    }

    // Pinned metrics on Plasma panel
    readonly property string pinnedMetrics: (target && target[propertyPrefix + "pinnedMetrics"] !== undefined)
        ? target[propertyPrefix + "pinnedMetrics"]
        : ConfigLogic.DEFAULT_PINNED_METRICS

    readonly property var pinnedList: {
        return ConfigLogic.parseCsv(pinnedMetrics);
    }

    readonly property var _pinnedSet: {
        var s = new Set();
        for (var i = 0; i < pinnedList.length; i++) {
            s.add(pinnedList[i]);
        }
        return s;
    }

    function isPinned(instanceId) {
        if (!instanceId) return false;
        return _pinnedSet.has(instanceId);
    }

    function togglePin(instanceId) {
        if (!instanceId) return;
        var prop = propertyPrefix + "pinnedMetrics";
        if (target && target[prop] !== undefined) {
            target[prop] = ConfigLogic.toggleCsvMembership(pinnedMetrics, instanceId, ConfigLogic.DEFAULT_PINNED_METRICS);
        }
    }

    function setPinned(instanceId, shouldPin) {
        if (!instanceId) return;
        var prop = propertyPrefix + "pinnedMetrics";
        if (target && target[prop] !== undefined) {
            target[prop] = ConfigLogic.setCsvMembership(pinnedMetrics, instanceId, shouldPin, ConfigLogic.DEFAULT_PINNED_METRICS);
        }
    }

    function movePinnedMetric(fromIndex, toIndex) {
        var prop = propertyPrefix + "pinnedMetrics";
        if (target && target[prop] !== undefined) {
            target[prop] = ConfigLogic.moveCsvItem(pinnedMetrics, fromIndex, toIndex, ConfigLogic.DEFAULT_PINNED_METRICS);
        }
    }

    // Dynamic Hardware Group Labels
    function parseGpuLabels() {
        return _parseJsonSafe((target && target[propertyPrefix + "gpuLabels"]) || "{}");
    }

    function saveGpuLabel(deviceId, label) {
        var map = parseGpuLabels();
        map[deviceId] = label;
        var prop = propertyPrefix + "gpuLabels";
        if (target && target[prop] !== undefined) {
            target[prop] = JSON.stringify(map);
        }
    }

    function isGpuSelected(deviceId) {
        var raw = (target && target[propertyPrefix + "gpuSelection"]) || "";
        return ConfigLogic.isSelectionEnabled(raw, deviceId);
    }

    function setGpuSelected(deviceId, enabled, allDiscoveredGpuIds) {
        var raw = (target && target[propertyPrefix + "gpuSelection"]) || "";
        var prop = propertyPrefix + "gpuSelection";
        if (target && target[prop] !== undefined) {
            target[prop] = ConfigLogic.updateSelection(raw, deviceId, enabled, allDiscoveredGpuIds);
        }
    }

    function parseDiskLabels() {
        return _parseJsonSafe((target && target[propertyPrefix + "diskLabels"]) || "{}");
    }

    function saveDiskLabel(deviceId, label) {
        var map = parseDiskLabels();
        map[deviceId] = label;
        var prop = propertyPrefix + "diskLabels";
        if (target && target[prop] !== undefined) {
            target[prop] = JSON.stringify(map);
        }
    }

    function parseFanLabels() {
        return _parseJsonSafe((target && target[propertyPrefix + "fanLabels"]) || "{}");
    }

    function saveFanLabel(deviceId, label) {
        var map = parseFanLabels();
        map[deviceId] = label;
        var prop = propertyPrefix + "fanLabels";
        if (target && target[prop] !== undefined) {
            target[prop] = JSON.stringify(map);
        }
    }

    function _parseJsonSafe(str) {
        return ConfigLogic.parseJsonMap(str);
    }

    // Static Group Labels
    readonly property string cpuLabel:  (target && target[propertyPrefix + "cpuLabel"])  || "CPU"
    readonly property string ramLabel:  (target && target[propertyPrefix + "ramLabel"])  || "RAM"
    readonly property string swapLabel: (target && target[propertyPrefix + "swapLabel"]) || "SWAP"
    readonly property string tempLabel: (target && target[propertyPrefix + "tempLabel"]) || "System"
    readonly property string netLabel:  (target && target[propertyPrefix + "netLabel"])  || "NET"
    readonly property string diskLabel: (target && target[propertyPrefix + "diskLabel"]) || "DSK"
    readonly property string fanLabel:  (target && target[propertyPrefix + "fanLabel"])  || "FAN"
    readonly property string batLabel:  (target && target[propertyPrefix + "batLabel"])  || "BAT"

    readonly property var _labelMap: ({
        cpu: cpuLabel, ram: ramLabel, swap: swapLabel, temp: tempLabel,
        net: netLabel, disk: diskLabel, fan: fanLabel, bat: batLabel, uptime: "Uptime"
    })

    function getGroupLabel(group) {
        return _labelMap[group] || (group ? group.toUpperCase() : "");
    }

    function setGroupLabel(group, val) {
        var prop = propertyPrefix + group + "Label";
        if (target && target[prop] !== undefined) {
            target[prop] = val;
        }
    }

    // Icons
    readonly property string cpuIcon:     resolveIcon((target && target[propertyPrefix + "cpuIcon"])     || "cpu-symbolic")
    readonly property string ramIcon:     resolveIcon((target && target[propertyPrefix + "ramIcon"])     || "memory-symbolic")
    readonly property string swapIcon:    resolveIcon((target && target[propertyPrefix + "swapIcon"])    || "memory-symbolic")
    readonly property string tempIcon:    resolveIcon((target && target[propertyPrefix + "tempIcon"])    || "temperature-symbolic")
    readonly property string gpuIcon:     resolveIcon((target && target[propertyPrefix + "gpuIcon"])     || "gpu-symbolic")
    readonly property string batteryIcon: resolveIcon((target && target[propertyPrefix + "batteryIcon"]) || "battery-symbolic")
    readonly property string powerIcon:   resolveIcon((target && target[propertyPrefix + "powerIcon"])   || "voltage-symbolic")
    readonly property string networkIcon: resolveIcon((target && target[propertyPrefix + "networkIcon"]) || "network-symbolic")
    readonly property string diskIcon:    resolveIcon((target && target[propertyPrefix + "diskIcon"])    || "storage-symbolic")
    readonly property string fanIcon:     resolveIcon((target && target[propertyPrefix + "fanIcon"])     || "fan-symbolic")
    readonly property string uptimeIcon:  resolveIcon((target && target[propertyPrefix + "uptimeIcon"])  || "system-symbolic")

    readonly property var _iconMap: ({
        cpu: cpuIcon, ram: ramIcon, swap: swapIcon, temp: tempIcon, gpu: gpuIcon,
        bat: batteryIcon, net: networkIcon, disk: diskIcon, fan: fanIcon, uptime: uptimeIcon
    })

    function getGroupIcon(group) {
        return _iconMap[group] || "";
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
    readonly property int diskWarningThreshold:     (target && target[propertyPrefix + "diskWarningThreshold"])     || 80
    readonly property int diskCriticalThreshold:    (target && target[propertyPrefix + "diskCriticalThreshold"])    || 90
    readonly property int diskTempWarningThreshold: (target && target[propertyPrefix + "diskTempWarningThreshold"]) || 45
    readonly property int diskTempCriticalThreshold: (target && target[propertyPrefix + "diskTempCriticalThreshold"]) || 60

    function getWarningThreshold(key) {
        var prop = propertyPrefix + key + "WarningThreshold";
        var val = target ? target[prop] : undefined;
        if (val !== undefined) return val;
        var direct = root[key + "WarningThreshold"];
        return direct !== undefined ? direct : 70;
    }

    function getCriticalThreshold(key) {
        var prop = propertyPrefix + key + "CriticalThreshold";
        var val = target ? target[prop] : undefined;
        if (val !== undefined) return val;
        var direct = root[key + "CriticalThreshold"];
        return direct !== undefined ? direct : 90;
    }

    // Units & hardware preferences
    readonly property int updateInterval:         (target && target[propertyPrefix + "updateInterval"])    || 2000
    readonly property string tempUnit:            (target && target[propertyPrefix + "tempUnit"])          || "C"
    readonly property string networkUnit:         (target && target[propertyPrefix + "networkUnit"])       || "bytes"
    readonly property string fanUnit:             (target && target[propertyPrefix + "fanUnit"])           || "rpm"
    readonly property int fanMaxRpm:              (target && target[propertyPrefix + "fanMaxRpm"])         || 2000
    readonly property string batteryDevice:       (target && target[propertyPrefix + "batteryDevice"])     || "auto"
    readonly property string networkInterface:    (target && target[propertyPrefix + "networkInterface"])  || "auto"
    readonly property bool showNetworkIp:         Boolean(target && target[propertyPrefix + "showNetworkIp"])
    readonly property string gpuSelection:        (target && target[propertyPrefix + "gpuSelection"])      || ""
    readonly property string gpuLabels:           (target && target[propertyPrefix + "gpuLabels"])          || ""
    readonly property string diskLabels:          (target && target[propertyPrefix + "diskLabels"])         || ""
    readonly property string fanLabels:           (target && target[propertyPrefix + "fanLabels"])          || ""
    readonly property string gpuSubMetrics:       (target && target[propertyPrefix + "gpuSubMetrics"])      || "usage,vram,temp"
    readonly property string diskSubMetrics:      (target && target[propertyPrefix + "diskSubMetrics"])     || "read,write"

    // Group order in popup catalogue
    readonly property string metricOrder: (target && target[propertyPrefix + "metricOrder"]) || ConfigLogic.DEFAULT_METRIC_ORDER
    readonly property var orderedKeys: {
        return ConfigLogic.normalizeOrder(metricOrder, Defs.ALL_GROUP_KEYS, ConfigLogic.DEFAULT_METRIC_ORDER);
    }

    function moveMetric(fromIndex, toIndex) {
        var prop = propertyPrefix + "metricOrder";
        if (target && target[prop] !== undefined) {
            target[prop] = ConfigLogic.moveCsvItem(orderedKeys.join(","), fromIndex, toIndex, ConfigLogic.DEFAULT_METRIC_ORDER);
        }
    }
}
