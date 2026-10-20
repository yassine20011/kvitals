.pragma library

function buildInventory(sensorEntries, patterns) {
    var entries = sensorEntries || [];
    var ids = [];
    var sensors = [];
    var idSet = {};
    var gpuMap = {};
    var diskMap = {};
    var fanSet = {};
    var coreMap = {};
    var interfaceSet = {};
    var batterySet = {};
    var diskTempSet = {};

    for (var i = 0; i < entries.length; i++) {
        var entry = typeof entries[i] === "string" ? { id: entries[i], name: entries[i] } : entries[i];
        var sensorId = entry && entry.id;
        if (!sensorId || /[\(\)\*\?\+]/.test(sensorId)) continue;

        ids.push(sensorId);
        sensors.push({ id: sensorId, name: entry.name || "" });
        idSet[sensorId] = true;

        var match = null;
        if ((match = sensorId.match(patterns.GPU))) {
            gpuMap[match[1]] = true;
        } else if ((match = sensorId.match(patterns.DISK_READ))) {
            diskMap[match[1]] = true;
        } else if (patterns.FAN.test(sensorId)) {
            fanSet[sensorId] = true;
        } else if ((match = sensorId.match(patterns.CPU_CORE))) {
            coreMap[match[1]] = true;
        } else if ((match = sensorId.match(patterns.NETWORK_IFACE))) {
            if (match[1] !== "all" && match[1] !== "lo") interfaceSet[match[1]] = true;
        } else if ((match = sensorId.match(patterns.BATTERY))) {
            batterySet[match[1]] = true;
        } else if (patterns.DISK_TEMP.test(sensorId)) {
            diskTempSet[sensorId] = true;
        }
    }

    var gpuIds = Object.keys(gpuMap).sort();
    var diskIds = Object.keys(diskMap).sort();
    var fanIds = Object.keys(fanSet).sort();
    var coreIds = Object.keys(coreMap);
    var sortedCores = [];
    for (var coreIndex = 0; coreIndex < coreIds.length; coreIndex++) {
        var number = parseInt(coreIds[coreIndex].replace("cpu", ""), 10);
        sortedCores.push({ id: coreIds[coreIndex], number: isNaN(number) ? coreIndex : number });
    }
    sortedCores.sort(function(left, right) { return left.number - right.number; });

    return {
        allIds: ids,
        allSensors: sensors,
        idSet: idSet,
        gpus: gpuIds.map(function(id, index) { return { id: id, name: "GPU " + (index + 1) }; }),
        disks: diskIds.map(function(id, index) { return { id: id, name: "Disk " + (index + 1) }; }),
        fans: fanIds.map(function(id, index) { return { id: id, name: "Fan " + (index + 1) }; }),
        cpuCores: sortedCores.map(function(core) { return { id: core.id, number: core.number, name: "Core " + (core.number + 1) }; }),
        networkIfaces: ["auto"].concat(Object.keys(interfaceSet).sort()),
        batteries: Object.keys(batterySet).sort(),
        diskTemps: Object.keys(diskTempSet).sort()
    };
}
