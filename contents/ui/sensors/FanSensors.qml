import QtQuick
import org.kde.ksysguard.sensors as Sensors
import org.kde.kitemmodels as KItemModels

Item {
    id: root

    property int updateInterval: 2000
    property string fanUnit: "rpm" // "rpm" or "percent"
    property string fanLabels: ""
    property int fanMaxRpm: 2000

    readonly property var discoveredFans: _discovered
    property var _discovered: []

    readonly property string fanValue: _fanStr
    readonly property bool hasFanData: _fanStr.length > 0
    property string _fanStr: ""

    readonly property var fanDataList: _dataList
    property var _dataList: []

    readonly property bool multiFan: _discovered.length > 1

    // -------------------------------------------------------------------------
    // Step 1: Discover available Fans via SensorTreeModel
    // -------------------------------------------------------------------------

    Sensors.SensorTreeModel {
        id: sensorTree
    }

    KItemModels.KDescendantsProxyModel {
        id: flatSensors
        model: sensorTree
    }

    function refreshDiscovered() {
        var ids = [];
        for (var row = 0; row < flatSensors.rowCount(); row++) {
            var idx = flatSensors.index(row, 0);
            var sensorId = flatSensors.data(idx, Sensors.SensorTreeModel.SensorId);
            if (!sensorId || sensorId.length === 0) continue;
            // Match any sensor that contains /fan and doesn't end with a non-digit (typically fan1, fan2, etc)
            var match = sensorId.match(/^(lmsensors|cpu|gpu)\/.*\/fan\d+$/i);
            if (!match) continue;
            ids.push(sensorId);
        }
        // Sort by sensor id before numbering: the sensor tree's traversal
        // order isn't guaranteed stable across sessions, and renumbering
        // fans on every restart would make "Fan 1"/"Fan 2" (and any custom
        // labels keyed off them) refer to different physical fans over time.
        ids.sort();
        // KSysGuard's DisplayRole is often generic/duplicated across fans
        // (e.g. the same "Fan Speed" label for every one), so it can't be
        // used to tell them apart. Assign a stable numbered name instead,
        // same as GpuSensors.qml does for multiple GPUs.
        var found = ids.map(function(id, i) {
            return { id: id, name: "Fan " + (i + 1), number: i + 1 };
        });

        if (JSON.stringify(found) !== JSON.stringify(_discovered)) {
            _discovered = found;
        }
    }

    Connections {
        target: flatSensors
        function onRowsInserted() { root.refreshDiscovered(); }
        function onRowsRemoved()  { root.refreshDiscovered(); }
        function onModelReset()   { root.refreshDiscovered(); }
    }

    Component.onCompleted: refreshDiscovered()

    // -------------------------------------------------------------------------
    // Step 2: Poll discovered fans
    // -------------------------------------------------------------------------

    readonly property var _activeSensorIds: _discovered.map(function(f){ return f.id; })

    Sensors.SensorDataModel {
        id: fanData
        sensors: root._activeSensorIds
        updateRateLimit: root.updateInterval
        enabled: root._activeSensorIds.length > 0

        onDataChanged: root.aggregate()
        onReadyChanged: { if (ready) root.aggregate(); }
    }

    function _modelValue(sensorId) {
        var col = fanData.column(sensorId);
        if (col < 0) return NaN;
        var idx = fanData.index(0, col);
        if (!idx.valid) return NaN;
        var val = fanData.data(idx, Sensors.SensorDataModel.Value);
        return (val === undefined || val === null) ? NaN : val;
    }

    function _modelMax(sensorId) {
        var col = fanData.column(sensorId);
        if (col < 0) return NaN;
        var idx = fanData.index(0, col);
        if (!idx.valid) return NaN;
        var val = fanData.data(idx, Sensors.SensorDataModel.Maximum);
        return (val === undefined || val === null) ? NaN : val;
    }

    function parseFanLabels(str) {
        var result = Object.create(null);
        if (!str) return result;
        str.split("|").forEach(function(pair) {
            var sep = pair.indexOf(":");
            if (sep > 0) result[pair.substring(0, sep)] = pair.substring(sep + 1);
        });
        return result;
    }

    // Returns { str, estimated }. "estimated" is true when the hardware
    // doesn't report its own max RPM and we fell back to the user-configured
    // fanMaxRpm guess instead of a real measurement.
    function _fanValueStr(f) {
        var v = _modelValue(f.id);
        if (isNaN(v) || v <= 0) return { str: "", estimated: false };
        if (fanUnit === "percent") {
            var max = _modelMax(f.id);
            var estimated = isNaN(max) || max <= 0;
            if (estimated) max = (fanMaxRpm > 0 ? fanMaxRpm : 2000);
            if (max <= 0) max = 2000;
            return { str: Math.min(100, Math.round((v / max) * 100)) + "%", estimated: estimated };
        }
        return { str: Math.round(v) + " RPM", estimated: false };
    }

    function aggregate() {
        var custom = parseFanLabels(fanLabels);
        var newList = [];
        var parts = [];
        for (var i = 0; i < _discovered.length; i++) {
            var f = _discovered[i];
            var r = _fanValueStr(f);
            if (!r.str) continue;
            var name = custom[f.id] || f.name;
            var v = _modelValue(f.id);
            // rpmValue is always the raw RPM reading, independent of fanUnit —
            // used by the popup, which shows RPM regardless of the compact
            // panel's unit (percent only saves space, it isn't more accurate).
            newList.push({ id: f.id, name: name, value: r.str, rpmValue: Math.round(v) + " RPM",
                           number: f.number, valueNumber: (!isNaN(v) && v > 0) ? v : NaN,
                           isEstimated: r.estimated });
            parts.push(r.str);
        }
        _fanStr = parts.join(" ");
        _dataList = newList;
    }

    onFanUnitChanged: aggregate()
    onFanLabelsChanged: aggregate()
    onFanMaxRpmChanged: aggregate()
}
