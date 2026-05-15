import QtQuick
import org.kde.ksysguard.sensors as Sensors
import org.kde.kitemmodels as KItemModels

Item {
    id: root

    property int updateInterval: 2000

    // Comma-separated selected GPU IDs e.g. "gpu0,gpu1". Empty = all discovered.
    property string gpuSelection: ""

    // User-defined labels: "gpu0:My iGPU,gpu1:dGPU". Empty string = use default "GPU N" name.
    property string gpuLabels: ""

    // List of { id: "gpu0", name: "GPU 1" } derived from SensorTreeModel (no polling)
    readonly property var discoveredGpus: _discovered
    property var _discovered: []

    // Aggregated display (single-GPU compat)
    readonly property real gpuUsageNumber: _usageNum
    readonly property real gpuTempNumber:  _tempNum
    readonly property string gpuValue:     _usageStr
    readonly property string gpuRamValue:  _vramStr
    readonly property string gpuTempValue: _tempStr
    readonly property string gpuDisplayValue: [_usageStr, _vramStr, _tempStr].filter(function(v){return v;}).join(" ")
    readonly property bool hasGpuData:      gpuDisplayValue.length > 0
    readonly property bool hasGpuUsageData: _usageStr.length > 0
    readonly property bool hasGpuVramData:  _vramStr.length > 0
    readonly property bool hasGpuTempData:  _tempStr.length > 0

    // Per-GPU list for multi display: [{ id, name, usage, vram, temp, usageNumber, tempNumber }]
    readonly property var gpuDataList: _dataList
    property var _dataList: []

    property real _usageNum: NaN
    property real _tempNum:  NaN
    property string _usageStr: ""
    property string _vramStr:  ""
    property string _tempStr:  ""

    // -------------------------------------------------------------------------
    // Step 1: Discover available GPUs via SensorTreeModel (metadata only, no polling)
    // -------------------------------------------------------------------------

    Sensors.SensorTreeModel {
        id: sensorTree
    }

    KItemModels.KDescendantsProxyModel {
        id: flatSensors
        model: sensorTree
    }

    // Parse "gpu0:Label A|gpu1:Label B" → { gpu0: "Label A", gpu1: "Label B" }
    function parseGpuLabels(str) {
        var result = {};
        if (!str) return result;
        var pairs = str.split("|");
        for (var i = 0; i < pairs.length; i++) {
            var sep = pairs[i].indexOf(":");
            if (sep > 0)
                result[pairs[i].substring(0, sep)] = pairs[i].substring(sep + 1);
        }
        return result;
    }

    function refreshDiscovered() {
        var found = [];
        for (var row = 0; row < flatSensors.rowCount(); row++) {
            var idx = flatSensors.index(row, 0);
            var sensorId = flatSensors.data(idx, Sensors.SensorTreeModel.SensorId);
            if (!sensorId || sensorId.length === 0) continue;
            var match = sensorId.match(/^gpu\/(gpu\d+)\/usage$/);
            if (!match) continue;
            found.push({ id: match[1], name: "GPU " + (found.length + 1) });
        }

        if (JSON.stringify(found) !== JSON.stringify(_discovered)) {
            _discovered = found;
            if (typeof Plasmoid !== "undefined" && Plasmoid.configuration)
                Plasmoid.configuration.gpuDiscovered = found.map(function(g){ return g.id + ":" + g.name; }).join(",");
        }
    }

    Connections {
        target: flatSensors
        function onRowsInserted()    { root.refreshDiscovered(); }
        function onRowsRemoved()     { root.refreshDiscovered(); }
        function onModelReset()      { root.refreshDiscovered(); }
        function onDataChanged()     { root.refreshDiscovered(); }
    }

    // -------------------------------------------------------------------------
    // Step 2: Compute active sensor IDs from user selection
    // -------------------------------------------------------------------------

    readonly property var _activeIds: {
        // "" (default) → all discovered; "none" → user explicitly deselected everything
        if (!gpuSelection || gpuSelection === "")
            return _discovered.map(function(g){ return g.id; });
        if (gpuSelection === "none")
            return [];
        return gpuSelection.split(",").map(function(s){ return s.trim(); }).filter(function(s){ return s.length > 0; });
    }

    readonly property var _activeSensorIds: {
        var ids = [];
        for (var i = 0; i < _activeIds.length; i++) {
            var g = _activeIds[i];
            ids.push("gpu/" + g + "/usage");
            ids.push("gpu/" + g + "/usedVram");
            ids.push("gpu/" + g + "/totalVram");
            ids.push("gpu/" + g + "/temperature");
        }
        return ids;
    }

    // -------------------------------------------------------------------------
    // Step 3: Single SensorDataModel — polls ONLY the selected sensors
    // -------------------------------------------------------------------------

    Sensors.SensorDataModel {
        id: gpuData
        sensors: root._activeSensorIds
        updateRateLimit: root.updateInterval
        enabled: root._activeSensorIds.length > 0

        onDataChanged: root.aggregate()
        onReadyChanged: { if (ready) root.aggregate(); }
    }

    // -------------------------------------------------------------------------
    // Step 4: Aggregate values — label resolution: custom label > default name > "GPU N"
    // -------------------------------------------------------------------------

    function _modelValue(sensorId) {
        var col = gpuData.column(sensorId);
        if (col < 0) return NaN;
        var idx = gpuData.index(0, col);
        if (!idx.valid) return NaN;
        var val = gpuData.data(idx, Sensors.SensorDataModel.Value);
        return (val === undefined || val === null) ? NaN : val;
    }

    function aggregate() {
        var ids = _activeIds;
        var customLabels = parseGpuLabels(gpuLabels);
        var newList = [];
        var totalUsage = 0, usageCount = 0;
        var totalVramUsed = 0, totalVramTotal = 0, hasVram = false;
        var maxTemp = NaN;

        for (var i = 0; i < ids.length; i++) {
            var g = ids[i];

            // Resolve display name: custom label > default name > fallback
            var hwName = "GPU " + (i + 1);
            for (var j = 0; j < _discovered.length; j++) {
                if (_discovered[j].id === g) { hwName = _discovered[j].name; break; }
            }
            var name = customLabels[g] || hwName;

            var uVal  = _modelValue("gpu/" + g + "/usage");
            var vuVal = _modelValue("gpu/" + g + "/usedVram");
            var vtVal = _modelValue("gpu/" + g + "/totalVram");
            var tVal  = _modelValue("gpu/" + g + "/temperature");

            var uStr = isNaN(uVal) ? "" : Math.round(uVal) + "%";
            var vStr = "";
            if (!isNaN(vuVal) && !isNaN(vtVal) && vtVal > 0 && vuVal >= 0)
                vStr = Utils.formatBytes(vuVal) + "/" + Utils.formatBytes(vtVal) + "G";
            // tVal === 0 is ksystemstats' null sentinel for iGPU: no hwmon node exists,
            // so the driver reports exactly 0. No real GPU can be at or below 0°C.
            var tStr = (isNaN(tVal) || tVal <= 0) ? "" : Math.round(tVal) + "°C";

            newList.push({ id: g, name: name,
                           usage: uStr, vram: vStr, temp: tStr,
                           usageNumber: isNaN(uVal) ? NaN : uVal,
                           tempNumber:  (isNaN(tVal) || tVal <= 0) ? NaN : tVal });

            if (!isNaN(uVal)) { totalUsage += uVal; usageCount++; }
            if (!isNaN(vuVal) && !isNaN(vtVal) && vtVal > 0 && vuVal >= 0) {
                totalVramUsed  += vuVal;
                totalVramTotal += vtVal;
                hasVram = true;
            }
            if (!isNaN(tVal) && tVal > 0 && (isNaN(maxTemp) || tVal > maxTemp)) maxTemp = tVal;
        }

        _dataList = newList;

        _usageNum = usageCount > 0 ? totalUsage / usageCount : NaN;
        _usageStr = usageCount > 0 ? Math.round(_usageNum) + "%" : "";
        _vramStr  = (hasVram && totalVramTotal > 0)
                    ? Utils.formatBytes(totalVramUsed) + "/" + Utils.formatBytes(totalVramTotal) + "G" : "";
        _tempNum  = isNaN(maxTemp) ? NaN : maxTemp;
        _tempStr  = isNaN(maxTemp) ? "" : Math.round(maxTemp) + "°C";
    }

    // Re-aggregate when labels or selection change so panel updates immediately
    onGpuLabelsChanged:    aggregate()
    onGpuSelectionChanged: aggregate()
}
