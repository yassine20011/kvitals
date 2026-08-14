import QtQuick
import org.kde.plasma.plasmoid
import "./MetricDefinitions.js" as Defs

QtObject {
    id: root

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

    // Category enablement
    readonly property bool cpuEnabled:    Plasmoid.configuration.cpuEnabled
    readonly property bool ramEnabled:    Plasmoid.configuration.ramEnabled
    readonly property bool tempEnabled:   Plasmoid.configuration.tempEnabled
    readonly property bool gpuEnabled:    Plasmoid.configuration.gpuEnabled
    readonly property bool batEnabled:    Plasmoid.configuration.batEnabled
    readonly property bool netEnabled:    Plasmoid.configuration.netEnabled
    readonly property bool diskEnabled:   Plasmoid.configuration.diskEnabled
    readonly property bool fanEnabled:    Plasmoid.configuration.fanEnabled
    readonly property bool uptimeEnabled: Plasmoid.configuration.uptimeEnabled

    function isGroupEnabled(group) {
        switch (group) {
        case "cpu":    return cpuEnabled;
        case "ram":    return ramEnabled;
        case "temp":   return tempEnabled;
        case "gpu":    return gpuEnabled;
        case "bat":    return batEnabled;
        case "net":    return netEnabled;
        case "disk":   return diskEnabled;
        case "fan":    return fanEnabled;
        case "uptime": return uptimeEnabled;
        default:       return false;
        }
    }

    // Sub-metric comma-separated lists
    readonly property string cpuSubMetrics:  Plasmoid.configuration.cpuSubMetrics  || "usage,freq,temp"
    readonly property string ramSubMetrics:  Plasmoid.configuration.ramSubMetrics  || "percentage"
    readonly property string gpuSubMetrics:  Plasmoid.configuration.gpuSubMetrics  || "usage,vram,temp"
    readonly property string batSubMetrics:  Plasmoid.configuration.batSubMetrics  || "percentage,power"
    readonly property string netSubMetrics:  Plasmoid.configuration.netSubMetrics  || "down,up"
    readonly property string diskSubMetrics: Plasmoid.configuration.diskSubMetrics || "read,write"

    // Group visibility target (compact, widget, both)
    readonly property string cpuVisibility:    Plasmoid.configuration.cpuVisibility    || "both"
    readonly property string ramVisibility:    Plasmoid.configuration.ramVisibility    || "both"
    readonly property string tempVisibility:   Plasmoid.configuration.tempVisibility   || "both"
    readonly property string gpuVisibility:    Plasmoid.configuration.gpuVisibility    || "both"
    readonly property string batVisibility:    Plasmoid.configuration.batVisibility    || "both"
    readonly property string netVisibility:    Plasmoid.configuration.netVisibility    || "both"
    readonly property string diskVisibility:   Plasmoid.configuration.diskVisibility   || "both"
    readonly property string fanVisibility:    Plasmoid.configuration.fanVisibility    || "both"
    readonly property string uptimeVisibility: Plasmoid.configuration.uptimeVisibility || "both"

    function getGroupVisibility(group) {
        switch (group) {
        case "cpu":    return cpuVisibility;
        case "ram":    return ramVisibility;
        case "temp":   return tempVisibility;
        case "gpu":    return gpuVisibility;
        case "bat":    return batVisibility;
        case "net":    return netVisibility;
        case "disk":   return diskVisibility;
        case "fan":    return fanVisibility;
        case "uptime": return uptimeVisibility;
        default:       return "both";
        }
    }

    function isSubMetricEnabled(group, subKey) {
        var str = "";
        switch (group) {
        case "cpu":  str = cpuSubMetrics; break;
        case "ram":  str = ramSubMetrics; break;
        case "gpu":  str = gpuSubMetrics; break;
        case "bat":  str = batSubMetrics; break;
        case "net":  str = netSubMetrics; break;
        case "disk": str = diskSubMetrics; break;
        case "temp": return true;
        case "fan": return true;
        case "uptime": return true;
        default: return true;
        }
        return str.split(",").map(function(s){ return s.trim(); }).indexOf(subKey) >= 0;
    }

    function isMetricVisible(group, subKey, view) {
        if (!isGroupEnabled(group)) return false;
        var vis = getGroupVisibility(group);
        if (vis !== "both" && vis !== view) return false;
        
        // RAM popup override for showing both percentage and used
        if (view === "widget" && group === "ram" && ramWidgetShowBoth) {
            if (subKey === "percentage" || subKey === "used") return true;
        }

        return isSubMetricEnabled(group, subKey);
    }

    // Labels
    readonly property string cpuLabel:  Plasmoid.configuration.cpuLabel  || "CPU"
    readonly property string ramLabel:  Plasmoid.configuration.ramLabel  || "RAM"
    readonly property string tempLabel: Plasmoid.configuration.tempLabel || "System"
    readonly property string netLabel:  Plasmoid.configuration.netLabel  || "NET"
    readonly property string diskLabel: Plasmoid.configuration.diskLabel || "DSK"
    readonly property string fanLabel:  Plasmoid.configuration.fanLabel  || "FAN"
    readonly property string gpuLabels: Plasmoid.configuration.gpuLabels || ""
    readonly property string diskLabels: Plasmoid.configuration.diskLabels || ""
    readonly property string fanLabels: Plasmoid.configuration.fanLabels || ""

    function getGroupLabel(group) {
        switch (group) {
        case "cpu":    return cpuLabel;
        case "ram":    return ramLabel;
        case "temp":   return tempLabel;
        case "gpu":    return "GPU";
        case "bat":    return "BAT";
        case "net":    return netLabel;
        case "disk":   return diskLabel;
        case "fan":    return fanLabel;
        case "uptime": return "UPTIME";
        default:       return group.toUpperCase();
        }
    }

    // Icons
    readonly property string cpuIcon:     resolveIcon(Plasmoid.configuration.cpuIcon || "am-cpu-symbolic")
    readonly property string ramIcon:     resolveIcon(Plasmoid.configuration.ramIcon || "nvidia-ram-symbolic")
    readonly property string tempIcon:    resolveIcon(Plasmoid.configuration.tempIcon || "temperature-normal")
    readonly property string gpuIcon:     resolveIcon(Plasmoid.configuration.gpuIcon || "gpu-symbolic")
    readonly property string batteryIcon: resolveIcon(Plasmoid.configuration.batteryIcon || "battery-good")
    readonly property string powerIcon:   resolveIcon(Plasmoid.configuration.powerIcon || "battery-charging-60")
    readonly property string networkIcon: resolveIcon(Plasmoid.configuration.networkIcon || "network-wireless")
    readonly property string diskIcon:    resolveIcon(Plasmoid.configuration.diskIcon || "am-disk-utility-symbolic")
    readonly property string fanIcon:     resolveIcon(Plasmoid.configuration.fanIcon || "am-fan-symbolic")
    readonly property string uptimeIcon:  resolveIcon(Plasmoid.configuration.uptimeIcon || "clock")

    function getGroupIcon(group) {
        switch (group) {
        case "cpu":    return cpuIcon;
        case "ram":    return ramIcon;
        case "temp":   return tempIcon;
        case "gpu":    return gpuIcon;
        case "bat":    return batteryIcon;
        case "net":    return networkIcon;
        case "disk":   return diskIcon;
        case "fan":    return fanIcon;
        case "uptime": return uptimeIcon;
        default:       return "";
        }
    }

    // Thresholds
    readonly property bool enableThresholdColors: Plasmoid.configuration.enableThresholdColors
    readonly property string warningColor:        Plasmoid.configuration.warningColor  || "#e5a50a"
    readonly property string criticalColor:       Plasmoid.configuration.criticalColor || "#da4453"

    readonly property int cpuWarningThreshold:      Plasmoid.configuration.cpuWarningThreshold      || 70
    readonly property int cpuCriticalThreshold:     Plasmoid.configuration.cpuCriticalThreshold     || 90
    readonly property int tempWarningThreshold:     Plasmoid.configuration.tempWarningThreshold     || 60
    readonly property int tempCriticalThreshold:    Plasmoid.configuration.tempCriticalThreshold    || 85
    readonly property int systemWarningThreshold:   Plasmoid.configuration.systemWarningThreshold   || 60
    readonly property int systemCriticalThreshold:  Plasmoid.configuration.systemCriticalThreshold  || 85
    readonly property int ramWarningThreshold:      Plasmoid.configuration.ramWarningThreshold      || 70
    readonly property int ramCriticalThreshold:     Plasmoid.configuration.ramCriticalThreshold     || 90
    readonly property int ramTempWarningThreshold:  Plasmoid.configuration.ramTempWarningThreshold  || 60
    readonly property int ramTempCriticalThreshold: Plasmoid.configuration.ramTempCriticalThreshold || 85
    readonly property int gpuWarningThreshold:      Plasmoid.configuration.gpuWarningThreshold      || 70
    readonly property int gpuCriticalThreshold:     Plasmoid.configuration.gpuCriticalThreshold     || 90
    readonly property int gpuTempWarningThreshold:  Plasmoid.configuration.gpuTempWarningThreshold  || 60
    readonly property int gpuTempCriticalThreshold: Plasmoid.configuration.gpuTempCriticalThreshold || 85
    readonly property int batteryWarningThreshold:  Plasmoid.configuration.batteryWarningThreshold  || 30
    readonly property int batteryCriticalThreshold: Plasmoid.configuration.batteryCriticalThreshold || 15
    readonly property int diskTempWarningThreshold: Plasmoid.configuration.diskTempWarningThreshold || 45
    readonly property int diskTempCriticalThreshold: Plasmoid.configuration.diskTempCriticalThreshold || 60

    function getWarningThreshold(key) {
        var val = root[key + "WarningThreshold"];
        return val !== undefined ? val : 70;
    }

    function getCriticalThreshold(key) {
        var val = root[key + "CriticalThreshold"];
        return val !== undefined ? val : 90;
    }

    // Units & hardware preferences
    readonly property int updateInterval:         Plasmoid.configuration.updateInterval    || 2000
    readonly property string tempUnit:            Plasmoid.configuration.tempUnit          || "C"
    readonly property string networkUnit:         Plasmoid.configuration.networkUnit       || "bytes"
    readonly property string fanUnit:             Plasmoid.configuration.fanUnit           || "rpm"
    readonly property int fanMaxRpm:              Plasmoid.configuration.fanMaxRpm         || 2000
    readonly property bool ramWidgetShowBoth:     Plasmoid.configuration.ramWidgetShowBoth || false
    readonly property string batteryDevice:       Plasmoid.configuration.batteryDevice     || "auto"
    readonly property string networkInterface:    Plasmoid.configuration.networkInterface  || "auto"
    readonly property bool showNetworkIp:         Plasmoid.configuration.showNetworkIp     || false
    readonly property string gpuSelection:        Plasmoid.configuration.gpuSelection      || ""

    // Ordering
    readonly property string metricOrder: Plasmoid.configuration.metricOrder || "cpu,ram,temp,gpu,bat,net,disk,fan,uptime"
    readonly property var orderedKeys: {
        var all = Defs.ALL_GROUP_KEYS;
        var keys = metricOrder.split(",").map(function(k){ return k.trim(); }).filter(function(k){ return k.length > 0 && all.indexOf(k) >= 0; });
        for (var i = 0; i < all.length; i++) {
            if (keys.indexOf(all[i]) === -1) keys.push(all[i]);
        }
        return keys;
    }
}
