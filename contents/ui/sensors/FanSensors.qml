import QtQuick
import org.kde.ksysguard.sensors as Sensors
import org.kde.kitemmodels as KItemModels

Item {
    id: root

    property int updateInterval: 2000
    property string fanUnit: "rpm" // "rpm" or "percent"

    readonly property var discoveredFans: _discovered
    property var _discovered: []

    readonly property string fanValue: _fanStr
    readonly property bool hasFanData: _fanStr.length > 0
    property string _fanStr: ""

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
        var found = [];
        for (var row = 0; row < flatSensors.rowCount(); row++) {
            var idx = flatSensors.index(row, 0);
            var sensorId = flatSensors.data(idx, Sensors.SensorTreeModel.SensorId);
            if (!sensorId || sensorId.length === 0) continue;
            // Match any sensor that contains /fan and doesn't end with a non-digit (typically fan1, fan2, etc)
            var match = sensorId.match(/^(lmsensors|cpu|gpu)\/.*\/fan\d+$/i);
            if (!match) continue;
            // Some names are like "cpu_fan", we can try to extract the last part or use the sensor Name
            var name = flatSensors.data(idx, Qt.DisplayRole) || "Fan " + (found.length + 1);
            found.push({ id: sensorId, name: name });
        }

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

    function aggregate() {
        var parts = [];
        for (var i = 0; i < _discovered.length; i++) {
            var f = _discovered[i];
            var v = _modelValue(f.id);
            if (isNaN(v) || v <= 0) continue; // Ignore 0 RPM or disconnected fans

            var str = "";
            if (fanUnit === "percent") {
                var max = _modelMax(f.id);
                if (isNaN(max) || max <= 0) {
                    continue;
                }
                var pct = Math.min(100, Math.round((v / max) * 100));
                str = pct + "%";
            } else {
                str = Math.round(v) + " RPM";
            }
            parts.push(str);
        }
        _fanStr = parts.join(" ");
    }

    onFanUnitChanged: aggregate()
}
