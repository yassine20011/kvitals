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
    property string diskLabels: ""

    readonly property string diskReadValue:  Utils.formatRate(diskReadSensor.status  === Sensors.Sensor.Ready ? diskReadSensor.value  : NaN, networkUnit)
    readonly property string diskWriteValue: Utils.formatRate(diskWriteSensor.status === Sensors.Sensor.Ready ? diskWriteSensor.value : NaN, networkUnit)

    readonly property real   diskTempNumber: _diskTempNum
    readonly property string diskTempValue:  isNaN(_diskTempNum) ? "" : Utils.formatTemp(_diskTempNum, tempUnit)

    readonly property var discoveredDisks: _discovered
    property var _discovered: []

    readonly property var diskDataList: _dataList
    property var _dataList: []

    readonly property bool multiDisk: _discovered.length > 1

    property real _diskTempNum: NaN

    // Aggregate I/O sensors (used in compact panel and tooltip)
    Sensors.Sensor {
        id: diskReadSensor
        sensorId: "disk/all/read"
        updateRateLimit: root.updateInterval
        enabled: root.enabled
    }

    Sensors.Sensor {
        id: diskWriteSensor
        sensorId: "disk/all/write"
        updateRateLimit: root.updateInterval
        enabled: root.enabled
    }

    // --- Per-disk discovery via SensorTreeModel ---

    Sensors.SensorTreeModel { id: sensorTree }

    KItemModels.KDescendantsProxyModel {
        id: flatSensors
        model: sensorTree
    }

    function refreshDiscovered() {
        var found = [];
        for (var row = 0; row < flatSensors.rowCount(); row++) {
            var idx = flatSensors.index(row, 0);
            var sid = flatSensors.data(idx, Sensors.SensorTreeModel.SensorId);
            if (!sid) continue;
            var match = sid.match(/^disk\/(nvme\d+n\d+|sd[a-z]+)\/read$/);
            if (!match) continue;
            var did = match[1];
            if (found.some(function(d){ return d.id === did; })) continue;
            found.push({ id: did, name: "DSK " + (found.length + 1) });
        }
        if (JSON.stringify(found) !== JSON.stringify(_discovered)) {
            _discovered = found;
            aggregatePerDisk();
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
            root.refreshDiscovered();
        }
    }

    Connections {
        target: flatSensors
        function onRowsInserted() { root._discoveryDirty = true; }
        function onRowsRemoved()  { root._discoveryDirty = true; }
        function onModelReset()   { root._discoveryDirty = true; }
        function onDataChanged()  { root._discoveryDirty = true; }
    }

    // --- Per-disk sensor IDs ---

    readonly property var _activeSensorIds: {
        var ids = [];
        for (var i = 0; i < _discovered.length; i++) {
            ids.push("disk/" + _discovered[i].id + "/read");
            ids.push("disk/" + _discovered[i].id + "/write");
        }
        return ids;
    }

    // --- Per-disk SensorDataModel ---

    Sensors.SensorDataModel {
        id: diskData
        sensors: root._activeSensorIds
        updateRateLimit: root.updateInterval
        enabled: root._activeSensorIds.length > 0
        onDataChanged: root.aggregatePerDisk()
        onReadyChanged: { if (ready) root.aggregatePerDisk(); }
    }

    function parseDiskLabels(str) {
        var result = {};
        if (!str) return result;
        str.split("|").forEach(function(pair) {
            var sep = pair.indexOf(":");
            if (sep > 0) result[pair.substring(0, sep)] = pair.substring(sep + 1);
        });
        return result;
    }

    function _modelValue(sensorId) {
        var col = diskData.column(sensorId);
        if (col < 0) return NaN;
        var idx = diskData.index(0, col);
        if (!idx.valid) return NaN;
        var val = diskData.data(idx, Sensors.SensorDataModel.Value);
        return (val === undefined || val === null) ? NaN : val;
    }

    function aggregatePerDisk() {
        var custom = parseDiskLabels(diskLabels);
        var newList = [];
        for (var i = 0; i < _discovered.length; i++) {
            var d = _discovered[i];
            var rVal = _modelValue("disk/" + d.id + "/read");
            var wVal = _modelValue("disk/" + d.id + "/write");
            var rStr = !isNaN(rVal) ? Utils.formatRate(rVal, networkUnit) : "";
            var wStr = !isNaN(wVal) ? Utils.formatRate(wVal, networkUnit) : "";
            var name = custom[d.id] || d.name;
            newList.push({ id: d.id, name: name, read: rStr, write: wStr });
        }
        _dataList = newList;
    }

    // ksystemstats' disk plugin does NOT remove sensors or emit rowsRemoved
    // when a USB is unplugged — the sensor tree entries persist with 0 values
    // indefinitely. We cross-reference against /proc/diskstats directly.
    Timer {
        id: procCheckTimer
        interval: 5000
        repeat: true
        running: true
        onTriggered: root._checkProcDisks()
    }

    function _checkProcDisks() {
        console.warn("[KVitals] DiskSensors: _checkProcDisks running, _discovered:", JSON.stringify(root._discovered.map(function(d){return d.id;})));
        var req = new XMLHttpRequest();
        try {
            req.open("GET", "file:///proc/diskstats");
        } catch (e) {
            console.warn("[KVitals] DiskSensors: XMLHttpRequest.open failed:", e);
            return;
        }
        req.onreadystatechange = function() {
            if (req.readyState !== XMLHttpRequest.DONE) return;
            console.warn("[KVitals] DiskSensors: XHR done, status:", req.status, "text length:", (req.responseText || "").length);
            var text = req.responseText;
            if (!text) {
                console.warn("[KVitals] DiskSensors: empty response from /proc/diskstats");
                return;
            }
            var exists = {};
            var lines = text.split("\n");
            for (var i = 0; i < lines.length; i++) {
                var parts = lines[i].trim().split(/\s+/);
                if (parts.length >= 3 && /^(nvme\d+n\d+|sd[a-z]+)$/.test(parts[2]) && !/\d$/.test(parts[2]))
                    exists[parts[2]] = true;
            }
            console.warn("[KVitals] DiskSensors: /proc/diskstats has devices:", JSON.stringify(Object.keys(exists).sort()));
            var changed = false;
            var filtered = [];
            for (var i = 0; i < root._discovered.length; i++) {
                if (exists[root._discovered[i].id])
                    filtered.push(root._discovered[i]);
                else {
                    console.warn("[KVitals] DiskSensors: removing", root._discovered[i].id, "- not in /proc/diskstats");
                    changed = true;
                }
            }
            if (changed) {
                root._discovered = filtered;
                root.aggregatePerDisk();
            }
        };
        req.send();
    }

    // --- Temperature (lmsensors) ---

    property var _tempSensorIds: []

    function _refreshTempSensors() {
        var found = [];
        for (var row = 0; row < flatSensors.rowCount(); row++) {
            var idx = flatSensors.index(row, 0);
            var sid = flatSensors.data(idx, Sensors.SensorTreeModel.SensorId);
            if (!sid) continue;
            if (/^lmsensors\/(nvme-pci-[^/]+|drivetemp-scsi-[^/]+)\/temp[12]$/.test(sid))
                found.push(sid);
        }
        if (JSON.stringify(found) !== JSON.stringify(_tempSensorIds)) {
            _tempSensorIds = found;
        }
    }

    property bool _tempDiscoveryDirty: false

    Timer {
        id: tempDiscoveryTimer
        interval: 500
        repeat: false
        running: _tempDiscoveryDirty
        onTriggered: {
            _tempDiscoveryDirty = false;
            root._refreshTempSensors();
        }
    }

    Connections {
        target: flatSensors
        function onRowsInserted() { root._tempDiscoveryDirty = true; }
        function onRowsRemoved()  { root._tempDiscoveryDirty = true; }
        function onModelReset()   { root._tempDiscoveryDirty = true; }
    }

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

    onDiskLabelsChanged: aggregatePerDisk()
    onNetworkUnitChanged: aggregatePerDisk()

    Component.onCompleted: {
        refreshDiscovered();
        _refreshTempSensors();
    }
}
