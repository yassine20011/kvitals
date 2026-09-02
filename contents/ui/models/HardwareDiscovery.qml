import QtQuick
import org.kde.ksysguard.sensors as Sensors
import org.kde.kitemmodels as KItemModels
import "./MetricDefinitions.js" as MetricDefinitions

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
        var ids = [];
        var sensors = [];
        var set = {};

        var gpuMap = {};
        var diskMap = {};
        var fanSet = {};
        var coreMap = {};
        var ifaceSet = {};
        var batSet = {};
        var diskTempSet = {};

        var pGpu = MetricDefinitions.PATTERNS ? MetricDefinitions.PATTERNS.GPU : /^gpu\/(gpu\d+)\/usage$/;
        var pDisk = MetricDefinitions.PATTERNS ? MetricDefinitions.PATTERNS.DISK_READ : /^disk\/(nvme\d+n\d+|sd[a-z]+)\/read$/;
        var pFan = MetricDefinitions.PATTERNS ? MetricDefinitions.PATTERNS.FAN : /^(lmsensors|cpu|gpu)\/.*\/fan\d+$/i;
        var pCore = MetricDefinitions.PATTERNS ? MetricDefinitions.PATTERNS.CPU_CORE : /^cpu\/(cpu\d+)\/usage$/;
        var pNet = MetricDefinitions.PATTERNS ? MetricDefinitions.PATTERNS.NETWORK_IFACE : /^network\/([^/]+)\/download$/;
        var pBat = MetricDefinitions.PATTERNS ? MetricDefinitions.PATTERNS.BATTERY : /^power\/([^/]+)\/chargePercentage$/;
        var pDiskTemp = MetricDefinitions.PATTERNS ? MetricDefinitions.PATTERNS.DISK_TEMP : /^(?:disk\/(?:nvme\d+n\d+|sd[a-z]+)\/temperature|lmsensors\/(?:nvme-pci-[^/]+|drivetemp-scsi-[^/]+|scsi-[^/]+|drivetemp-[^/]+)\/temp\d+)$/;

        for (var row = 0; row < rowCount; row++) {
            var idx = flatSensors.index(row, 0);
            var sid = flatSensors.data(idx, Sensors.SensorTreeModel.SensorId);
            if (!sid || sid.length === 0) continue;
            if (/[\(\)\*\?\+]/.test(sid)) continue;

            var name = flatSensors.data(idx, Qt.DisplayRole) || "";
            ids.push(sid);
            sensors.push({ id: sid, name: name });
            set[sid] = true;

            var m = null;
            if ((m = sid.match(pGpu))) {
                gpuMap[m[1]] = true;
            } else if ((m = sid.match(pDisk))) {
                diskMap[m[1]] = true;
            } else if (pFan.test(sid)) {
                fanSet[sid] = true;
            } else if ((m = sid.match(pCore))) {
                coreMap[m[1]] = true;
            } else if ((m = sid.match(pNet))) {
                if (m[1] !== "all" && m[1] !== "lo") ifaceSet[m[1]] = true;
            } else if ((m = sid.match(pBat))) {
                batSet[m[1]] = true;
            } else if (pDiskTemp.test(sid)) {
                diskTempSet[sid] = true;
            }
        }

        _allIds = ids;
        _allSensors = sensors;
        _idSet = set;
        _patternCache = {};

        var gList = Object.keys(gpuMap).sort();
        _gpus = gList.map(function(id, i) { return { id: id, name: "GPU " + (i + 1) }; });

        var dList = Object.keys(diskMap).sort();
        _disks = dList.map(function(id, i) { return { id: id, name: "Disk " + (i + 1) }; });

        var fList = Object.keys(fanSet).sort();
        _fans = fList.map(function(id, i) { return { id: id, name: "Fan " + (i + 1) }; });

        var cList = Object.keys(coreMap);
        var cSorted = [];
        for (var ci = 0; ci < cList.length; ci++) {
            var num = parseInt(cList[ci].replace("cpu", ""), 10);
            cSorted.push({ id: cList[ci], number: isNaN(num) ? ci : num });
        }
        cSorted.sort(function(a, b) { return a.number - b.number; });
        _cpuCores = cSorted.map(function(c) { return { id: c.id, number: c.number, name: "Core " + (c.number + 1) }; });

        var nList = Object.keys(ifaceSet).sort();
        _netIfaces = ["auto"].concat(nList);

        _batteries = Object.keys(batSet).sort();
        _diskTemps = Object.keys(diskTempSet).sort();

        _revision++;
    }

    Component.onCompleted: _rebuildInventory()
}
