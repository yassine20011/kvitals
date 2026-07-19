import QtQuick
import org.kde.ksysguard.sensors as Sensors
import org.kde.kitemmodels as KItemModels
import org.kde.plasma.plasma5support as P5Support

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
            if (_unplugged[did]) continue;
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
    // when a USB disk is unplugged — the sensor tree entries persist with 0
    // values indefinitely. The Solid hotplug dataengine emits add/remove
    // events for removable storage (driven by the same UDisks2 DBus signals
    // plasmashell already listens to for the device notifier), so track
    // devices we saw removed and filter them out of discovery. Internal
    // disks never appear in this engine, so they are never filtered.
    property var _unplugged: ({})

    function _udiToDisk(udi) {
        // e.g. /org/freedesktop/UDisks2/block_devices/sdb1 -> "sdb"
        var m = String(udi).match(/\/(sd[a-z]+|nvme\d+n\d+)(?:p?\d+)?$/);
        return m ? m[1] : "";
    }

    P5Support.DataSource {
        id: hotplugSource
        engine: "hotplug"
        onSourceAdded: function(source) {
            var disk = root._udiToDisk(source);
            if (disk && root._unplugged[disk]) {
                delete root._unplugged[disk];
                root.refreshDiscovered();
            }
        }
        onSourceRemoved: function(source) {
            var disk = root._udiToDisk(source);
            if (disk) {
                root._unplugged[disk] = true;
                root.refreshDiscovered();
            }
        }
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
