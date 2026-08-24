import QtQuick
import org.kde.ksysguard.sensors as Sensors
import "../models/MetricDefinitions.js" as MetricDefinitions

Item {
    id: root

    property var discovery: null
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

    // SPD5118 and chipset discovery via HardwareDiscovery
    function refreshDiscovered() {
        if (!discovery) return;
        var ramCandidates = [];
        var chipsetCandidates = [];
        var pattern = MetricDefinitions.PATTERNS ? MetricDefinitions.PATTERNS.TEMP_LMSENSORS : /^lmsensors\/(.+)\/temp\d+$/;
        var sensors = discovery.query(pattern);

        for (var i = 0; i < sensors.length; i++) {
            var sensorId = sensors[i].id;
            if (!sensorId || sensorId.length === 0) continue;

            // Skip CPU core temps and GPU temps
            if (/^(cpu|gpu)\//.test(sensorId)) continue;

            var match = sensorId.match(pattern);
            if (!match) continue;

            var adapter = match[1];

            if (/^spd5118/i.test(adapter)) {
                ramCandidates.push({ id: sensorId, adapter: adapter });
                continue;
            }

            // Chipset discovery: Intel PCH (pch_*) and motherboard Super I/O (-isa-)
            var isPch = /^pch_/i.test(adapter);
            var isIsaSuperIo = /-isa-/.test(adapter) && !/^coretemp/i.test(adapter) && !/^asus-isa/i.test(adapter);
            if (isPch || isIsaSuperIo) {
                var label = sensors[i].name || "";
                chipsetCandidates.push({ id: sensorId, adapter: adapter, label: label, priority: isPch ? 1 : 2 });
            }
        }

        // Clear RAM sensor ID if no longer in the tree
        var ramStillValid = false;
        for (var ci = 0; ci < ramCandidates.length; ci++) {
            if (ramCandidates[ci].id === _ramSensorId) { ramStillValid = true; break; }
        }
        if (!ramStillValid) _ramSensorId = "";

        if (_ramSensorId.length === 0 && ramCandidates.length > 0) {
            _ramSensorId = ramCandidates[0].id;
        }

        // Chipset sensor discovery
        if (chipsetCandidates.length > 0) {
            chipsetCandidates.sort(function(a, b) { return a.priority - b.priority; });
            var best = chipsetCandidates[0];
            if (chipsetCandidates.length > 1) {
                var nonSystemLabels = /^(cputin|auxtin|peci|smbusmaster)/i;
                var filtered = chipsetCandidates.filter(function(c) {
                    return !nonSystemLabels.test(c.label);
                });
                if (filtered.length > 0) best = filtered[0];
            }
            if (_systemSensorId !== best.id) {
                _systemSensorId = best.id;
            }
        } else if (discovery.count > 0) {
            _systemSensorId = "";
        }
    }

    Connections {
        target: discovery
        function onRevisionChanged() { root.refreshDiscovered(); }
    }

    onDiscoveryChanged: refreshDiscovered()

    Component.onCompleted: {
        refreshDiscovered();
    }
}
