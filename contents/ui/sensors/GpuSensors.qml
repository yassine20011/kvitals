import QtQuick
import org.kde.ksysguard.sensors as Sensors
import "../models/MetricDefinitions.js" as MetricDefinitions

Item {
    id: root

    property var discovery: null
    property int updateInterval: 2000

    // Comma-separated selected GPU IDs e.g. "gpu0,gpu1". Empty = all discovered.
    property string gpuSelection: ""

    // User-defined labels: "gpu0:My iGPU|gpu1:dGPU". Empty string = use default "GPU N" name.
    property string gpuLabels: ""

    // Temperature unit: "C" (default) or "F"
    property string tempUnit: "C"

    // Global GPU sub-metric visibility e.g. "usage,vram,temp" or "usage,temp"
    property string gpuSubMetrics: MetricDefinitions.GROUPS.gpu.defaultSubMetrics

    // Legacy per-GPU sub-metric visibility (fallback compatibility)
    property string gpuMetrics: ""

    // List of { id: "gpu0", name: "GPU 1" } derived from HardwareDiscovery
    readonly property var discoveredGpus: _discovered
    property var _discovered: []

    // Aggregated display (single-GPU compat)
    readonly property real gpuUsageNumber: _usageNum
    readonly property real gpuTempNumber:  _tempNum
    readonly property string gpuValue:     _usageStr
    readonly property string gpuRamValue:  _vramStr
    readonly property string gpuTempValue: _tempStr
    readonly property string gpuDisplayValue:
        [_usageStr, _vramStr, _tempStr].filter(function(v){return v;}).join(" ")
    readonly property bool hasGpuData:      gpuDisplayValue.length > 0
    readonly property bool hasGpuUsageData: _usageStr.length > 0
    readonly property bool hasGpuVramData:  _vramStr.length  > 0
    readonly property bool hasGpuTempData:  _tempStr.length  > 0

    // Per-GPU list for multi display: [{ id, name, usage, vram, temp, usageNumber, tempNumber }]
    readonly property var gpuDataList: _dataList
    property var _dataList: []

    property real _usageNum: NaN
    property real _tempNum:  NaN
    property string _usageStr: ""
    property string _vramStr:  ""
    property string _tempStr:  ""

    // -------------------------------------------------------------------------
    // Step 1: Discover available GPUs via HardwareDiscovery
    // -------------------------------------------------------------------------

    // Parse "gpu0:Label A|gpu1:Label B" -> { gpu0: "Label A", gpu1: "Label B" }
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

    // Parse sub-metrics string e.g. "gpu0:usage,vram,temp|gpu1:usage,temp" or global "usage,vram,temp"
    function parseGpuSubMetrics(str, gpuId) {
        var defaultList = MetricDefinitions.GROUPS.gpu.defaultSubMetrics.split(",").map(function(s){ return s.trim(); });
        if (!str || str.length === 0) return defaultList;
        if (str.indexOf(":") >= 0) {
            var pairs = str.split("|");
            for (var i = 0; i < pairs.length; i++) {
                var sep = pairs[i].indexOf(":");
                if (sep > 0 && pairs[i].substring(0, sep) === gpuId) {
                    var subs = pairs[i].substring(sep + 1).split(",").map(function(s){ return s.trim(); }).filter(function(m){
                        return m.length > 0;
                    });
                    return subs.length > 0 ? subs : defaultList;
                }
            }
            return defaultList;
        }
        var list = str.split(",").map(function(s){ return s.trim(); }).filter(function(s){
            return s.length > 0;
        });
        return list.length > 0 ? list : defaultList;
    }

    function refreshDiscovered() {
        if (!discovery) return;
        var found = [];
        var pattern = MetricDefinitions.PATTERNS ? MetricDefinitions.PATTERNS.GPU : /^gpu\/(gpu\d+)\/usage$/;
        var ids = discovery.queryIds(pattern);
        for (var i = 0; i < ids.length; i++) {
            var match = ids[i].match(pattern);
            if (!match) continue;
            found.push({ id: match[1], name: "GPU " + (found.length + 1) });
        }

        if (JSON.stringify(found) !== JSON.stringify(_discovered)) {
            _discovered = found;
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

    // -------------------------------------------------------------------------
    // Step 2: Compute active sensor IDs — per GPU, only poll enabled sub-metrics
    // -------------------------------------------------------------------------

    readonly property var _activeIds: {
        if (!gpuSelection || gpuSelection === "")
            return _discovered.map(function(g){ return g.id; });
        if (gpuSelection === "none")
            return [];
        return gpuSelection.split(",")
            .map(function(s){ return s.trim(); })
            .filter(function(s){ return s.length > 0; });
    }

    readonly property var _activeSensorIds: {
        var ids = [];
        var rawStr = gpuSubMetrics || gpuMetrics;
        for (var i = 0; i < _activeIds.length; i++) {
            var g = _activeIds[i];
            var m = parseGpuSubMetrics(rawStr, g);
            if (m.indexOf("usage") >= 0) ids.push("gpu/" + g + "/usage");
            if (m.indexOf("vram")  >= 0) {
                ids.push("gpu/" + g + "/usedVram");
                ids.push("gpu/" + g + "/totalVram");
            }
            if (m.indexOf("temp")  >= 0) ids.push("gpu/" + g + "/temperature");
            if (m.indexOf("freq")  >= 0) ids.push("gpu/" + g + "/coreFrequency");
            if (m.indexOf("power") >= 0) ids.push("gpu/" + g + "/power");
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
        var rawStr = gpuSubMetrics || gpuMetrics;
        var newList = [];
        var totalUsage = 0, usageCount = 0;
        var totalVramUsed = 0, totalVramTotal = 0, hasVram = false;
        var maxTemp = NaN;

        for (var i = 0; i < ids.length; i++) {
            var g = ids[i];
            var m = parseGpuSubMetrics(rawStr, g);
            var showU = m.indexOf("usage") >= 0;
            var showV = m.indexOf("vram")  >= 0;
            var showT = m.indexOf("temp")  >= 0;
            var showF = m.indexOf("freq")  >= 0;
            var showP = m.indexOf("power") >= 0;

            // Resolve display name: custom label > default name > fallback
            var hwName = "GPU " + (i + 1);
            for (var j = 0; j < _discovered.length; j++) {
                if (_discovered[j].id === g) { hwName = _discovered[j].name; break; }
            }
            var name = customLabels[g] || hwName;

            var uVal  = showU ? _modelValue("gpu/" + g + "/usage")         : NaN;
            var vuVal = showV ? _modelValue("gpu/" + g + "/usedVram")       : NaN;
            var vtVal = showV ? _modelValue("gpu/" + g + "/totalVram")      : NaN;
            var tVal  = showT ? _modelValue("gpu/" + g + "/temperature")    : NaN;
            var fVal  = showF ? _modelValue("gpu/" + g + "/coreFrequency")  : NaN;
            var pVal  = showP ? _modelValue("gpu/" + g + "/power")          : NaN;

            var uStr = !isNaN(uVal) ? Math.round(uVal).toString().padStart(3) + "%" : "";
            var vStr = "";
            if (!isNaN(vuVal) && !isNaN(vtVal) && vtVal > 0 && vuVal >= 0)
                vStr = Utils.formatBytes(vuVal) + "/" + Utils.formatBytes(vtVal) + "G";
            // tVal === 0 is ksystemstats' null sentinel for iGPU (no hwmon node)
            var tStr = (!isNaN(tVal) && tVal > 0) ? Utils.formatTemp(tVal, tempUnit) : "";
            var fStr = "";
            if (!isNaN(fVal) && fVal > 0) {
                if (fVal >= 1000) fStr = (fVal / 1000).toFixed(2) + " GHz";
                else fStr = Math.round(fVal) + " MHz";
            }
            var pStr = (!isNaN(pVal) && pVal > 0) ? pVal.toFixed(1) + "W" : "";

            newList.push({ id: g, name: name,
                           usage: uStr, vram: vStr, temp: tStr, freq: fStr, power: pStr,
                           usageNumber: !isNaN(uVal) ? uVal : NaN,
                           tempNumber:  (!isNaN(tVal) && tVal > 0) ? tVal : NaN,
                           freqNumber:  (!isNaN(fVal) && fVal > 0) ? fVal : NaN,
                           powerNumber: (!isNaN(pVal) && pVal > 0) ? pVal : NaN });

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
        _usageStr = usageCount > 0 ? Math.round(_usageNum).toString().padStart(3) + "%" : "";
        
        _vramStr  = (hasVram && totalVramTotal > 0)
                    ? Utils.formatBytes(totalVramUsed) + "/" + Utils.formatBytes(totalVramTotal) + "G" : "";
        _tempNum  = !isNaN(maxTemp) ? maxTemp : NaN;
        _tempStr  = !isNaN(maxTemp) ? Utils.formatTemp(maxTemp, tempUnit) : "";
    }

    // Re-aggregate when sub-metrics, labels, selection, or unit change
    onGpuSubMetricsChanged: aggregate()
    onGpuMetricsChanged:    aggregate()
    onGpuLabelsChanged:     aggregate()
    onGpuSelectionChanged:  aggregate()
    onTempUnitChanged:      aggregate()
}
