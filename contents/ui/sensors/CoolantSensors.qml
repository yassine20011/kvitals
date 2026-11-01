import QtQuick
import org.kde.ksysguard.sensors as Sensors

Item {
    id: root

    property var discovery: null
    property int updateInterval: 2000
    property string tempUnit: "C"
    property string coolantLabels: ""

    readonly property var discoveredCoolants: _discovered
    property var _discovered: []

    readonly property bool hasCoolantData: _dataList.length > 0

    readonly property var coolantDataList: _dataList
    property var _dataList: []

    function refreshDiscovered() {
        if (!discovery) return;
        var found = (discovery.discoveredCoolants || []).map(function(c) {
            return { id: c.id, sensorId: c.sensorId, name: c.name };
        });

        if (JSON.stringify(found) !== JSON.stringify(_discovered)) {
            _discovered = found;
        }
    }

    Connections {
        target: discovery
        function onRevisionChanged() { root.refreshDiscovered(); }
    }

    onDiscoveryChanged: refreshDiscovered()

    Component.onCompleted: refreshDiscovered()

    readonly property var _activeSensorIds: _discovered.map(function(c){ return c.sensorId; })

    Sensors.SensorDataModel {
        id: coolantData
        sensors: root._activeSensorIds
        updateRateLimit: root.updateInterval
        enabled: root._activeSensorIds.length > 0

        onDataChanged: root.aggregate()
        onReadyChanged: { if (ready) root.aggregate(); }
        onRowsInserted: root.aggregate()
        onColumnsInserted: root.aggregate()
        onModelReset: root.aggregate()
        onLayoutChanged: root.aggregate()
    }

    function _modelValue(sensorId) {
        var col = coolantData.column(sensorId);
        if (col < 0) return NaN;
        var idx = coolantData.index(0, col);
        if (!idx.valid) return NaN;
        var val = coolantData.data(idx, Sensors.SensorDataModel.Value);
        return (val === undefined || val === null) ? NaN : val;
    }

    function parseCoolantLabels(str) {
        if (!str) return {};
        if (typeof str === "object") return str;
        var trimmed = String(str).trim();
        if (trimmed.startsWith("{")) {
            try {
                return JSON.parse(trimmed);
            } catch (e) {}
        }
        var result = {};
        trimmed.split("|").forEach(function(pair) {
            var sep = pair.indexOf(":");
            if (sep > 0) result[pair.substring(0, sep).trim()] = pair.substring(sep + 1).trim();
        });
        return result;
    }

    function aggregate() {
        var custom = parseCoolantLabels(coolantLabels);
        var newList = [];
        for (var i = 0; i < _discovered.length; i++) {
            var c = _discovered[i];
            var v = _modelValue(c.sensorId);
            if (isNaN(v)) continue;
            newList.push({ id: c.id, name: custom[c.id] || c.name,
                           value: Utils.formatTemp(v, tempUnit), valueNumber: v });
        }
        _dataList = newList;
    }

    onTempUnitChanged: aggregate()
    onCoolantLabelsChanged: aggregate()
}
