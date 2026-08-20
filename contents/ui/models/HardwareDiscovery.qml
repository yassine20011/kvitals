import QtQuick
import org.kde.ksysguard.sensors as Sensors
import org.kde.kitemmodels as KItemModels

Item {
    id: root

    readonly property int count: _allIds.length
    readonly property int revision: _revision
    readonly property var allSensorIds: _allIds

    function queryIds(pattern) {
        if (!pattern) return [];
        var regex = (pattern instanceof RegExp) ? pattern : new RegExp(pattern);
        var result = [];
        for (var i = 0; i < _allIds.length; i++) {
            if (regex.test(_allIds[i])) {
                result.push(_allIds[i]);
            }
        }
        return result;
    }

    function query(pattern) {
        if (!pattern) return [];
        var regex = (pattern instanceof RegExp) ? pattern : new RegExp(pattern);
        var result = [];
        for (var i = 0; i < _allSensors.length; i++) {
            if (regex.test(_allSensors[i].id)) {
                result.push(_allSensors[i]);
            }
        }
        return result;
    }

    function sensorExists(sensorId) {
        return _idSet[sensorId] === true;
    }

    property var _allIds: []
    property var _allSensors: []
    property var _idSet: ({})
    property int _revision: 0
    property bool _dirty: false

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
        function onRowsInserted() { root._dirty = true; }
        function onRowsRemoved()  { root._dirty = true; }
        function onModelReset()   { root._dirty = true; }
        function onDataChanged()  { root._dirty = true; }
    }

    function _rebuildInventory() {
        var rowCount = flatSensors.rowCount();
        var ids = [];
        var sensors = [];
        var set = {};

        for (var row = 0; row < rowCount; row++) {
            var idx = flatSensors.index(row, 0);
            var sid = flatSensors.data(idx, Sensors.SensorTreeModel.SensorId);
            if (!sid || sid.length === 0) continue;

            var name = flatSensors.data(idx, Qt.DisplayRole) || "";
            ids.push(sid);
            sensors.push({ id: sid, name: name });
            set[sid] = true;
        }

        _allIds = ids;
        _allSensors = sensors;
        _idSet = set;
        _revision++;
    }

    Component.onCompleted: _rebuildInventory()
}
