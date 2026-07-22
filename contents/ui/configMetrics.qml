import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.ksysguard.sensors as Sensors
import org.kde.kitemmodels as KItemModels

KCM.SimpleKCM {
    id: metricsPage

    // ── cfg_ bindings ──────────────────────────────────────────────────────

    property bool cfg_cpuEnabled
    property string cfg_cpuSubMetrics: "usage,freq,temp"
    property string cfg_cpuLabel: "CPU"
    property string cfg_cpuVisibility: "both"

    property bool cfg_ramEnabled
    property string cfg_ramSubMetrics: "percentage"
    property string cfg_ramLabel: "RAM"
    property bool cfg_ramWidgetShowBoth: false
    property string cfg_ramVisibility: "both"

    property bool cfg_tempEnabled
    property string cfg_tempLabel: "System"
    property string cfg_tempVisibility: "both"

    property bool cfg_gpuEnabled
    property string cfg_gpuMetrics: ""
    property string cfg_gpuSelection: ""
    property string cfg_gpuLabels: ""
    property string cfg_gpuVisibility: "both"

    property bool cfg_batEnabled
    property string cfg_batSubMetrics: "percentage,power"
    property string cfg_batVisibility: "both"

    property bool cfg_netEnabled
    property string cfg_netSubMetrics: "down,up"
    property string cfg_netLabel: "NET"
    property string cfg_networkInterface: "auto"
    property bool cfg_showNetworkIp: false
    property string cfg_netVisibility: "both"

    property bool cfg_diskEnabled
    property string cfg_diskSubMetrics: "read,write"
    property string cfg_diskLabel: "DSK"
    property string cfg_diskLabels: ""
    property string cfg_diskVisibility: "both"

    property bool cfg_fanEnabled
    property string cfg_fanLabel: "FAN"
    property string cfg_fanLabels: ""
    property int cfg_fanMaxRpm: 2000
    property string cfg_fanVisibility: "both"
    property bool cfg_uptimeEnabled
    property string cfg_uptimeVisibility: "both"

    property string cfg_metricOrder: "cpu,ram,temp,gpu,bat,net,disk,fan,uptime"
    property string cfg_batteryDevice

    // ── Icon bindings (from configIcons.qml, shared across config pages) ───

    property string cfg_cpuIcon:     "am-cpu-symbolic"
    property string cfg_ramIcon:     "nvidia-ram-symbolic"
    property string cfg_tempIcon:    "temperature-normal"
    property string cfg_gpuIcon:     "gpu-symbolic"
    property string cfg_batteryIcon: "battery-good"
    property string cfg_powerIcon:   "battery-charging-60"
    property string cfg_networkIcon: "network-wireless"
    property string cfg_diskIcon:    "am-disk-utility-symbolic"
    property string cfg_fanIcon:     "am-fan-symbolic"
    property string cfg_uptimeIcon:  "clock"

    // ── Category metadata ──────────────────────────────────────────────────

    readonly property var allKeys: ["cpu", "ram", "temp", "gpu", "bat", "net", "disk", "fan", "uptime"]

    function iconFor(key) {
        switch (key) {
            case "cpu":    return cfg_cpuIcon;
            case "ram":    return cfg_ramIcon;
            case "temp":   return cfg_tempIcon;
            case "gpu":    return cfg_gpuIcon;
            case "bat":    return cfg_batteryIcon;
            case "net":    return cfg_networkIcon;
            case "disk":   return cfg_diskIcon;
            case "fan":    return cfg_fanIcon;
            case "uptime": return cfg_uptimeIcon;
        }
        return "help-about";
    }

    readonly property var metricMeta: ({
        "cpu":  { label: i18n("CPU"),              subs: [
            {key: "usage", label: i18n("Usage")},
            {key: "freq",  label: i18n("Frequency")},
            {key: "temp",  label: i18n("Temperature")}
        ]},
        "ram":  { label: i18n("RAM"),              subs: [
            {key: "percentage", label: i18n("Percentage")},
            {key: "used",       label: i18n("Used / Total")},
            {key: "temp",       label: i18n("Temperature (DDR5)")}
        ]},
        "temp": { label: i18n("Temperature"),      subs: []},
        "gpu":  { label: i18n("GPU"),              subs: [
            {key: "usage", label: i18n("Usage")},
            {key: "vram",  label: i18n("VRAM")},
            {key: "temp",  label: i18n("Temperature")}
        ]},
        "bat":  { label: i18n("Battery"),          subs: [
            {key: "percentage", label: i18n("Percentage")},
            {key: "power",      label: i18n("Power consumption")}
        ]},
        "net":  { label: i18n("Network"),          subs: [
            {key: "down", label: i18n("Download")},
            {key: "up",   label: i18n("Upload")},
            {key: "ip",   label: i18n("IP address")}
        ]},
        "disk": { label: i18n("Disk"),             subs: [
            {key: "read",  label: i18n("Read")},
            {key: "write", label: i18n("Write")},
            {key: "temp",  label: i18n("Temperature")}
        ]},
        "fan":  { label: i18n("Fan"),              subs: []},
        "uptime": { label: i18n("System Uptime"),  subs: []}
    })

    // ── Sub-metric helpers ─────────────────────────────────────────────────

    function subMetrics(key) {
        var str;
        switch (key) {
            case "cpu":  str = cfg_cpuSubMetrics;  break;
            case "ram":  str = cfg_ramSubMetrics;  break;
            case "bat":  str = cfg_batSubMetrics;  break;
            case "net":  str = cfg_netSubMetrics;  break;
            case "disk": str = cfg_diskSubMetrics; break;
            default:     str = "";
        }
        return str ? str.split(",").filter(function(s){ return s.length > 0; }) : [];
    }

    function isEnabled(key) {
        switch (key) {
            case "cpu":    return cfg_cpuEnabled;
            case "ram":    return cfg_ramEnabled;
            case "temp":   return cfg_tempEnabled;
            case "gpu":    return cfg_gpuEnabled;
            case "bat":    return cfg_batEnabled;
            case "net":    return cfg_netEnabled;
            case "disk":   return cfg_diskEnabled;
            case "fan":    return cfg_fanEnabled;
            case "uptime": return cfg_uptimeEnabled;
        }
        return false;
    }

    function setEnabled(key, val) {
        switch (key) {
            case "cpu":    cfg_cpuEnabled    = val; break;
            case "ram":    cfg_ramEnabled    = val; break;
            case "temp":   cfg_tempEnabled   = val; break;
            case "gpu":    cfg_gpuEnabled    = val; break;
            case "bat":    cfg_batEnabled    = val; break;
            case "net":    cfg_netEnabled    = val; break;
            case "disk":   cfg_diskEnabled   = val; break;
            case "fan":    cfg_fanEnabled    = val; break;
            case "uptime": cfg_uptimeEnabled = val; break;
        }
    }

    function visibilityFor(key) {
        switch (key) {
            case "cpu":    return cfg_cpuVisibility;
            case "ram":    return cfg_ramVisibility;
            case "temp":   return cfg_tempVisibility;
            case "gpu":    return cfg_gpuVisibility;
            case "bat":    return cfg_batVisibility;
            case "net":    return cfg_netVisibility;
            case "disk":   return cfg_diskVisibility;
            case "fan":    return cfg_fanVisibility;
            case "uptime": return cfg_uptimeVisibility;
        }
        return "both";
    }

    function setVisibility(key, val) {
        switch (key) {
            case "cpu":    cfg_cpuVisibility    = val; break;
            case "ram":    cfg_ramVisibility    = val; break;
            case "temp":   cfg_tempVisibility   = val; break;
            case "gpu":    cfg_gpuVisibility    = val; break;
            case "bat":    cfg_batVisibility    = val; break;
            case "net":    cfg_netVisibility    = val; break;
            case "disk":   cfg_diskVisibility   = val; break;
            case "fan":    cfg_fanVisibility    = val; break;
            case "uptime": cfg_uptimeVisibility = val; break;
        }
    }

    function toggleSubMetric(key, sub, enable) {
        var list = subMetrics(key);
        if (enable) {
            if (list.indexOf(sub) < 0) list.push(sub);
        } else {
            if (list.length <= 1) return;
            list = list.filter(function(s){ return s !== sub; });
        }
        var canonical = metricMeta[key].subs.map(function(s){ return s.key; });
        list.sort(function(a, b){ return canonical.indexOf(a) - canonical.indexOf(b); });
        var str = list.join(",");
        switch (key) {
            case "cpu":  cfg_cpuSubMetrics  = str; break;
            case "ram":  cfg_ramSubMetrics  = str; break;
            case "bat":  cfg_batSubMetrics  = str; break;
            case "net":  cfg_netSubMetrics  = str; break;
            case "disk": cfg_diskSubMetrics = str; break;
        }
    }

    // ── Ordering ───────────────────────────────────────────────────────────

    readonly property var currentOrder: {
        var keys = cfg_metricOrder.split(",").map(function(k){ return k.trim(); })
            .filter(function(k){ return k.length > 0 && metricMeta[k] !== undefined; });
        allKeys.forEach(function(k){ if (keys.indexOf(k) < 0) keys.push(k); });
        return keys;
    }

    function moveMetric(fromIndex, toIndex) {
        var keys = currentOrder.slice();
        var item = keys.splice(fromIndex, 1)[0];
        keys.splice(toIndex, 0, item);
        cfg_metricOrder = keys.join(",");
    }

    // ── Sensor discovery (GPU, Disk, Network) ─────────────────────────────

    Sensors.SensorTreeModel { id: cfgSensorTree }
    KItemModels.KDescendantsProxyModel { id: cfgFlatSensors; model: cfgSensorTree }

    // GPU discovery
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

    function refreshConfigGpus() { gpuRefreshDebounce.restart(); }

    property bool _discoveryDirty: false

    Timer {
        id: discoveryTimer
        interval: 500
        repeat: false
        running: _discoveryDirty
        onTriggered: { _discoveryDirty = false; metricsPage.refreshConfigGpus(); }
    }

    Connections {
        target: cfgFlatSensors
        function onRowsInserted() { metricsPage._discoveryDirty = true; }
        function onRowsRemoved()  { metricsPage._discoveryDirty = true; }
        function onModelReset()   { metricsPage._discoveryDirty = true; }
        function onDataChanged()  { metricsPage._discoveryDirty = true; }
    }

    readonly property var discoveredGpus: _liveDiscoveredGpus

    function parseGpuMetrics(str) {
        var result = {};
        if (!str) return result;
        str.split("|").forEach(function(pair) {
            var sep = pair.indexOf(":");
            if (sep > 0) {
                var id = pair.substring(0, sep);
                var mstr = pair.substring(sep + 1);
                result[id] = mstr.length > 0 ? mstr.split(",") : [];
            }
        });
        return result;
    }

    function saveGpuMetric(gpuId, metric, enable) {
        var mm = parseGpuMetrics(cfg_gpuMetrics);
        var current = mm[gpuId] || ["usage", "vram", "temp"];
        if (enable) {
            if (current.indexOf(metric) < 0) current.push(metric);
        } else {
            current = current.filter(function(m){ return m !== metric; });
        }
        var canonical = ["usage", "vram", "temp"];
        current.sort(function(a, b){ return canonical.indexOf(a) - canonical.indexOf(b); });
        mm[gpuId] = current;
        var parts = [];
        for (var id in mm) parts.push(id + ":" + mm[id].join(","));
        cfg_gpuMetrics = parts.join("|");
    }

    // GPU label helpers
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

    // Disk discovery
    property var _liveDiscoveredDisks: []

    Timer {
        id: diskRefreshDebounce
        interval: 100
        repeat: false
        onTriggered: {
            var found = [];
            for (var row = 0; row < cfgFlatSensors.rowCount(); row++) {
                var idx = cfgFlatSensors.index(row, 0);
                var sensorId = cfgFlatSensors.data(idx, Sensors.SensorTreeModel.SensorId);
                if (!sensorId) continue;
                var match = sensorId.match(/^disk\/(nvme\d+n\d+|sd[a-z]+)\/read$/);
                if (!match) continue;
                if (found.some(function(d){ return d.id === match[1]; })) continue;
                found.push({ id: match[1], name: "DSK " + (found.length + 1) });
            }
            if (JSON.stringify(found) !== JSON.stringify(_liveDiscoveredDisks))
                _liveDiscoveredDisks = found;
        }
    }

    function refreshConfigDisks() { diskRefreshDebounce.restart(); }

    property var _discoveryDirtyDisk: false

    Timer {
        id: diskDiscoveryTimer
        interval: 500
        repeat: false
        running: _discoveryDirtyDisk
        onTriggered: { _discoveryDirtyDisk = false; metricsPage.refreshConfigDisks(); }
    }

    Connections {
        target: cfgFlatSensors
        function onRowsInserted() { metricsPage._discoveryDirtyDisk = true; }
        function onRowsRemoved()  { metricsPage._discoveryDirtyDisk = true; }
        function onModelReset()   { metricsPage._discoveryDirtyDisk = true; }
        function onDataChanged()  { metricsPage._discoveryDirtyDisk = true; }
    }

    readonly property var discoveredDisks: _liveDiscoveredDisks

    // Disk label helpers
    function parseDiskLabels(str) {
        var result = {};
        if (!str) return result;
        str.split("|").forEach(function(pair) {
            var sep = pair.indexOf(":");
            if (sep > 0) result[pair.substring(0, sep)] = pair.substring(sep + 1);
        });
        return result;
    }

    function saveDiskLabel(diskId, label) {
        var labels = parseDiskLabels(cfg_diskLabels);
        var trimmed = (label || "").trim();
        if (trimmed.length > 0) labels[diskId] = trimmed;
        else delete labels[diskId];
        var parts = [];
        for (var id in labels) parts.push(id + ":" + labels[id]);
        cfg_diskLabels = parts.join("|");
    }

    // Network interface discovery
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

    // GPU sub-metric helpers (per-device, stored in gpuSubMetrics globally)
    // gpuSubMetrics applies to all GPUs uniformly (simplification from per-GPU gpuMetrics)

    // ── UI ─────────────────────────────────────────────────────────────────

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

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Metrics Configuration")
        }

        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true

            Repeater {
                model: metricsPage.currentOrder

                delegate: ColumnLayout {
                    id: catDelegate
                    required property var modelData
                    required property int index

                    spacing: 0
                    Layout.fillWidth: true

                    readonly property string key: modelData
                    readonly property var meta: metricsPage.metricMeta[key] || {}
                    readonly property bool catEnabled: metricsPage.isEnabled(key)
                    readonly property var activeSubs: metricsPage.subMetrics(key)
                    readonly property bool hasSubs: meta.subs && meta.subs.length > 0

                    // ── Category row ────────────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Icon {
                            source: metricsPage.iconFor(catDelegate.key)
                            isMask: true
                            implicitWidth: Kirigami.Units.iconSizes.smallMedium
                            implicitHeight: Kirigami.Units.iconSizes.smallMedium
                            opacity: catDelegate.catEnabled ? 1 : 0.4
                        }

                        CheckBox {
                            id: enabledCheck
                            text: meta.label || key
                            checked: catDelegate.catEnabled
                            onToggled: metricsPage.setEnabled(key, checked)
                            Layout.fillWidth: true
                        }

                        ComboBox {
                            id: visibilityCombo
                            model: [i18n("All"), i18n("Popup"), i18n("Compact")]
                            currentIndex: {
                                var v = metricsPage.visibilityFor(catDelegate.key);
                                if (v === "widget") return 1;
                                if (v === "compact") return 2;
                                return 0;
                            }
                            onActivated: {
                                var vals = ["both", "widget", "compact"];
                                metricsPage.setVisibility(catDelegate.key, vals[index]);
                            }
                            implicitWidth: Kirigami.Units.gridUnit * 8
                            ToolTip.text: i18n("All=widget+compact, Popup=full view only, Compact=panel only")
                            ToolTip.visible: hovered
                            ToolTip.delay: Kirigami.Units.toolTipDelay
                        }

                        Item { Layout.fillWidth: true }

                        Button {
                            icon.name: "arrow-up"
                            flat: true
                            enabled: index > 0
                            implicitWidth: Kirigami.Units.gridUnit * 2
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
                            implicitWidth: Kirigami.Units.gridUnit * 2
                            implicitHeight: Kirigami.Units.gridUnit * 2
                            onClicked: metricsPage.moveMetric(index, index + 1)
                            ToolTip.text: i18n("Move down")
                            ToolTip.visible: hovered
                            ToolTip.delay: Kirigami.Units.toolTipDelay
                        }
                    }

                    // ── Sub-metric toggles ─────────────────────────────────
                    // Only shown for categories that have sub-metrics defined

                    Loader {
                        active: catDelegate.hasSubs && catDelegate.catEnabled
                        visible: active
                        Layout.fillWidth: true
                        Layout.leftMargin: Kirigami.Units.gridUnit * 2 + Kirigami.Units.smallSpacing
                        Layout.topMargin: Kirigami.Units.smallSpacing
                        Layout.bottomMargin: Kirigami.Units.smallSpacing

                        sourceComponent: ColumnLayout {
                            spacing: Kirigami.Units.smallSpacing

                            // Label field
                            RowLayout {
                                visible: catDelegate.key === "cpu" || catDelegate.key === "ram" ||
                                         catDelegate.key === "net" || catDelegate.key === "disk"
                                spacing: Kirigami.Units.smallSpacing
                                Label { text: i18n("Label:"); opacity: 0.8 }
                                TextField {
                                    implicitWidth: Kirigami.Units.gridUnit * 12
                                    text: {
                                        switch (catDelegate.key) {
                                            case "cpu":  return cfg_cpuLabel;
                                            case "ram":  return cfg_ramLabel;
                                            case "net":  return cfg_netLabel;
                                            case "disk": return cfg_diskLabel;
                                        }
                                        return "";
                                    }
                                    placeholderText: catDelegate.meta.label
                                    onTextEdited: {
                                        var v = text.trim() || catDelegate.meta.label;
                                        switch (catDelegate.key) {
                                            case "cpu":  cfg_cpuLabel  = v; break;
                                            case "ram":  cfg_ramLabel  = v; break;
                                            case "net":  cfg_netLabel  = v; break;
                                            case "disk": cfg_diskLabel = v; break;
                                        }
                                    }
                                }
                            }

                            // Sub-metric checkboxes (hidden for GPU — handled per-device below)
                            Flow {
                                visible: catDelegate.key !== "gpu"
                                spacing: Kirigami.Units.largeSpacing
                                Layout.fillWidth: true

                                Repeater {
                                    model: catDelegate.meta.subs

                                    delegate: CheckBox {
                                        required property var modelData
                                        text: modelData.label
                                        checked: catDelegate.activeSubs.indexOf(modelData.key) >= 0
                                        enabled: {
                                            // DDR5 temp: grey out when sensor not detected
                                            // (can still uncheck, but not check)
                                            if (catDelegate.key === "ram" && modelData.key === "temp"
                                                && !Plasmoid.configuration._ramTempDetected)
                                                return checked;
                                            return !(checked && catDelegate.activeSubs.length <= 1);
                                        }
                                        onToggled: {
                                            metricsPage.toggleSubMetric(catDelegate.key, modelData.key, checked);
                                            // Manually touching Percentage/Used releases the
                                            // popup-only "show both" override so the button
                                            // can be used again.
                                            if (catDelegate.key === "ram"
                                                && (modelData.key === "percentage" || modelData.key === "used"))
                                                cfg_ramWidgetShowBoth = false;
                                        }
                                    }
                                }
                            }

                            // RAM: popup-only override to show both Percentage and Used/Total
                            // in the widget window without changing which one is checked here
                            // (that choice still governs the compact panel on its own).
                            Button {
                                visible: catDelegate.key === "ram"
                                text: i18n("Show both % and Used in popup")
                                checkable: true
                                checked: cfg_ramWidgetShowBoth
                                // Greyed out only when both are already individually
                                // selected — togglable if just % , just Used/Total, or neither.
                                enabled: !(catDelegate.activeSubs.indexOf("percentage") >= 0
                                    && catDelegate.activeSubs.indexOf("used") >= 0)
                                onToggled: cfg_ramWidgetShowBoth = checked
                            }

                            // DDR5 temperature hint — only relevant once the user has
                            // enabled the sub-metric and the sensor genuinely isn't there;
                            // it used to show whenever the checkbox was checked, which was
                            // confusing on hardware where the sensor IS detected and working.
                            Label {
                                visible: catDelegate.key === "ram" && catDelegate.activeSubs.indexOf("temp") >= 0
                                    && !Plasmoid.configuration._ramTempDetected
                                text: i18n("DDR5 only: not detected or exposed on this hardware, no data will be shown")
                                opacity: 0.6
                                font.italic: true
                                wrapMode: Text.WordWrap
                                Layout.maximumWidth: Kirigami.Units.gridUnit * 24
                            }

                            // ── Category-specific inline settings ──────────

                            // Network: interface selector
                            RowLayout {
                                visible: catDelegate.key === "net"
                                spacing: Kirigami.Units.smallSpacing
                                Label { text: i18n("Interface:"); opacity: 0.8 }
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
                                CheckBox {
                                    text: i18n("Show IP")
                                    checked: cfg_showNetworkIp
                                    onToggled: cfg_showNetworkIp = checked
                                    visible: catDelegate.activeSubs.indexOf("ip") >= 0
                                }
                            }

                            // GPU: per-device selection
                            ColumnLayout {
                                visible: catDelegate.key === "gpu"
                                spacing: Kirigami.Units.smallSpacing
                                Layout.fillWidth: true

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
                                        opacity: 0.7; font.italic: true
                                    }
                                }

                                Label {
                                    visible: metricsPage.discoveredGpus.length > 1
                                    text: i18n("Tip: on hybrid-GPU laptops, uncheck the discrete GPU to let it suspend and save power.")
                                    opacity: 0.7; font.italic: true
                                    wrapMode: Text.WordWrap
                                    Layout.maximumWidth: Kirigami.Units.gridUnit * 24
                                }

                                Repeater {
                                    id: gpuSelectorRepeater
                                    model: metricsPage.discoveredGpus

                                    delegate: ColumnLayout {
                                        id: gpuDelegate
                                        required property var modelData
                                        spacing: Kirigami.Units.smallSpacing
                                        Layout.fillWidth: true
                                        Layout.leftMargin: Kirigami.Units.smallSpacing

                                        property bool _gpuEnabled: {
                                            if (!cfg_gpuSelection || cfg_gpuSelection === "") return true;
                                            if (cfg_gpuSelection === "none") return false;
                                            return cfg_gpuSelection.split(",").indexOf(modelData.id) >= 0;
                                        }

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

                                        ColumnLayout {
                                            enabled: gpuDelegate._gpuEnabled
                                            opacity: gpuDelegate._gpuEnabled ? 1.0 : 0.4
                                            spacing: Kirigami.Units.smallSpacing
                                            Layout.leftMargin: Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing

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
                                            Flow {
                                                spacing: Kirigami.Units.largeSpacing
                                                Layout.fillWidth: true
                                                Layout.topMargin: Kirigami.Units.smallSpacing
                                                Repeater {
                                                    model: [
                                                        {key: "usage", label: i18n("Usage")},
                                                        {key: "vram",  label: i18n("VRAM")},
                                                        {key: "temp",  label: i18n("Temperature")}
                                                    ]
                                                    delegate: CheckBox {
                                                        required property var modelData
                                                        text: modelData.label
                                                        checked: {
                                                            var mm = metricsPage.parseGpuMetrics(cfg_gpuMetrics);
                                                            var mList = mm[gpuDelegate.modelData.id] || ["usage", "vram", "temp"];
                                                            return mList.indexOf(modelData.key) >= 0;
                                                        }
                                                        onToggled: metricsPage.saveGpuMetric(gpuDelegate.modelData.id, modelData.key, checked)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Battery: device selector
                            RowLayout {
                                visible: catDelegate.key === "bat"
                                spacing: Kirigami.Units.smallSpacing
                                Label { text: i18n("Device:"); opacity: 0.8 }
                                TextField {
                                    text: cfg_batteryDevice === "auto" ? "" : cfg_batteryDevice
                                    placeholderText: i18n("Leave empty for auto-detect (e.g. BAT0)")
                                    implicitWidth: Kirigami.Units.gridUnit * 14
                                    onTextEdited: {
                                        var v = text.trim();
                                        cfg_batteryDevice = v.length > 0 ? v : "auto";
                                    }
                                }
                            }

                            // Disk: per-device labels
                            ColumnLayout {
                                visible: catDelegate.key === "disk"
                                spacing: Kirigami.Units.smallSpacing
                                Layout.fillWidth: true

                                Repeater {
                                    model: metricsPage.discoveredDisks

                                    delegate: RowLayout {
                                        required property var modelData
                                        visible: metricsPage.discoveredDisks.length > 0
                                        spacing: Kirigami.Units.smallSpacing
                                        Layout.leftMargin: Kirigami.Units.smallSpacing

                                        Label {
                                            text: modelData.name + ":"
                                            opacity: 0.8
                                            Layout.minimumWidth: Kirigami.Units.gridUnit * 3
                                        }
                                        TextField {
                                            implicitWidth: Kirigami.Units.gridUnit * 12
                                            text: metricsPage.parseDiskLabels(cfg_diskLabels)[modelData.id] || ""
                                            placeholderText: modelData.name
                                            onTextEdited: metricsPage.saveDiskLabel(modelData.id, text)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Single-metric label fields (temp, fan, uptime) ─────

                    Loader {
                        active: catDelegate.key === "temp" && catDelegate.catEnabled
                        visible: active
                        Layout.fillWidth: true
                        Layout.leftMargin: Kirigami.Units.gridUnit * 2 + Kirigami.Units.smallSpacing
                        Layout.topMargin: Kirigami.Units.smallSpacing
                        Layout.bottomMargin: Kirigami.Units.smallSpacing

                        sourceComponent: ColumnLayout {
                            spacing: Kirigami.Units.smallSpacing

                            RowLayout {
                                spacing: Kirigami.Units.smallSpacing
                                Label { text: i18n("Label:"); opacity: 0.8 }
                                TextField {
                                    implicitWidth: Kirigami.Units.gridUnit * 12
                                    text: cfg_tempLabel
                                    placeholderText: i18n("System")
                                    onTextEdited: cfg_tempLabel = text.trim() || "System"
                                }
                            }

                            // Fallback hint — shown when runtime detects no chipset sensor
                            Label {
                                visible: Plasmoid.configuration._tempFallbackActive
                                text: i18n("No chipset temp sensor detected, fallback to CPU temp sensor")
                                opacity: 0.6
                                font.italic: true
                                wrapMode: Text.WordWrap
                                Layout.maximumWidth: Kirigami.Units.gridUnit * 28
                            }
                        }
                    }

                    // ── Divider ────────────────────────────────────────────
                    Rectangle {
                        visible: index < metricsPage.currentOrder.length - 1
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
