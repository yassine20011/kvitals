import QtQuick
import org.kde.ksysguard.sensors as Sensors
import org.kde.kitemmodels as KItemModels

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
    readonly property string diskUsedValue: {
        if (diskUsedSensor.status !== Sensors.Sensor.Ready) return "...";
        return Utils.formatBytes(diskUsedSensor.value);
    }
    readonly property string diskTotalValue: {
        if (diskTotalSensor.status !== Sensors.Sensor.Ready) return "...";
        return Utils.formatBytes(diskTotalSensor.value);
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
