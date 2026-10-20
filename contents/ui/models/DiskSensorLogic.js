.pragma library

function parseSysfsOutput(rawOutput, availableSensors) {
    if (!rawOutput) return {};
    var sensors = availableSensors || [];
    var map = {};
    var lines = String(rawOutput).split("\n");

    for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim();
        if (!line) continue;
        var parts = line.split(":");
        if (parts.length < 3) continue;

        var blockName = parts[0].trim();
        var hardwareName = parts[1].trim();
        var hardwarePath = parts.slice(2).join(":").trim();
        var adapterPrefix = "";

        if (hardwareName === "nvme") {
            var pciMatches = hardwarePath.match(/[0-9a-fA-F]{4}:([0-9a-fA-F]{2}):([0-9a-fA-F]{2})\.([0-9a-fA-F])/g);
            if (pciMatches && pciMatches.length > 0) {
                var lastPci = pciMatches[pciMatches.length - 1];
                var pci = lastPci.match(/([0-9a-fA-F]{2}):([0-9a-fA-F]{2})\.([0-9a-fA-F])/);
                if (pci) adapterPrefix = "lmsensors/nvme-pci-" + (pci[1] + pci[2]).toLowerCase();
            }
        } else if (hardwareName === "drivetemp") {
            var scsi = hardwarePath.match(/host(\d+)\/target\d+:\d+:(\d+)\/(\d+):(\d+):(\d+):(\d+)/);
            if (scsi) {
                adapterPrefix = "lmsensors/drivetemp-scsi-" + scsi[1] + "-" + scsi[2];
            } else {
                var scsiDevice = hardwarePath.match(/(\d+):(\d+):(\d+):(\d+)$/);
                if (scsiDevice) adapterPrefix = "lmsensors/drivetemp-scsi-" + scsiDevice[1] + "-" + scsiDevice[3];
            }
        }

        if (!adapterPrefix) continue;
        var preferredSensor = adapterPrefix + "/temp1";
        if (sensors.length === 0 || sensors.indexOf(preferredSensor) >= 0) {
            map[blockName] = preferredSensor;
            continue;
        }
        for (var sensorIndex = 0; sensorIndex < sensors.length; sensorIndex++) {
            if (sensors[sensorIndex].indexOf(adapterPrefix) === 0) {
                map[blockName] = sensors[sensorIndex];
                break;
            }
        }
    }
    return map;
}

function resolveTemperatureSensor(diskId, sysfsMap, sensorExists) {
    if (!diskId) return "";
    var directId = "disk/" + diskId + "/temperature";
    if (sensorExists && sensorExists(directId)) return directId;
    return sysfsMap && sysfsMap[diskId] ? sysfsMap[diskId] : "";
}
