import QtQuick
import org.kde.ksysguard.sensors as Sensors
import org.kde.kitemmodels as KItemModels
import org.kde.plasma.plasma5support as Plasma5Support

Item {
    id: root
    property bool _dbg: { console.warn("[KVitals] DiskSensors: constructing..."); return true; }

    property int updateInterval: 2000
    property bool enabled: true
    property string tempUnit: "C"
    property string networkUnit: "bytes"
    property string diskDevice: "auto"

    readonly property string _devicePath: {
        if (!diskDevice || diskDevice === "" || diskDevice === "auto")
            return "all";
        return diskDevice;
    }

    readonly property string diskReadValue:  Utils.formatRate(diskReadSensor.status  === Sensors.Sensor.Ready ? diskReadSensor.value  : NaN, networkUnit)
    readonly property string diskWriteValue: Utils.formatRate(diskWriteSensor.status === Sensors.Sensor.Ready ? diskWriteSensor.value : NaN, networkUnit)

    // Disk space usage (from KSysGuard)
    // Partition-based usage (from lsblk+df) — used when a specific device is selected
    property string selectedDiskDevice: ""
    property real summedPartitionUsed: 0
    property real summedPartitionTotal: 0

    readonly property string diskUsedValue: {
        if (selectedDiskDevice !== "" && summedPartitionTotal > 0)
            return Utils.formatBytes(summedPartitionUsed) + "G";
        if (diskUsedSensor.status === Sensors.Sensor.Ready)
            return Utils.formatBytes(diskUsedSensor.value) + "G";
        return "...";
    }
    readonly property string diskTotalValue: {
        if (selectedDiskDevice !== "" && summedPartitionTotal > 0)
            return Utils.formatBytes(summedPartitionTotal) + "G";
        if (diskTotalSensor.status === Sensors.Sensor.Ready)
            return Utils.formatBytes(diskTotalSensor.value) + "G";
        return "...";
    }

    // Highest temperature found across all discovered drive temp sensors
    readonly property real   diskTempNumber: _diskTempNum
    readonly property string diskTempValue:  isNaN(_diskTempNum) ? "" : Utils.formatTemp(_diskTempNum, tempUnit)

    property real _diskTempNum: NaN

    // I/O sensors 
    Sensors.Sensor {
        id: diskReadSensor
        sensorId: "disk/" + root._devicePath + "/read"
        updateRateLimit: root.updateInterval
        enabled: root.enabled
    }

    Sensors.Sensor {
        id: diskWriteSensor
        sensorId: "disk/" + root._devicePath + "/write"
        updateRateLimit: root.updateInterval
        enabled: root.enabled
    }

    Sensors.Sensor {
        id: diskUsedSensor
        sensorId: "disk/" + root._devicePath + "/used"
        updateRateLimit: root.updateInterval
        enabled: root.enabled
    }

    Sensors.Sensor {
        id: diskTotalSensor
        sensorId: "disk/" + root._devicePath + "/total"
        updateRateLimit: root.updateInterval
        enabled: root.enabled
    }

    // ── Partition usage via lsblk + df (for specific device) ────────────────

    Plasma5Support.DataSource {
        id: partitionUsageSource
        engine: "executable"

        onNewData: function(sourceName, data) {
            disconnectSource(sourceName);
            if (data["exit code"] !== 0) return;
            root.parsePartitionUsage(data["stdout"] || "");
        }

        function run(device) {
            connectSource("lsblk -b -J /dev/" + device + " 2>/dev/null && df -B1 /dev/" + device + "* 2>/dev/null");
        }
    }

    Timer {
        id: partitionUpdateTimer
        interval: root.updateInterval
        repeat: true
        running: root.selectedDiskDevice !== ""
        onTriggered: partitionUsageSource.run(root.selectedDiskDevice)
    }

    function parsePartitionUsage(output) {
        var totalSize = 0;
        try {
            var jsonMatch = output.match(/\{[\s\S]*\}/);
            if (jsonMatch) {
                var lsblkOutput = JSON.parse(jsonMatch[0]);
                if (lsblkOutput.blockdevices && lsblkOutput.blockdevices[0]) {
                    var device = lsblkOutput.blockdevices[0];
                    if (device.children) {
                        for (var i = 0; i < device.children.length; i++) {
                            var child = device.children[i];
                            if (child.size) totalSize += parseInt(child.size) || 0;
                        }
                    }
                }
            }
        } catch(e) {
            console.warn("[KVitals] lsblk parse failed, using df fallback");
        }

        var usedSpace = 0;
        var lines = output.split("\n");
        for (var i = 1; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line.length === 0) continue;
            var parts = line.split(/\s+/);
            if (parts.length >= 3) {
                var used = parseInt(parts[2]) || 0;
                if (!isNaN(used)) usedSpace += used;
                if (totalSize === 0 && parts[1]) {
                    var size = parseInt(parts[1]) || 0;
                    if (!isNaN(size)) totalSize += size;
                }
            }
        }

        summedPartitionUsed = usedSpace;
        summedPartitionTotal = totalSize;
    }

    // Matches lmsensors chips that are NVMe (nvme-pci-*) or SATA drivetemp
    // (drivetemp-scsi-*) and picks temp1 (Composite) or temp2 (secondary sensor)

    Sensors.SensorTreeModel { id: sensorTree }

    KItemModels.KDescendantsProxyModel {
        id: flatSensors
        model: sensorTree
    }

    property var _tempSensorIds: []

    function _refreshTempSensors() {
        console.debug("[KVitals] DiskSensors: scan started. rows = " + flatSensors.rowCount());
        var found = [];
        for (var row = 0; row < flatSensors.rowCount(); row++) {
            var idx = flatSensors.index(row, 0);
            var sid = flatSensors.data(idx, Sensors.SensorTreeModel.SensorId);
            if (!sid) continue;
            if (/^lmsensors\/(nvme-pci-[^/]+|drivetemp-scsi-[^/]+)\/temp[12]$/.test(sid))
                found.push(sid);
        }
        console.debug("[KVitals] DiskSensors: scan finished. found = " + JSON.stringify(found));
        if (JSON.stringify(found) !== JSON.stringify(_tempSensorIds)) {
            console.debug("[KVitals] DiskSensors: temp sensors updated. ids = " + JSON.stringify(found));
            _tempSensorIds = found;
        }
    }

    property bool _discoveryDirty: false

    Timer {
        id: discoveryTimer
        interval: 500
        repeat: false
        running: _discoveryDirty
        onTriggered: {
            _discoveryDirty = false;
            root._refreshTempSensors();
        }
    }

    Connections {
        target: flatSensors
        function onRowsInserted() { root._discoveryDirty = true; }
        function onRowsRemoved()  { root._discoveryDirty = true; }
        function onModelReset()   { root._discoveryDirty = true; }
    }

    Component.onCompleted: {
        console.warn("[KVitals] DiskSensors: ready.");
        _refreshTempSensors();
        if (root.diskDevice && root.diskDevice !== "" && root.diskDevice !== "auto") {
            root.selectedDiskDevice = root.diskDevice;
            partitionUsageSource.run(root.diskDevice);
        }
    }

    onDiskDeviceChanged: {
        if (diskDevice === "auto" || diskDevice === "" || !diskDevice) {
            selectedDiskDevice = "";
            summedPartitionUsed = 0;
            summedPartitionTotal = 0;
        } else {
            selectedDiskDevice = diskDevice;
            partitionUsageSource.run(diskDevice);
        }
    }

    // Poll discovered temp sensors
    Sensors.SensorDataModel {
        id: tempData
        sensors: root._tempSensorIds
        updateRateLimit: root.updateInterval
        enabled: root._tempSensorIds.length > 0
        onDataChanged: root._aggregateTemp()
        onReadyChanged: { if (ready) root._aggregateTemp(); }
    }

    function _aggregateTemp() {
        var max = NaN;
        for (var i = 0; i < _tempSensorIds.length; i++) {
            var col = tempData.column(_tempSensorIds[i]);
            if (col < 0) continue;
            var val = tempData.data(tempData.index(0, col), Sensors.SensorDataModel.Value);
            if (typeof val !== "number" || isNaN(val) || val <= 0) continue;
            if (isNaN(max) || val > max) max = val;
        }
        _diskTempNum = max;
    }
}
