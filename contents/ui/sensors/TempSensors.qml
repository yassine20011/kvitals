import QtQuick
import org.kde.ksysguard.sensors as Sensors
import "../models/MetricDefinitions.js" as MetricDefinitions

Item {
    id: root

    property var discovery: null
    property int updateInterval: 2000
    property string tempUnit: "C"
    property string tempSensor: "auto"
    property string tempSelection: ""
    property string tempLabels: ""
    property string pinnedMetrics: ""
    onTempSensorChanged: refreshDiscovered()

    readonly property var tempDataList: _multiTempList
    property var _multiTempList: []

    // System temperature: auto-detect chipset sensor, fallback to CPU average
    property string _systemSensorId: ""

    readonly property real tempNumericValue: {
        if (sysSensor.status !== Sensors.Sensor.Ready) return NaN;
        if (sysSensor.value === undefined || sysSensor.value === null || isNaN(sysSensor.value)) return NaN;
        var val = Number(sysSensor.value);
        return val > 0 ? val : NaN;
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
        if (cpuTempSensor.value === undefined || cpuTempSensor.value === null || isNaN(cpuTempSensor.value)) return NaN;
        var val = Number(cpuTempSensor.value);
        return val > 0 ? val : NaN;
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
        if (ramSensor.value === undefined || ramSensor.value === null || isNaN(ramSensor.value)) return NaN;
        var val = Number(ramSensor.value);
        return val > 0 ? val : NaN;
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

    // Temperature discovery
    function refreshDiscovered() {
        if (!discovery) return;

        var ramCandidates = [];
        var chipsetCandidates = [];
        var pattern = MetricDefinitions.PATTERNS ? MetricDefinitions.PATTERNS.TEMP_LMSENSORS : /^lmsensors\/(.+)\/temp\d+$/;
        var sensors = discovery.query(pattern);

        for (var i = 0; i < sensors.length; i++) {
            var sensorId = sensors[i].id;
            if (!sensorId || sensorId.length === 0) continue;

            if (/^(cpu|gpu)\//.test(sensorId)) continue;

            var match = sensorId.match(pattern);
            if (!match) continue;

            var adapter = match[1];

            if (/^(spd5118|jc42|dimm_temp|dimm-temp)/i.test(adapter)) {
                ramCandidates.push({ id: sensorId, adapter: adapter });
                continue;
            }

            var isPch = /^pch_/i.test(adapter);
            var isIsaSuperIo = /-isa-/.test(adapter) && !/^coretemp/i.test(adapter) && !/^asus-isa/i.test(adapter);
            var isAcpi = /-acpi-/i.test(adapter);
            if (isPch || isIsaSuperIo || isAcpi) {
                var label = sensors[i].name || "";
                var priority = isPch ? 1 : (isIsaSuperIo ? 2 : 3);
                chipsetCandidates.push({ id: sensorId, adapter: adapter, label: label, priority: priority });
            }
        }

        // RAM discovery
        var ramStillValid = false;
        for (var ci = 0; ci < ramCandidates.length; ci++) {
            if (ramCandidates[ci].id === _ramSensorId) { ramStillValid = true; break; }
        }
        if (!ramStillValid) _ramSensorId = "";

        if (_ramSensorId.length === 0 && ramCandidates.length > 0) {
            _ramSensorId = ramCandidates[0].id;
        }

        // System sensor discovery
        if (root.tempSensor && root.tempSensor !== "auto") {
            var targetId = root.tempSensor;
            var resolvedTargetId = "";

            if (discovery.sensorExists(targetId)) {
                resolvedTargetId = targetId;
            } else if (discovery.sensorExists("lmsensors/" + targetId)) {
                resolvedTargetId = "lmsensors/" + targetId;
            } else {
                var discovered = discovery.discoveredTempSensors || [];
                for (var d = 0; d < discovered.length; d++) {
                    if (discovered[d].adapter === targetId || discovered[d].id.indexOf("/" + targetId + "/") !== -1) {
                        resolvedTargetId = discovered[d].id;
                        break;
                    }
                }
            }

            if (!resolvedTargetId && discovery.count === 0) {
                resolvedTargetId = targetId;
            }

            if (resolvedTargetId && _systemSensorId !== resolvedTargetId) {
                _systemSensorId = resolvedTargetId;
            }
        } else {
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
    }

    Connections {
        target: discovery
        function onRevisionChanged() { root.refreshDiscovered(); }
    }

    onDiscoveryChanged: refreshDiscovered()

    // Multi-sensor polling
    readonly property var _activeSensorIds: {
        var set = {};
        if (root.tempSelection && root.tempSelection !== "none") {
            var parts = root.tempSelection.split(",");
            for (var i = 0; i < parts.length; i++) {
                var s = parts[i].trim();
                if (s.length > 0) set[s] = true;
            }
        }
        if (root.pinnedMetrics) {
            var pinned = root.pinnedMetrics.split(",");
            for (var p = 0; p < pinned.length; p++) {
                var pItem = pinned[p].trim();
                if (pItem.startsWith("temp:") && pItem.endsWith("/temp")) {
                    var sId = pItem.substring(5, pItem.length - 5);
                    if (sId.length > 0) set[sId] = true;
                }
            }
        }
        return Object.keys(set);
    }

    Sensors.SensorDataModel {
        id: multiTempData
        sensors: root._activeSensorIds
        updateRateLimit: root.updateInterval
        enabled: root._activeSensorIds.length > 0

        onDataChanged: root.aggregateMultiTemps()
        onReadyChanged: { if (ready) root.aggregateMultiTemps(); }
        onRowsInserted: root.aggregateMultiTemps()
        onColumnsInserted: root.aggregateMultiTemps()
        onModelReset: root.aggregateMultiTemps()
        onLayoutChanged: root.aggregateMultiTemps()
    }

    function _modelValue(sensorId) {
        var col = multiTempData.column(sensorId);
        if (col < 0) return NaN;
        var idx = multiTempData.index(0, col);
        if (!idx.valid) return NaN;
        var val = multiTempData.data(idx, Sensors.SensorDataModel.Value);
        return (val === undefined || val === null || isNaN(val)) ? NaN : Number(val);
    }

    function parseTempLabels(str) {
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

    function aggregateMultiTemps() {
        if (_activeSensorIds.length === 0) {
            if (_multiTempList.length > 0) _multiTempList = [];
            return;
        }

        var custom = parseTempLabels(tempLabels);
        var discovered = discovery ? (discovery.discoveredTempSensors || []) : [];
        var discMap = {};
        for (var d = 0; d < discovered.length; d++) {
            discMap[discovered[d].id] = discovered[d];
        }

        var newList = [];
        for (var i = 0; i < _activeSensorIds.length; i++) {
            var sid = _activeSensorIds[i];
            var val = _modelValue(sid);
            var numVal = (!isNaN(val) && val > 0) ? val : NaN;
            var disc = discMap[sid] || { name: sid, adapter: sid };
            var name = custom[sid] || disc.name || sid;
            var disp = isNaN(numVal) ? "--" : Utils.formatTemp(numVal, root.tempUnit);

            newList.push({
                id: sid,
                name: name,
                valueNumber: numVal,
                displayValue: disp
            });
        }
        _multiTempList = newList;
    }

    onTempUnitChanged: aggregateMultiTemps()
    onTempLabelsChanged: aggregateMultiTemps()
    onTempSelectionChanged: aggregateMultiTemps()
    onPinnedMetricsChanged: aggregateMultiTemps()

    Component.onCompleted: {
        refreshDiscovered();
        aggregateMultiTemps();
    }
}
