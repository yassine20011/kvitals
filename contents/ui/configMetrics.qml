import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.ksysguard.sensors as Sensors
import "./models"
import "./models/MetricDefinitions.js" as MetricDefinitions

KCM.SimpleKCM {
    id: metricsPage

    // ── cfg_ bindings ──────────────────────────────────────────────────────

    property bool cfg_cpuEnabled
    property string cfg_cpuSubMetrics: MetricDefinitions.GROUPS.cpu.defaultSubMetrics
    property string cfg_cpuLabel: "CPU"
    property string cfg_cpuVisibility: "both"

    property bool cfg_ramEnabled
    property string cfg_ramSubMetrics: MetricDefinitions.GROUPS.ram.defaultSubMetrics
    property string cfg_ramLabel: "RAM"
    property bool cfg_ramWidgetShowBoth: false
    property string cfg_ramVisibility: "both"

    property bool cfg_swapEnabled
    property string cfg_swapSubMetrics: MetricDefinitions.GROUPS.swap.defaultSubMetrics
    property string cfg_swapLabel: "SWAP"
    property string cfg_swapVisibility: "both"

    property bool cfg_tempEnabled
    property string cfg_tempLabel: "System"
    property string cfg_tempVisibility: "both"

    property bool cfg_gpuEnabled
    property string cfg_gpuSubMetrics: MetricDefinitions.GROUPS.gpu.defaultSubMetrics
    property string cfg_gpuSelection: ""
    property string cfg_gpuLabels: ""
    property string cfg_gpuVisibility: "both"

    property bool cfg_batEnabled
    property string cfg_batSubMetrics: MetricDefinitions.GROUPS.bat.defaultSubMetrics
    property string cfg_batVisibility: "both"

    property bool cfg_netEnabled
    property string cfg_netSubMetrics: MetricDefinitions.GROUPS.net.defaultSubMetrics
    property string cfg_netLabel: "NET"
    property string cfg_networkInterface: "auto"
    property bool cfg_showNetworkIp: false
    property string cfg_netVisibility: "both"

    property bool cfg_diskEnabled
    property string cfg_diskSubMetrics: MetricDefinitions.GROUPS.disk.defaultSubMetrics
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

    property string cfg_metricOrder: "cpu,ram,swap,temp,gpu,bat,net,disk,fan,uptime"
    property string cfg_batteryDevice

    // ── Icon bindings (from configIcons.qml, shared across config pages) ───

    property string cfg_cpuIcon:     "am-cpu-symbolic"
    property string cfg_ramIcon:     "nvidia-ram-symbolic"
    property string cfg_swapIcon:    "nvidia-ram-symbolic"
    property string cfg_tempIcon:    "temperature-normal"
    property string cfg_gpuIcon:     "gpu-symbolic"
    property string cfg_batteryIcon: "battery-good"
    property string cfg_powerIcon:   "battery-charging-60"
    property string cfg_networkIcon: "network-wireless"
    property string cfg_diskIcon:    "am-disk-utility-symbolic"
    property string cfg_fanIcon:     "am-fan-symbolic"
    property string cfg_uptimeIcon:  "clock"

    // Metric configuration adapter targeting KCM properties
    MetricConfig {
        id: metricConfig
        target: metricsPage
        propertyPrefix: "cfg_"
    }

    readonly property var currentOrder: metricConfig.orderedKeys

    // Sensor discovery (GPU, Disk, Fan) via HardwareDiscovery
    HardwareDiscovery {
        id: discovery
    }

    // GPU discovery
    readonly property var discoveredGpus: {
        var pattern = MetricDefinitions.PATTERNS ? MetricDefinitions.PATTERNS.GPU : /^gpu\/(gpu\d+)\/usage$/;
        var ids = discovery.revision >= 0 ? discovery.queryIds(pattern) : [];
        var found = [];
        for (var i = 0; i < ids.length; i++) {
            var match = ids[i].match(pattern);
            if (match) {
                found.push({ id: match[1], name: "GPU " + (found.length + 1) });
            }
        }
        return found;
    }

    // Disk discovery
    readonly property var discoveredDisks: {
        var pattern = MetricDefinitions.PATTERNS ? MetricDefinitions.PATTERNS.DISK_READ : /^disk\/(nvme\d+n\d+|sd[a-z]+)\/read$/;
        var ids = discovery.revision >= 0 ? discovery.queryIds(pattern) : [];
        var found = [];
        for (var i = 0; i < ids.length; i++) {
            var match = ids[i].match(pattern);
            if (match && !found.some(function(d){ return d.id === match[1]; })) {
                found.push({ id: match[1], name: "DSK " + (found.length + 1) });
            }
        }
        return found;
    }

    // Fan discovery
    readonly property var discoveredFans: {
        var pattern = MetricDefinitions.PATTERNS ? MetricDefinitions.PATTERNS.FAN : /^(lmsensors|cpu|gpu)\/.*\/fan\d+$/i;
        var ids = discovery.revision >= 0 ? discovery.queryIds(pattern) : [];
        ids.sort();
        return ids.map(function(id, i) { return { id: id, name: "Fan " + (i + 1) }; });
    }

    // Fan max-RPM capability check
    property bool fanMaxFallbackNeeded: true

    Sensors.SensorDataModel {
        id: fanMaxCheck
        sensors: metricsPage.discoveredFans.map(function(f){ return f.id; })
        updateRateLimit: 2000
        enabled: metricsPage.discoveredFans.length > 0

        onDataChanged: metricsPage._recomputeFanMaxFallback()
        onReadyChanged: { if (ready) metricsPage._recomputeFanMaxFallback(); }
    }

    function _recomputeFanMaxFallback() {
        for (var i = 0; i < discoveredFans.length; i++) {
            var col = fanMaxCheck.column(discoveredFans[i].id);
            var idx = col >= 0 ? fanMaxCheck.index(0, col) : null;
            var val = idx && idx.valid ? fanMaxCheck.data(idx, Sensors.SensorDataModel.Maximum) : undefined;
            if (val === undefined || val === null || val <= 0) {
                fanMaxFallbackNeeded = true;
                return;
            }
        }
        fanMaxFallbackNeeded = false;
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

    // UI

    Kirigami.FormLayout {

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Metrics Configuration")
        }

        Label {
            text: i18n("Upgrading from an older version may reset your visibility and sub-metric choices below to defaults.")
            opacity: 0.6
            font.italic: true
            wrapMode: Text.WordWrap
            Layout.maximumWidth: Kirigami.Units.gridUnit * 28
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
                    readonly property var meta: MetricDefinitions.GROUPS[key] || {}
                    readonly property bool catEnabled: metricConfig.isGroupEnabled(key)
                    readonly property var activeSubs: metricConfig.getSubMetrics(key)
                    readonly property bool hasSubs: meta.subs && meta.subs.length > 0

                    // ── Category row ────────────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Icon {
                            source: metricConfig.getGroupIcon(catDelegate.key)
                            isMask: true
                            implicitWidth: Kirigami.Units.iconSizes.smallMedium
                            implicitHeight: Kirigami.Units.iconSizes.smallMedium
                            opacity: catDelegate.catEnabled ? 1 : 0.4
                        }

                        CheckBox {
                            id: enabledCheck
                            text: i18n(meta.name || meta.defaultLabel || key)
                            checked: catDelegate.catEnabled
                            onToggled: metricConfig.setGroupEnabled(key, checked)
                            Layout.fillWidth: true
                        }

                        ComboBox {
                            id: visibilityCombo
                            model: [i18n("All"), i18n("Popup"), i18n("Compact")]
                            currentIndex: {
                                var v = metricConfig.getVisibility(catDelegate.key);
                                if (v === "widget") return 1;
                                if (v === "compact") return 2;
                                return 0;
                            }
                            onActivated: {
                                var vals = ["both", "widget", "compact"];
                                metricConfig.setVisibility(catDelegate.key, vals[index]);
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
                            onClicked: metricConfig.moveMetric(index, index - 1)
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
                            onClicked: metricConfig.moveMetric(index, index + 1)
                            ToolTip.text: i18n("Move down")
                            ToolTip.visible: hovered
                            ToolTip.delay: Kirigami.Units.toolTipDelay
                        }
                    }

                    // ── Sub-metric toggles ─────────────────────────────────
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
                                         catDelegate.key === "swap" ||
                                         catDelegate.key === "net" || catDelegate.key === "disk"
                                spacing: Kirigami.Units.smallSpacing
                                Label { text: i18n("Label:"); opacity: 0.8 }
                                TextField {
                                    implicitWidth: Kirigami.Units.gridUnit * 12
                                    text: metricConfig.getGroupLabel(catDelegate.key)
                                    placeholderText: catDelegate.meta.defaultLabel || ""
                                    onTextEdited: metricConfig.setGroupLabel(catDelegate.key, text.trim() || (catDelegate.meta.defaultLabel || ""))
                                }
                            }

                            // Sub-metric checkboxes
                            Flow {
                                visible: catDelegate.key !== "gpu"
                                spacing: Kirigami.Units.largeSpacing
                                Layout.fillWidth: true

                                Repeater {
                                    model: catDelegate.meta.subs

                                    delegate: CheckBox {
                                        required property var modelData
                                        text: i18n(modelData.label)
                                        checked: catDelegate.activeSubs.indexOf(modelData.key) >= 0
                                        enabled: {
                                            if (catDelegate.key === "ram" && modelData.key === "temp"
                                                && !Plasmoid.configuration._ramTempDetected)
                                                return checked;
                                            return !(checked && catDelegate.activeSubs.length <= 1);
                                        }
                                        onToggled: {
                                            metricConfig.toggleSubMetric(catDelegate.key, modelData.key, checked);
                                            if (catDelegate.key === "ram"
                                                && (modelData.key === "percentage" || modelData.key === "used"))
                                                cfg_ramWidgetShowBoth = false;
                                        }
                                    }
                                }
                            }

                            // RAM popup override button
                            Button {
                                visible: catDelegate.key === "ram"
                                text: i18n("Show both in popup window")
                                checkable: true
                                checked: cfg_ramWidgetShowBoth
                                enabled: !(catDelegate.activeSubs.indexOf("percentage") >= 0
                                    && catDelegate.activeSubs.indexOf("used") >= 0)
                                onToggled: cfg_ramWidgetShowBoth = checked
                            }

                            // DDR5 temperature hint
                            Label {
                                visible: catDelegate.key === "ram" && catDelegate.activeSubs.indexOf("temp") >= 0
                                    && !Plasmoid.configuration._ramTempDetected
                                text: i18n("DDR5 only: not detected or exposed on this hardware, no data will be shown")
                                opacity: 0.6
                                font.italic: true
                                wrapMode: Text.WordWrap
                                Layout.maximumWidth: Kirigami.Units.gridUnit * 24
                            }

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

                            // GPU: per-device selection and sub-metrics
                            ColumnLayout {
                                visible: catDelegate.key === "gpu"
                                spacing: Kirigami.Units.smallSpacing
                                Layout.fillWidth: true

                                Label {
                                    visible: metricsPage.discoveredGpus.length === 0
                                    text: i18n("No GPU detected")
                                    opacity: 0.7
                                    font.italic: true
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

                                        property bool _gpuEnabled: metricConfig.isGpuSelected(modelData.id)

                                        CheckBox {
                                            text: gpuDelegate.modelData.name
                                            checked: gpuDelegate._gpuEnabled
                                            onToggled: {
                                                var allIds = gpuSelectorRepeater.model.map(function(g){ return g.id; });
                                                metricConfig.setGpuSelected(modelData.id, checked, allIds);
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
                                                    text: metricConfig.parseGpuLabels()[gpuDelegate.modelData.id] || ""
                                                    placeholderText: gpuDelegate.modelData.name
                                                    onTextEdited: metricConfig.saveGpuLabel(gpuDelegate.modelData.id, text)
                                                }
                                            }

                                            // Per-GPU sub-metric checkboxes
                                            Flow {
                                                spacing: Kirigami.Units.largeSpacing
                                                Layout.fillWidth: true

                                                property var activeGpuSubs: metricConfig.getGpuSubMetrics(gpuDelegate.modelData.id)

                                                Repeater {
                                                    model: catDelegate.meta.subs

                                                    delegate: CheckBox {
                                                        required property var modelData
                                                        text: i18n(modelData.label)
                                                        checked: parent.activeGpuSubs.indexOf(modelData.key) >= 0
                                                        enabled: !(checked && parent.activeGpuSubs.length <= 1)
                                                        onToggled: {
                                                            var allIds = metricsPage.discoveredGpus.map(function(g){ return g.id; });
                                                            metricConfig.toggleGpuSubMetric(gpuDelegate.modelData.id, modelData.key, checked, allIds);
                                                        }
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
                                            text: metricConfig.parseDiskLabels()[modelData.id] || ""
                                            placeholderText: modelData.name
                                            onTextEdited: metricConfig.saveDiskLabel(modelData.id, text)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Single-metric label fields (temp, fan, uptime)
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
                                    text: metricConfig.getGroupLabel("temp")
                                    placeholderText: i18n("System")
                                    onTextEdited: metricConfig.setGroupLabel("temp", text.trim() || "System")
                                }
                            }

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

                    // Fan settings
                    Loader {
                        active: catDelegate.key === "fan" && catDelegate.catEnabled
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
                                    text: metricConfig.getGroupLabel("fan")
                                    placeholderText: i18n("FAN")
                                    onTextEdited: metricConfig.setGroupLabel("fan", text.trim() || "FAN")
                                }
                            }

                            ColumnLayout {
                                spacing: Kirigami.Units.smallSpacing
                                Layout.fillWidth: true

                                Repeater {
                                    model: metricsPage.discoveredFans

                                    delegate: RowLayout {
                                        required property var modelData
                                        visible: metricsPage.discoveredFans.length > 0
                                        spacing: Kirigami.Units.smallSpacing
                                        Layout.leftMargin: Kirigami.Units.smallSpacing

                                        Label {
                                            text: modelData.name + ":"
                                            opacity: 0.8
                                            Layout.minimumWidth: Kirigami.Units.gridUnit * 3
                                        }
                                        TextField {
                                            implicitWidth: Kirigami.Units.gridUnit * 12
                                            text: metricConfig.parseFanLabels()[modelData.id] || ""
                                            placeholderText: modelData.name
                                            onTextEdited: metricConfig.saveFanLabel(modelData.id, text)
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                visible: metricsPage.fanMaxFallbackNeeded
                                spacing: Kirigami.Units.smallSpacing
                                Label { text: i18n("Max RPM for percentage:"); opacity: 0.8 }
                                SpinBox {
                                    from: 500
                                    to: 9999
                                    stepSize: 100
                                    value: cfg_fanMaxRpm
                                    onValueChanged: cfg_fanMaxRpm = value
                                    implicitWidth: Kirigami.Units.gridUnit * 6
                                }
                            }

                            Label {
                                visible: metricsPage.fanMaxFallbackNeeded
                                text: i18n("Your fans don't report a max RPM: enter one manually (check your fan's specs online). Estimated values show \"~\".")
                                opacity: 0.6
                                font.italic: true
                                wrapMode: Text.WordWrap
                                Layout.maximumWidth: Kirigami.Units.gridUnit * 28
                            }
                        }
                    }

                    // Divider
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
