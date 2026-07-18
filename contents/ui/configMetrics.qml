import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.ksysguard.sensors as Sensors
import org.kde.kitemmodels as KItemModels

KCM.SimpleKCM {
    id: metricsPage

    // --- cfg_ bindings (must match main.xml keys exactly) ---
    property bool cfg_showCpu
    property bool cfg_showRam
    property bool cfg_showTemp
    property bool cfg_showGpu
    property bool cfg_showBattery
    property bool cfg_showPower
    property bool cfg_showNetwork
    property bool cfg_showDisk
    property bool cfg_showFan
    property bool cfg_showUptime
    property bool cfg_compactShowCpu
    property bool cfg_compactShowRam
    property bool cfg_compactShowTemp
    property bool cfg_compactShowGpu
    property bool cfg_compactShowBattery
    property bool cfg_compactShowPower
    property bool cfg_compactShowNetwork
    property bool cfg_compactShowDisk
    property bool cfg_compactShowFan
    property bool cfg_compactShowUptime
    property string cfg_cpuLabel: "CPU"
    property string cfg_networkInterface: "auto"
    property bool cfg_showNetworkIp: false
    property string cfg_batteryDevice
    property string cfg_gpuSelection: ""
    property string cfg_gpuLabels: ""
    property string cfg_metricOrder: "cpu,ram,temp,gpu,bat,pwr,net,disk"
    property bool cfg_mergeCpuTemp: false
    property bool cfg_mergeCpuFreq: false
    property bool cfg_mergeBatPwr: false
    property bool cfg_splitGpu: false
    property string cfg_gpuMetrics: ""
    property bool cfg_showCpuFreq: false

    // --- GPU discovery via SensorTreeModel (pure metadata, no polling) ---
    Sensors.SensorTreeModel { id: cfgSensorTree }
    KItemModels.KDescendantsProxyModel { id: cfgFlatSensors; model: cfgSensorTree }

    property var _liveDiscoveredGpus: []

    Timer {
        id: gpuRefreshDebounce
        interval: 100
        repeat: false
        onTriggered: {
            var found = [];
            for (var row = 0; row < cfgFlatSensors.rowCount(); row++) {
                var idx = cfgFlatSensors.index(row, 0);
                var sensorId = cfgFlatSensors.data(idx, Sensors.SensorTreeModel.SensorId);
                if (!sensorId || sensorId.length === 0) continue;
                var match = sensorId.match(/^gpu\/(gpu\d+)\/usage$/);
                if (!match) continue;
                found.push({ id: match[1], name: "GPU " + (found.length + 1) });
            }
            if (JSON.stringify(found) !== JSON.stringify(_liveDiscoveredGpus))
                _liveDiscoveredGpus = found;
        }
    }

    function refreshConfigGpus() {
        gpuRefreshDebounce.restart();
    }

    property bool _discoveryDirty: false

    Timer {
        id: discoveryTimer
        interval: 500
        repeat: false
        running: _discoveryDirty
        onTriggered: {
            _discoveryDirty = false;
            metricsPage.refreshConfigGpus();
        }
    }

    Connections {
        target: cfgFlatSensors
        function onRowsInserted() { metricsPage._discoveryDirty = true; }
        function onRowsRemoved()  { metricsPage._discoveryDirty = true; }
        function onModelReset()   { metricsPage._discoveryDirty = true; }
        function onDataChanged()  { metricsPage._discoveryDirty = true; }
    }

    readonly property var discoveredGpus: {
        if (_liveDiscoveredGpus.length > 0) return _liveDiscoveredGpus;
        if (!cfg_gpuDiscovered) return [];
        return cfg_gpuDiscovered.split(",").filter(function(s){ return s.indexOf(":") >= 0; }).map(function(s){
            var parts = s.split(":");
            return { id: parts[0], name: parts.slice(1).join(":") };
        });
    }

    // --- Network interface discovery ---
    property var ifaceList: ["auto"]

    Plasma5Support.DataSource {
        id: ifaceSource
        engine: "executable"
        connectedSources: ["ls /sys/class/net/"]
        onNewData: function (source, data) {
            if (data["exit code"] !== 0) return;
            var raw = data["stdout"].trim();
            if (raw.length === 0) return;
            var ifaces = raw.split("\n").filter(function (name) {
                return name !== "lo" && name.length > 0;
            });
            ifaces.unshift("auto");
            metricsPage.ifaceList = ifaces;
        }
    }

    // --- GPU label helpers ---
    function parseGpuLabels(str) {
        var result = {};
        if (!str) return result;
        str.split("|").forEach(function(pair) {
            var sep = pair.indexOf(":");
            if (sep > 0) result[pair.substring(0, sep)] = pair.substring(sep + 1);
        });
        return result;
    }

    function saveGpuLabel(gpuId, label) {
        var labels = parseGpuLabels(cfg_gpuLabels);
        var trimmed = (label || "").trim();
        if (trimmed.length > 0) labels[gpuId] = trimmed;
        else delete labels[gpuId];
        var parts = [];
        for (var id in labels) parts.push(id + ":" + labels[id]);
        cfg_gpuLabels = parts.join("|");
    }

    // --- GPU sub-metric helpers ---
    function parseGpuMetrics(str) {
        var result = {};
        if (!str) return result;
        str.split("|").forEach(function(pair) {
            var sep = pair.indexOf(":");
            if (sep <= 0) return;
            var id = pair.substring(0, sep);
            var metrics = pair.substring(sep + 1).split(",").filter(function(m){
                return m === "usage" || m === "vram" || m === "temp";
            });
            if (metrics.length > 0) result[id] = metrics;
        });
        return result;
    }

    function gpuMetricsFor(gpuId) {
        var mm = parseGpuMetrics(cfg_gpuMetrics);
        return (mm[gpuId] && mm[gpuId].length > 0) ? mm[gpuId] : ["usage", "vram", "temp"];
    }

    function saveGpuMetric(gpuId, metric, enable) {
        var mm = parseGpuMetrics(cfg_gpuMetrics);
        var current = mm[gpuId] ? mm[gpuId].slice() : ["usage", "vram", "temp"];
        if (enable) {
            if (current.indexOf(metric) < 0) current.push(metric);
        } else {
            if (current.length <= 1) return;
            current = current.filter(function(m){ return m !== metric; });
        }
        var order = ["usage", "vram", "temp"];
        current.sort(function(a, b){ return order.indexOf(a) - order.indexOf(b); });
        if (current.length === 3) delete mm[gpuId];
        else mm[gpuId] = current;
        var parts = [];
        for (var id in mm) parts.push(id + ":" + mm[id].join(","));
        cfg_gpuMetrics = parts.join("|");
    }

    // --- Metric order helpers ---
    readonly property var allKeys: ["cpu", "ram", "temp", "gpu", "bat", "pwr", "net", "disk", "fan", "uptime"]

    readonly property var metricMeta: ({
        "cpu":  { label: i18n("CPU usage"),         icon: "cpu" },
        "ram":  { label: i18n("RAM usage"),          icon: "memory" },
        "temp": { label: i18n("CPU temperature"),    icon: "temperature-normal" },
        "gpu":  { label: i18n("GPU metrics"),        icon: "video-card" },
        "bat":  { label: i18n("Battery status"),     icon: "battery-good" },
        "pwr":  { label: i18n("Power consumption"),  icon: "battery-charging-60" },
        "net":  { label: i18n("Network speed"),      icon: "network-wireless" },
        "disk": { label: i18n("Disk I/O & temp"),    icon: "drive-harddisk" },
        "fan":  { label: i18n("Fan speed"),          icon: "fan" },
        "uptime": { label: i18n("System Uptime"),    icon: "clock" }
    })

    property var currentOrder: {
        var keys = cfg_metricOrder.split(",").map(function(k){ return k.trim(); })
            .filter(function(k){ return k.length > 0 && metricMeta[k] !== undefined; });
        allKeys.forEach(function(k){ if (keys.indexOf(k) < 0) keys.push(k); });
        return keys;
    }

    function isChecked(key) {
        switch (key) {
            case "cpu":  return cfg_showCpu;
            case "ram":  return cfg_showRam;
            case "temp": return cfg_showTemp;
            case "gpu":  return cfg_showGpu;
            case "bat":  return cfg_showBattery;
            case "pwr":  return cfg_showPower;
            case "net":  return cfg_showNetwork;
            case "disk": return cfg_showDisk;
            case "fan":  return cfg_showFan;
            case "uptime": return cfg_showUptime;
        }
        return false;
    }

    function isCompactChecked(key) {
        switch (key) {
            case "cpu":  return cfg_compactShowCpu;
            case "ram":  return cfg_compactShowRam;
            case "temp": return cfg_compactShowTemp;
            case "gpu":  return cfg_compactShowGpu;
            case "bat":  return cfg_compactShowBattery;
            case "pwr":  return cfg_compactShowPower;
            case "net":  return cfg_compactShowNetwork;
            case "disk": return cfg_compactShowDisk;
            case "fan":  return cfg_compactShowFan;
            case "uptime": return cfg_compactShowUptime;
        }
        return false;
    }

    function setChecked(key, val) {
        switch (key) {
            case "cpu":  cfg_showCpu     = val; break;
            case "ram":  cfg_showRam     = val; break;
            case "temp": cfg_showTemp    = val; break;
            case "gpu":  cfg_showGpu     = val; break;
            case "bat":  cfg_showBattery = val; break;
            case "pwr":  cfg_showPower   = val; break;
            case "net":  cfg_showNetwork = val; break;
            case "disk": cfg_showDisk    = val; break;
            case "fan":  cfg_showFan     = val; break;
            case "uptime": cfg_showUptime = val; break;
        }
        if (!val) {
            if ((key === "cpu" || key === "temp") && cfg_mergeCpuTemp) cfg_mergeCpuTemp = false;
            if ((key === "bat" || key === "pwr")  && cfg_mergeBatPwr)  cfg_mergeBatPwr  = false;
            if (key === "gpu" && cfg_splitGpu) cfg_splitGpu = false;
        }
    }

    function setCompactChecked(key, val) {
        switch (key) {
            case "cpu":  cfg_compactShowCpu     = val; break;
            case "ram":  cfg_compactShowRam     = val; break;
            case "temp": cfg_compactShowTemp    = val; break;
            case "gpu":  cfg_compactShowGpu     = val; break;
            case "bat":  cfg_compactShowBattery = val; break;
            case "pwr":  cfg_compactShowPower   = val; break;
            case "net":  cfg_compactShowNetwork = val; break;
            case "disk": cfg_compactShowDisk    = val; break;
            case "fan":  cfg_compactShowFan     = val; break;
            case "uptime": cfg_compactShowUptime = val; break;
        }
    }

    function moveMetric(fromIndex, toIndex) {
        var keys = currentOrder.slice();
        var item = keys.splice(fromIndex, 1)[0];
        keys.splice(toIndex, 0, item);
        cfg_metricOrder = keys.join(",");
    }


    // =========================================================================
    // UI
    // =========================================================================
    
    // Prevent "ugly to correct" UI flash during initial layout calculations
    property bool _isReady: false
    Timer {
        id: readyTimer
        interval: 100
        running: true
        repeat: false
        onTriggered: metricsPage._isReady = true
    }
    BusyIndicator {
        anchors.centerIn: metricsPage
        running: !metricsPage._isReady
        visible: running
        z: 999
    }

    Kirigami.FormLayout {
        opacity: metricsPage._isReady ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        // ----- Section header -----
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Visibility & Order")
        }

        // Column headers row
        RowLayout {
            spacing: Kirigami.Units.smallSpacing

            Label {
                text: i18n("Metric (Full view)")
                font.bold: true
                opacity: 0.7
                Layout.preferredWidth: Kirigami.Units.gridUnit * 14
            }
            Label {
                text: i18n("Compact")
                font.bold: true
                opacity: 0.7
                Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                horizontalAlignment: Text.AlignHCenter
            }
            Item { Layout.fillWidth: true }
        }

        // Metric rows
        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true

            Repeater {
                model: metricsPage.currentOrder

                delegate: ColumnLayout {
                    id: metricDelegate
                    required property var modelData
                    required property int index

                    spacing: 0
                    Layout.fillWidth: true

                    // Hide metrics absorbed by a merge group
                    visible: !(modelData === "temp" && cfg_mergeCpuTemp && cfg_showCpu) &&
                             !(modelData === "pwr"  && cfg_mergeBatPwr  && cfg_showBattery)

                    // Resolved shorthands for readability inside this delegate
                    readonly property bool metricEnabled: metricsPage.isChecked(modelData)
                    readonly property string metricLabel: (metricsPage.metricMeta[modelData] || {}).label || modelData
                    readonly property string metricIcon:  (metricsPage.metricMeta[modelData] || {}).icon  || "help-about"

                    // ── Main row ──────────────────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        // Metric toggle
                        CheckBox {
                            id: enabledCheck
                            text: metricDelegate.metricLabel
                            checked: metricDelegate.metricEnabled
                            onToggled: metricsPage.setChecked(modelData, checked)
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 14
                        }

                        // Compact-view toggle
                        Item {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                            Layout.minimumHeight: compactCheck.implicitHeight
                            CheckBox {
                                id: compactCheck
                                anchors.centerIn: parent
                                checked: metricsPage.isCompactChecked(modelData)
                                enabled: metricDelegate.metricEnabled
                                onToggled: metricsPage.setCompactChecked(modelData, checked)
                                // Accessible name for keyboard/screen-reader users
                                Accessible.name: i18n("Show %1 in compact panel", metricDelegate.metricLabel)
                            }
                        }

                        // Spacer
                        Item { Layout.fillWidth: true }

                        // Reorder buttons
                        Button {
                            icon.name: "arrow-up"
                            flat: true
                            enabled: index > 0
                            implicitWidth:  Kirigami.Units.gridUnit * 2
                            implicitHeight: Kirigami.Units.gridUnit * 2
                            onClicked: metricsPage.moveMetric(index, index - 1)
                            ToolTip.text: i18n("Move up")
                            ToolTip.visible: hovered
                            ToolTip.delay: Kirigami.Units.toolTipDelay
                        }
                        Button {
                            icon.name: "arrow-down"
                            flat: true
                            enabled: index < metricsPage.currentOrder.length - 1
                            implicitWidth:  Kirigami.Units.gridUnit * 2
                            implicitHeight: Kirigami.Units.gridUnit * 2
                            onClicked: metricsPage.moveMetric(index, index + 1)
                            ToolTip.text: i18n("Move down")
                            ToolTip.visible: hovered
                            ToolTip.delay: Kirigami.Units.toolTipDelay
                        }
                    }

                    // ── Inline per-metric settings (visible only when enabled) ──
                    // Each block is keyed to its metric so context is never lost.

                    // CPU settings
                    Loader {
                        active: modelData === "cpu" && metricDelegate.metricEnabled
                        visible: active
                        Layout.fillWidth: true
                        Layout.leftMargin: Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing
                        Layout.topMargin: Kirigami.Units.smallSpacing

                        sourceComponent: ColumnLayout {
                            spacing: Kirigami.Units.smallSpacing

                            RowLayout {
                                spacing: Kirigami.Units.smallSpacing
                                Label { text: i18n("Label:"); opacity: 0.8 }
                                TextField {
                                    implicitWidth: Kirigami.Units.gridUnit * 12
                                    text: cfg_cpuLabel
                                    placeholderText: i18n("CPU")
                                    onTextEdited: cfg_cpuLabel = text.trim() || "CPU"
                                }
                            }

                            RowLayout {
                                spacing: Kirigami.Units.largeSpacing
                                CheckBox {
                                    text: i18n("Show CPU frequency")
                                    checked: cfg_showCpuFreq
                                    onToggled: {
                                        cfg_showCpuFreq = checked;
                                        if (!checked) cfg_mergeCpuFreq = false;
                                    }
                                }
                                CheckBox {
                                    text: i18n("Merge frequency into compact view")
                                    checked: cfg_mergeCpuFreq
                                    enabled: cfg_showCpuFreq
                                    onToggled: cfg_mergeCpuFreq = checked
                                }
                            }
                            CheckBox {
                                visible: cfg_showTemp
                                text: i18n("Show temperature next to usage (merge CPU & temp)")
                                checked: cfg_mergeCpuTemp
                                enabled: cfg_showTemp
                                onToggled: cfg_mergeCpuTemp = checked
                            }
                        }
                    }

                    // Network settings
                    Loader {
                        active: modelData === "net" && metricDelegate.metricEnabled
                        visible: active
                        Layout.fillWidth: true
                        Layout.leftMargin: Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing
                        Layout.topMargin: Kirigami.Units.smallSpacing

                        sourceComponent: ColumnLayout {
                            spacing: Kirigami.Units.smallSpacing

                            RowLayout {
                                spacing: Kirigami.Units.smallSpacing
                                Label { text: i18n("Interface:") }
                                ComboBox {
                                    id: ifaceCombo
                                    model: metricsPage.ifaceList
                                    currentIndex: {
                                        var idx = metricsPage.ifaceList.indexOf(cfg_networkInterface);
                                        return idx >= 0 ? idx : 0;
                                    }
                                    onActivated: cfg_networkInterface = metricsPage.ifaceList[currentIndex]
                                    implicitWidth: Kirigami.Units.gridUnit * 10
                                }
                            }

                            CheckBox {
                                text: i18n("Show Local IP Address")
                                checked: cfg_showNetworkIp
                                onToggled: cfg_showNetworkIp = checked
                            }
                        }
                    }

                    // Battery settings
                    Loader {
                        active: modelData === "bat" && metricDelegate.metricEnabled
                        visible: active
                        Layout.fillWidth: true
                        Layout.leftMargin: Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing
                        Layout.topMargin: Kirigami.Units.smallSpacing

                        sourceComponent: ColumnLayout {
                            spacing: Kirigami.Units.smallSpacing

                            RowLayout {
                                spacing: Kirigami.Units.smallSpacing
                                Label { text: i18n("Device:") }
                                TextField {
                                    id: batteryInput
                                    text: cfg_batteryDevice === "auto" ? "" : cfg_batteryDevice
                                    placeholderText: i18n("Leave empty for auto-detect (e.g. BAT0)")
                                    implicitWidth: Kirigami.Units.gridUnit * 14
                                    onTextEdited: {
                                        var v = text.trim();
                                        cfg_batteryDevice = v.length > 0 ? v : "auto";
                                    }
                                }
                            }
                            CheckBox {
                                visible: cfg_showPower
                                text: i18n("Show power consumption next to battery level (merge battery & power)")
                                checked: cfg_mergeBatPwr
                                enabled: cfg_showPower
                                onToggled: cfg_mergeBatPwr = checked
                            }
                        }
                    }

                    // GPU settings
                    Loader {
                        active: modelData === "gpu" && metricDelegate.metricEnabled
                        visible: active
                        Layout.fillWidth: true
                        Layout.leftMargin: Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing
                        Layout.topMargin: Kirigami.Units.smallSpacing

                        sourceComponent: ColumnLayout {
                            spacing: Kirigami.Units.smallSpacing

                            // Split GPU option
                            CheckBox {
                                text: i18n("Show usage, VRAM and temperature as separate entries (split GPU metrics)")
                                checked: cfg_splitGpu
                                onToggled: cfg_splitGpu = checked
                            }

                            // No GPU found yet (Loading state)
                            RowLayout {
                                visible: metricsPage.discoveredGpus.length === 0
                                spacing: Kirigami.Units.smallSpacing

                                BusyIndicator {
                                    running: parent.visible
                                    Layout.preferredWidth: Kirigami.Units.gridUnit
                                    Layout.preferredHeight: Kirigami.Units.gridUnit
                                }

                                Label {
                                    text: i18n("Discovering GPUs...")
                                    opacity: 0.7
                                    font.italic: true
                                }
                            }

                            // Hybrid GPU tip
                            Label {
                                visible: metricsPage.discoveredGpus.length > 1
                                text: i18n("Tip: on hybrid-GPU laptops, uncheck the discrete GPU to let it suspend and save power.")
                                opacity: 0.7
                                font.italic: true
                                wrapMode: Text.WordWrap
                                Layout.maximumWidth: Kirigami.Units.gridUnit * 24
                            }

                            // Per-GPU rows
                            Repeater {
                                id: gpuSelectorRepeater
                                model: metricsPage.discoveredGpus

                                delegate: ColumnLayout {
                                    id: gpuDelegate
                                    required property var modelData
                                    spacing: Kirigami.Units.smallSpacing
                                    Layout.fillWidth: true
                                    Layout.leftMargin: Kirigami.Units.smallSpacing

                                    property var _activeMetrics: metricsPage.gpuMetricsFor(modelData.id)

                                    property bool _gpuEnabled: {
                                        if (!cfg_gpuSelection || cfg_gpuSelection === "") return true;
                                        if (cfg_gpuSelection === "none") return false;
                                        return cfg_gpuSelection.split(",").indexOf(modelData.id) >= 0;
                                    }

                                    // GPU enable checkbox
                                    CheckBox {
                                        text: gpuDelegate.modelData.name
                                        checked: gpuDelegate._gpuEnabled
                                        onToggled: {
                                            var ids;
                                            if (!cfg_gpuSelection || cfg_gpuSelection === "") {
                                                ids = gpuSelectorRepeater.model.map(function(g){ return g.id; });
                                            } else if (cfg_gpuSelection === "none") {
                                                ids = [];
                                            } else {
                                                ids = cfg_gpuSelection.split(",").filter(function(s){ return s.length > 0; });
                                            }
                                            if (checked) {
                                                if (ids.indexOf(modelData.id) < 0) ids.push(modelData.id);
                                            } else {
                                                ids = ids.filter(function(id){ return id !== modelData.id; });
                                            }
                                            var allIds = gpuSelectorRepeater.model.map(function(g){ return g.id; });
                                            var allSelected = allIds.every(function(id){ return ids.indexOf(id) >= 0; });
                                            if (allSelected)           cfg_gpuSelection = "";
                                            else if (ids.length === 0) cfg_gpuSelection = "none";
                                            else                       cfg_gpuSelection = ids.join(",");
                                        }
                                    }

                                    // Label + sub-metrics (indented under GPU checkbox)
                                    ColumnLayout {
                                        enabled: gpuDelegate._gpuEnabled
                                        opacity: gpuDelegate._gpuEnabled ? 1.0 : 0.4
                                        spacing: Kirigami.Units.smallSpacing
                                        Layout.leftMargin: Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing

                                        // Custom label
                                        RowLayout {
                                            spacing: Kirigami.Units.smallSpacing
                                            Label { text: i18n("Label:"); opacity: 0.8 }
                                            TextField {
                                                implicitWidth: Kirigami.Units.gridUnit * 12
                                                text: metricsPage.parseGpuLabels(cfg_gpuLabels)[gpuDelegate.modelData.id] || ""
                                                placeholderText: gpuDelegate.modelData.name
                                                onTextEdited: metricsPage.saveGpuLabel(gpuDelegate.modelData.id, text)
                                            }
                                        }

                                        // Sub-metric toggles
                                        RowLayout {
                                            spacing: Kirigami.Units.largeSpacing
                                            Label { text: i18n("Show:"); opacity: 0.8 }
                                            CheckBox {
                                                text: i18n("Usage")
                                                checked: gpuDelegate._activeMetrics.indexOf("usage") >= 0
                                                enabled: !(checked && gpuDelegate._activeMetrics.length <= 1)
                                                onToggled: metricsPage.saveGpuMetric(gpuDelegate.modelData.id, "usage", checked)
                                            }
                                            CheckBox {
                                                text: i18n("VRAM")
                                                checked: gpuDelegate._activeMetrics.indexOf("vram") >= 0
                                                enabled: !(checked && gpuDelegate._activeMetrics.length <= 1)
                                                onToggled: metricsPage.saveGpuMetric(gpuDelegate.modelData.id, "vram", checked)
                                            }
                                            CheckBox {
                                                text: i18n("Temperature")
                                                checked: gpuDelegate._activeMetrics.indexOf("temp") >= 0
                                                enabled: !(checked && gpuDelegate._activeMetrics.length <= 1)
                                                onToggled: metricsPage.saveGpuMetric(gpuDelegate.modelData.id, "temp", checked)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Thin divider between rows (not after the last visible one)
                    Rectangle {
                        visible: {
                            for (var i = index + 1; i < metricsPage.currentOrder.length; i++) {
                                var nextData = metricsPage.currentOrder[i];
                                var isHidden = (nextData === "temp" && cfg_mergeCpuTemp && cfg_showCpu) ||
                                               (nextData === "pwr"  && cfg_mergeBatPwr  && cfg_showBattery);
                                if (!isHidden) return true;
                            }
                            return false;
                        }
                        Layout.fillWidth: true
                        height: 1
                        color: Kirigami.Theme.textColor
                        opacity: 0.08
                        Layout.topMargin: Kirigami.Units.smallSpacing
                        Layout.bottomMargin: Kirigami.Units.smallSpacing
                    }
                }
            }
        }
    }
}
