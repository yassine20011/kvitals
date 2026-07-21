import QtQuick
import org.kde.ksysguard.sensors as Sensors
import org.kde.kitemmodels as KItemModels

Item {
    id: root
    property bool _dbg: { console.warn("[KVitals] TempSensors: constructing..."); return true; }

    property int updateInterval: 2000
    property string tempUnit: "C"

    // ── System/motherboard temperature ─────────────────────────────────────
    // Discovery excludes CPU, GPU, disk, WiFi, Ethernet, and SPD5118
    // Fallback: cpu/all/averageTemperature

    property string _sysSensorId: ""

    readonly property string _activeSysId: _sysSensorId.length > 0
        ? _sysSensorId : "cpu/all/averageTemperature"

    readonly property real sysTempNumericValue: {
        if (sysSensor.status !== Sensors.Sensor.Ready) return NaN;
        return sysSensor.value;
    }

    readonly property string sysTempValue: {
        if (isNaN(sysTempNumericValue)) return "--";
        return Utils.formatTemp(sysTempNumericValue, tempUnit);
    }

    // Alias for backward compatibility with main.qml
    readonly property real tempNumericValue: sysTempNumericValue
    readonly property string tempValue: sysTempValue

    // True when no motherboard sensor found (yet) → using CPU average
    readonly property bool sysIsFallback: _sysSensorId.length === 0

    Sensors.Sensor {
        id: sysSensor
        sensorId: root._activeSysId
        updateRateLimit: root.updateInterval
    }

    // ── DDR5 RAM temperature (SPD5118) ────────────────────────────────────

    property string _ramSensorId: ""

    readonly property bool ramTempExists: _ramSensorId.length > 0

    readonly property real ramTempNumericValue: {
        if (!ramTempExists) return NaN;
        if (ramSensor.status !== Sensors.Sensor.Ready) return NaN;
        return ramSensor.value;
    }

    readonly property string ramTempValue: {
        if (isNaN(ramTempNumericValue)) return "--";
        return Utils.formatTemp(ramTempNumericValue, tempUnit);
    }

    Sensors.Sensor {
        id: ramSensor
        sensorId: root._ramSensorId || ""
        updateRateLimit: root.updateInterval
        enabled: root.ramTempExists
    }

    // ── Sensor tree discovery ─────────────────────────────────────────────

    Sensors.SensorTreeModel { id: sensorTree }
    KItemModels.KDescendantsProxyModel { id: flatSensors; model: sensorTree }

    // The sensor tree is populated incrementally over several async
    // rowsInserted bursts (root node first, then adapters, then leaf
    // temp entries). Rather than trying to guess when discovery is
    // "done" and latching a final answer, just rescan on every model
    // change and pick a candidate as soon as one shows up. _sysSensorId
    // / _ramSensorId themselves already carry the "found" state, so
    // sysIsFallback / ramTempExists can read them directly instead of
    // relying on a separate one-shot "selection finished" flag that can
    // fire before the tree is actually populated.
    function refreshDiscovered() {
        var sysCandidates = [];
        var ramCandidates = [];
        var newRows = flatSensors.rowCount();

        for (var row = 0; row < newRows; row++) {
            var idx = flatSensors.index(row, 0);
            var sensorId = flatSensors.data(idx, Sensors.SensorTreeModel.SensorId);
            if (!sensorId || sensorId.length === 0) continue;

            var match = sensorId.match(/^lmsensors\/(.+)\/temp\d+$/);
            if (!match) continue;

            var adapter = match[1];

            // RAM temp: SPD5118 modules
            if (/^spd5118/i.test(adapter)) {
                ramCandidates.push({ id: sensorId, adapter: adapter });
                continue;
            }

            // System temp: exclude known non-motherboard sources
            if (/^(k10temp|coretemp|amdgpu|nvidia|nvme|drivetemp|mt7921|r8169)/i.test(adapter))
                continue;

            sysCandidates.push({ id: sensorId, adapter: adapter });
        }

        // Select system/RAM temp (stable once chosen)
        if (sysCandidates.length > 0 && _sysSensorId.length === 0) {
            _sysSensorId = sysCandidates[0].id;
            console.warn("[KVitals] TempSensors: system sensor = " + _sysSensorId);
        }
        if (ramCandidates.length > 0 && _ramSensorId.length === 0) {
            _ramSensorId = ramCandidates[0].id;
            console.warn("[KVitals] TempSensors: RAM sensor = " + _ramSensorId);
        }
    }

    Connections {
        target: flatSensors
        function onRowsInserted() { root.refreshDiscovered(); }
        function onRowsRemoved()  { root.refreshDiscovered(); }
        function onModelReset()   { root.refreshDiscovered(); }
    }

    Component.onCompleted: {
        console.warn("[KVitals] TempSensors: ready.");
        refreshDiscovered();
    }
}
