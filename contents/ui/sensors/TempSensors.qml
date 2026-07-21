import QtQuick
import org.kde.ksysguard.sensors as Sensors
import org.kde.kitemmodels as KItemModels

Item {
    id: root
    property bool _dbg: { console.warn("[KVitals] TempSensors: constructing..."); return true; }

    property int updateInterval: 2000
    property string tempUnit: "C"

    // System temperature: auto-detect chipset sensor, fallback to CPU average
    property string _systemSensorId: ""

    readonly property real tempNumericValue: {
        if (sysSensor.status !== Sensors.Sensor.Ready) return NaN;
        return sysSensor.value;
    }

    readonly property string tempValue: {
        if (isNaN(tempNumericValue)) return "--";
        return Utils.formatTemp(tempNumericValue, tempUnit);
    }

    // Fallback is active when no chipset sensor was found and we use CPU average
    readonly property bool sysIsFallback: _systemSensorId.length === 0

    // Dedicated CPU temperature — always reads the CPU average, independent of system temp
    readonly property real cpuTempNumericValue: {
        if (cpuTempSensor.status !== Sensors.Sensor.Ready) return NaN;
        return cpuTempSensor.value;
    }

    readonly property string cpuTempValue: {
        if (isNaN(cpuTempNumericValue)) return "--";
        return Utils.formatTemp(cpuTempNumericValue, tempUnit);
    }

    Sensors.Sensor {
        id: cpuTempSensor
        sensorId: "cpu/all/averageTemperature"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: sysSensor
        sensorId: root._systemSensorId || "cpu/all/averageTemperature"
        updateRateLimit: root.updateInterval
    }

    // DDR5 RAM temperature via SPD5118 (discovered from sensor tree)
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

    // SPD5118 discovery via sensor tree
    Sensors.SensorTreeModel { id: sensorTree }
    KItemModels.KDescendantsProxyModel { id: flatSensors; model: sensorTree }

    function refreshDiscovered() {
        var ramCandidates = [];
        var chipsetCandidates = [];
        var newRows = flatSensors.rowCount();

        for (var row = 0; row < newRows; row++) {
            var idx = flatSensors.index(row, 0);
            var sensorId = flatSensors.data(idx, Sensors.SensorTreeModel.SensorId);
            if (!sensorId || sensorId.length === 0) continue;

            // Skip CPU core temps and GPU temps
            if (/^(cpu|gpu)\//.test(sensorId)) continue;

            var match = sensorId.match(/^lmsensors\/(.+)\/temp\d+$/);
            if (!match) continue;

            var adapter = match[1];

            if (/^spd5118/i.test(adapter)) {
                ramCandidates.push({ id: sensorId, adapter: adapter });
                continue;
            }

            // Super I/O chips (real chipset sensors) live on the ISA/LPC bus
            // and expose an adapter name containing "-isa-".
            // CPU sensors (k10temp on AMD) are on PCI → "-pci-".
            // GPU sensors (amdgpu, nvidia) are on PCI → "-pci-".
            // Intel coretemp is an exception: it uses "-isa-" too,
            // so we exclude it explicitly.
            // This is hardware-agnostic: no blacklist of specific drivers.
            if (/-isa-/.test(adapter) && !/^coretemp/i.test(adapter)) {
                var label = flatSensors.data(idx, Qt.DisplayRole) || "";
                chipsetCandidates.push({ id: sensorId, adapter: adapter, label: label });
            }
        }

        // Clear RAM sensor ID if no longer in the tree
        var ramStillValid = false;
        for (var ci = 0; ci < ramCandidates.length; ci++) {
            if (ramCandidates[ci].id === _ramSensorId) { ramStillValid = true; break; }
        }
        if (!ramStillValid) _ramSensorId = "";

        if (_ramSensorId.length === 0 && ramCandidates.length > 0) {
            var newRamId = ramCandidates[0].id;
            console.warn("[KVitals] TempSensors: ramSensorId selected: " + newRamId);
            _ramSensorId = newRamId;
        }

        // Chipset sensor discovery — prefer ISA/LPC bus (Super I/O).
        // PCI candidates (k10temp, amdgpu, etc.) are deliberately ignored:
        // they report CPU/GPU package temps, not chipset temps.
        // When multiple ISA channels exist on the same adapter (typical for
        // nct6775-family: SYSTIN=temp1, CPUTIN=temp2, AUXTIN*=temp3+),
        // prefer candidates whose label doesn't indicate a CPU-adjacent or
        // auxiliary sensor. The Qt::DisplayRole exposes the lm-sensors label.
        if (chipsetCandidates.length > 0) {
            var best = chipsetCandidates[0];
            if (chipsetCandidates.length > 1) {
                var nonSystemLabels = /^(cputin|auxtin|peci|smbusmaster)/i;
                var filtered = chipsetCandidates.filter(function(c) {
                    return !nonSystemLabels.test(c.label);
                });
                if (filtered.length > 0) best = filtered[0];
            }
            if (_systemSensorId !== best.id) {
                console.warn("[KVitals] TempSensors: chipset sensor selected: "
                    + best.id + " (" + best.adapter + ") label=" + best.label);
                _systemSensorId = best.id;
            }
        } else if (newRows > 0) {
            if (_systemSensorId.length > 0) {
                console.warn("[KVitals] TempSensors: chipset sensor lost, reverting to CPU fallback");
            }
            _systemSensorId = "";
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
        function onRowsInserted()    { root._discoveryDirty = true; }
        function onRowsRemoved()     { root._discoveryDirty = true; }
        function onModelReset()      { root._discoveryDirty = true; }
        function onDataChanged()     { root._discoveryDirty = true; }
    }

    Component.onCompleted: {
        console.warn("[KVitals] TempSensors: ready.");
        refreshDiscovered();
    }
}
