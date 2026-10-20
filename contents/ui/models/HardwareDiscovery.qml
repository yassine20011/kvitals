import QtQuick
import org.kde.ksysguard.sensors as Sensors
import org.kde.kitemmodels as KItemModels
import "./MetricDefinitions.js" as MetricDefinitions
import "./HardwareInventoryLogic.js" as HardwareInventoryLogic

Item {
    id: root

    readonly property int count: _allIds.length
    readonly property int revision: _revision
    readonly property var allSensorIds: _allIds

    // Pre-indexed hardware properties
    readonly property var discoveredGpus: _gpus
    readonly property var discoveredDisks: _disks
    readonly property var discoveredFans: _fans
    readonly property var discoveredCores: _cpuCores
    readonly property var discoveredNetworkIfaces: _netIfaces
    readonly property var discoveredBatteries: _batteries
    readonly property var discoveredDiskTemps: _diskTemps

    // Query cache for O(1) repeated pattern queries
    property var _patternCache: ({})

    function queryIds(pattern) {
        if (!pattern) return [];
        var key = (pattern instanceof RegExp) ? pattern.source : String(pattern);
        if (_patternCache[key]) {
            return _patternCache[key];
        }
        var regex = (pattern instanceof RegExp) ? pattern : new RegExp(pattern);
        var result = [];
        for (var i = 0; i < _allIds.length; i++) {
            if (regex.test(_allIds[i])) {
                result.push(_allIds[i]);
            }
        }
        _patternCache[key] = result;
        return result;
    }

    function query(pattern) {
        if (!pattern) return [];
        var key = "full_" + ((pattern instanceof RegExp) ? pattern.source : String(pattern));
        if (_patternCache[key]) {
            return _patternCache[key];
        }
        var regex = (pattern instanceof RegExp) ? pattern : new RegExp(pattern);
        var result = [];
        for (var i = 0; i < _allSensors.length; i++) {
            if (regex.test(_allSensors[i].id)) {
                result.push(_allSensors[i]);
            }
        }
        _patternCache[key] = result;
        return result;
    }

    function sensorExists(sensorId) {
        return _idSet[sensorId] === true;
    }

    function rescan() {
        _rebuildInventory();
    }

    property var _allIds: []
    property var _allSensors: []
    property var _idSet: ({})
    property int _revision: 0
    property bool _dirty: false

    property var _gpus: []
    property var _disks: []
    property var _fans: []
    property var _cpuCores: []
    property var _netIfaces: ["auto"]
    property var _batteries: []
    property var _diskTemps: []

    Sensors.SensorTreeModel {
        id: sensorTree
    }

    KItemModels.KDescendantsProxyModel {
        id: flatSensors
        model: sensorTree
    }

    Timer {
        id: debounceTimer
        interval: 350
        repeat: false
        running: root._dirty
        onTriggered: {
            root._dirty = false;
            root._rebuildInventory();
        }
    }

    Connections {
        target: flatSensors
        function onRowsInserted() {
            if (root._allIds.length === 0) {
                root._rebuildInventory();
            } else {
                root._dirty = true;
            }
        }
        function onRowsRemoved() { root._dirty = true; }
        function onModelReset() { root._rebuildInventory(); }
        function onDataChanged() { root._dirty = true; }
    }

    function _rebuildInventory() {
        var rowCount = flatSensors.rowCount();
        var entries = [];

        for (var row = 0; row < rowCount; row++) {
            var idx = flatSensors.index(row, 0);
            var sid = flatSensors.data(idx, Sensors.SensorTreeModel.SensorId);
            var name = flatSensors.data(idx, Qt.DisplayRole) || "";
            entries.push({ id: sid, name: name });
        }

        var inventory = HardwareInventoryLogic.buildInventory(entries, MetricDefinitions.PATTERNS);
        _allIds = inventory.allIds;
        _allSensors = inventory.allSensors;
        _idSet = inventory.idSet;
        _patternCache = {};
        _gpus = inventory.gpus;
        _disks = inventory.disks;
        _fans = inventory.fans;
        _cpuCores = inventory.cpuCores;
        _netIfaces = inventory.networkIfaces;
        _batteries = inventory.batteries;
        _diskTemps = inventory.diskTemps;

        _revision++;
    }

    Component.onCompleted: _rebuildInventory()
}
