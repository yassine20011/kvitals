.pragma library

// buildPopupGroups groups catalogue metrics into standard GNOME Vitals categories:
// Temperature, Fan, Memory, Processor, System, Network, Storage, GPU.
function buildPopupGroups(metricsList, orderedKeys) {
    if (!metricsList || metricsList.length === 0) return [];
    var available = metricsList.filter(function(m) {
        return m.status !== "unavailable";
    });

    var map = {};
    for (var i = 0; i < available.length; i++) {
        map[available[i].id] = available[i];
    }

    var categories = [];

    // 1. Temperature (all temperature sensors across devices)
    var tempMetrics = available.filter(function(m) {
        return m.subKey === "temp" || m.group === "temp";
    }).map(function(m) {
        return Object.assign({}, m, {
            icon: "temperature-symbolic"
        });
    });
    if (tempMetrics.length > 0) {
        var tempAgg = map["temp/system"] || map["cpu/temp"] || tempMetrics[0];
        categories.push({
            key: "temperature",
            groupLabel: "Temperature",
            icon: "temperature-symbolic",
            aggregateValue: tempAgg ? tempAgg.displayValue : "",
            aggregateColor: tempAgg ? tempAgg.color : "",
            sections: [
                {
                    sectionLabel: "",
                    metrics: tempMetrics
                }
            ]
        });
    }

    // 2. Fan
    var fanMetrics = available.filter(function(m) { return m.group === "fan"; });
    if (fanMetrics.length > 0) {
        categories.push({
            key: "fan",
            groupLabel: "Fan",
            icon: fanMetrics[0].icon || "fan-symbolic",
            aggregateValue: fanMetrics[0].displayValue,
            aggregateColor: fanMetrics[0].color,
            sections: [
                {
                    sectionLabel: "",
                    metrics: fanMetrics
                }
            ]
        });
    }

    // 3. Memory (RAM + Swap)
    var ramMetrics = available.filter(function(m) { return m.group === "ram" && m.subKey !== "temp"; });
    var swapMetrics = available.filter(function(m) { return m.group === "swap"; });
    if (ramMetrics.length > 0 || swapMetrics.length > 0) {
        var ramPct = map["ram/percentage"];
        var memSections = [];
        if (ramMetrics.length > 0 && swapMetrics.length > 0) {
            memSections.push({ sectionLabel: "RAM", metrics: ramMetrics });
            memSections.push({ sectionLabel: "Swap", metrics: swapMetrics });
        } else {
            memSections.push({ sectionLabel: "", metrics: ramMetrics.concat(swapMetrics) });
        }

        categories.push({
            key: "memory",
            groupLabel: "Memory",
            icon: "memory-symbolic",
            aggregateValue: ramPct ? ramPct.displayValue : (ramMetrics[0] ? ramMetrics[0].displayValue : ""),
            aggregateColor: ramPct ? ramPct.color : (ramMetrics[0] ? ramMetrics[0].color : ""),
            sections: memSections
        });
    }

    // 4. Processor (CPU)
    var cpuMetrics = available.filter(function(m) { return m.group === "cpu" && m.subKey !== "temp"; });
    if (cpuMetrics.length > 0) {
        var cpuUsage = map["cpu/usage"] || cpuMetrics[0];
        var coreMetrics = cpuMetrics.filter(function(m) { return m.subKey === "core"; });
        var nonCoreMetrics = cpuMetrics.filter(function(m) { return m.subKey !== "core"; });

        var cpuSections = [];
        if (coreMetrics.length > 0 && nonCoreMetrics.length > 0) {
            cpuSections.push({ sectionLabel: "", metrics: nonCoreMetrics });
            cpuSections.push({ sectionLabel: "Cores", metrics: coreMetrics });
        } else {
            cpuSections.push({ sectionLabel: "", metrics: cpuMetrics });
        }

        categories.push({
            key: "processor",
            groupLabel: "Processor",
            icon: "cpu-symbolic",
            aggregateValue: cpuUsage ? cpuUsage.displayValue : "",
            aggregateColor: cpuUsage ? cpuUsage.color : "",
            sections: cpuSections
        });
    }

    // 5. Battery (when present on laptops)
    var batMetrics = available.filter(function(m) { return m.group === "bat"; });
    if (batMetrics.length > 0) {
        var batPct = map["bat/percentage"] || batMetrics[0];
        categories.push({
            key: "battery",
            groupLabel: "Battery",
            icon: "battery-symbolic",
            aggregateValue: batPct ? batPct.displayValue : "",
            aggregateColor: batPct ? batPct.color : "",
            sections: [
                {
                    sectionLabel: "",
                    metrics: batMetrics
                }
            ]
        });
    }

    // 6. System (Uptime)
    var sysMetrics = available.filter(function(m) { return m.group === "uptime"; });
    if (sysMetrics.length > 0) {
        var uptimeMetric = map["uptime/uptime"] || sysMetrics[0];
        categories.push({
            key: "system",
            groupLabel: "System",
            icon: "system-symbolic",
            aggregateValue: uptimeMetric ? uptimeMetric.displayValue : "",
            aggregateColor: uptimeMetric ? uptimeMetric.color : "",
            sections: [
                {
                    sectionLabel: "",
                    metrics: sysMetrics
                }
            ]
        });
    }

    // 7. Network
    var netMetrics = available.filter(function(m) { return m.group === "net"; });
    if (netMetrics.length > 0) {
        var netDown = map["net/down"] || netMetrics[0];
        categories.push({
            key: "network",
            groupLabel: "Network",
            icon: "network-symbolic",
            aggregateValue: netDown ? netDown.displayValue : "",
            aggregateColor: netDown ? netDown.color : "",
            sections: [
                {
                    sectionLabel: "",
                    metrics: netMetrics
                }
            ]
        });
    }

    // 8. Storage (Disks)
    var diskMetrics = available.filter(function(m) { return m.group === "disk" && m.subKey !== "temp"; });
    if (diskMetrics.length > 0) {
        var diskDeviceIds = [];
        for (var di = 0; di < diskMetrics.length; di++) {
            var dev = diskMetrics[di].deviceId;
            if (dev && diskDeviceIds.indexOf(dev) === -1) diskDeviceIds.push(dev);
        }

        var diskSections = [];
        if (diskDeviceIds.length > 1) {
            var globalDiskItems = diskMetrics.filter(function(m) { return !m.deviceId; });
            if (globalDiskItems.length > 0) {
                diskSections.push({
                    sectionLabel: "Overall",
                    metrics: globalDiskItems
                });
            }
            for (var dIdx = 0; dIdx < diskDeviceIds.length; dIdx++) {
                var dId = diskDeviceIds[dIdx];
                var dItems = diskMetrics.filter(function(m) { return m.deviceId === dId; });
                var dLabel = dItems[0].deviceName || dItems[0].groupLabel || ("Disk " + (dIdx + 1));
                diskSections.push({
                    sectionLabel: dLabel,
                    metrics: dItems
                });
            }
        } else {
            diskSections.push({
                sectionLabel: "",
                metrics: diskMetrics
            });
        }

        var diskAgg = map["disk/usage"] || diskMetrics[0];
        categories.push({
            key: "storage",
            groupLabel: "Storage",
            icon: "storage-symbolic",
            aggregateValue: diskAgg ? diskAgg.displayValue : "",
            aggregateColor: diskAgg ? diskAgg.color : "",
            sections: diskSections
        });
    }

    // 8. GPU
    var gpuMetrics = available.filter(function(m) { return m.group === "gpu"; });
    if (gpuMetrics.length > 0) {
        var gpuDeviceIds = [];
        for (var gi = 0; gi < gpuMetrics.length; gi++) {
            var gDev = gpuMetrics[gi].deviceId;
            if (gDev && gpuDeviceIds.indexOf(gDev) === -1) gpuDeviceIds.push(gDev);
        }

        var gpuSections = [];
        if (gpuDeviceIds.length > 1) {
            for (var gIdx = 0; gIdx < gpuDeviceIds.length; gIdx++) {
                var gId = gpuDeviceIds[gIdx];
                var gItems = gpuMetrics.filter(function(m) { return m.deviceId === gId; });
                var gLabel = gItems[0].deviceName || gItems[0].groupLabel || ("GPU " + (gIdx + 1));
                gpuSections.push({
                    sectionLabel: gLabel,
                    metrics: gItems
                });
            }
        } else {
            gpuSections.push({
                sectionLabel: "",
                metrics: gpuMetrics
            });
        }

        var gpuUsage = gpuMetrics.filter(function(m){ return m.subKey === "usage"; })[0] || gpuMetrics[0];
        categories.push({
            key: "gpu",
            groupLabel: "GPU",
            icon: "gpu-symbolic",
            aggregateValue: gpuUsage ? gpuUsage.displayValue : "",
            aggregateColor: gpuUsage ? gpuUsage.color : "",
            sections: gpuSections
        });
    }

    return categories;
}

function _resolveSegmentLabel(metric, isTemp) {
    if (isTemp || metric.group === "fan" || metric.subKey === "core") return metric.subLabel || "";
    // For CPU, RAM, Swap, Battery, GPU, Network, Disk, value or icon is self-describing
    return "";
}

function _resolveSegmentIcon(metric) {
    if (metric.group === "net" || metric.group === "disk") {
        return metric.icon || "";
    }
    return "";
}

// buildCompactItems maps pinned metrics to compact panel items, optionally
// merging metrics of the same hardware device/family into multi-segment items.
function buildCompactItems(metricsList, pinnedList, mergeSameFamily) {
    if (!metricsList || metricsList.length === 0 || !pinnedList || pinnedList.length === 0) return [];
    if (mergeSameFamily === undefined) mergeSameFamily = true;

    var metricMap = {};
    for (var mIdx = 0; mIdx < metricsList.length; mIdx++) {
        var m = metricsList[mIdx];
        if (m.status === "ready") {
            metricMap[m.id] = m;
        }
    }

    var items = [];
    var groupIndexMap = {};

    for (var i = 0; i < pinnedList.length; i++) {
        var id = pinnedList[i];
        var metric = metricMap[id];
        if (!metric) continue;

        var isTemp = (metric.subKey === "temp" || metric.group === "temp");
        var groupKey = isTemp ? "temp" : (metric.deviceId ? (metric.group + ":" + metric.deviceId) : metric.group);

        if (mergeSameFamily && groupIndexMap[groupKey] !== undefined) {
            // Merge into existing group item
            var existingItem = items[groupIndexMap[groupKey]];
            if (!existingItem.segments) {
                var firstSegIcon = existingItem._firstSubIcon || "";
                existingItem.segments = [
                    {
                        value: existingItem.value,
                        color: existingItem.color,
                        label: existingItem._firstSubLabel || "",
                        icon: firstSegIcon,
                        key: existingItem._firstSubKey || ""
                    }
                ];
                existingItem.value = null;
                existingItem.label = existingItem._groupBaseLabel + ":";
                if (firstSegIcon) existingItem._segmentsHaveIcons = true;
            }
            var segIcon = _resolveSegmentIcon(metric);
            if (segIcon) existingItem._segmentsHaveIcons = true;
            existingItem.segments.push({
                value: metric.displayValue,
                color: metric.color,
                label: _resolveSegmentLabel(metric, isTemp),
                icon: segIcon,
                key: metric.subKey || metric.id
            });
        } else {
            // New group item
            var baseLabel = isTemp ? "TEMP" : (metric.groupLabel || metric.deviceName || metric.group.toUpperCase());
            var singleLabel = metric.label;
            var itemIcon = isTemp ? "temperature-symbolic" : metric.icon;
            var segIcon = _resolveSegmentIcon(metric);

            var newItem = {
                id: metric.id,
                icon: itemIcon,
                label: singleLabel + ":",
                value: metric.displayValue,
                color: metric.color,
                key: groupKey,
                segments: null,
                _segmentsHaveIcons: false,
                _groupBaseLabel: baseLabel,
                _firstSubLabel: _resolveSegmentLabel(metric, isTemp),
                _firstSubIcon: segIcon,
                _firstSubKey: metric.subKey || metric.id
            };
            if (mergeSameFamily) {
                groupIndexMap[groupKey] = items.length;
            }
            items.push(newItem);
        }
    }

    return items;
}
