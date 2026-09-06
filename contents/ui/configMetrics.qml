import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasmoid
import org.kde.ksysguard.sensors as Sensors
import "./models"
import "./models/MetricDefinitions.js" as MetricDefinitions

KCM.SimpleKCM {
    id: metricsPage

    // ── cfg_ bindings ──────────────────────────────────────────────────────

    property string cfg_pinnedMetrics: ""
    property string cfg_cpuLabel: "CPU"
    property string cfg_ramLabel: "RAM"
    property string cfg_swapLabel: "SWAP"
    property string cfg_tempLabel: "System"
    property string cfg_gpuSelection: ""
    property string cfg_gpuLabels: ""
    property string cfg_netLabel: "NET"
    property string cfg_networkInterface: "auto"
    property bool cfg_showNetworkIp: false
    property string cfg_diskLabel: "DSK"
    property string cfg_diskLabels: ""
    property string cfg_fanLabel: "FAN"
    property string cfg_fanLabels: ""
    property int cfg_fanMaxRpm: 2000
    property string cfg_metricOrder: "cpu,ram,swap,temp,gpu,bat,net,disk,fan,uptime"
    property string cfg_batteryDevice: "auto"
    property string cfg_batLabel: "BAT"

    // ── Icon bindings ──────────────────────────────────────────────────────

    property string cfg_cpuIcon:     "cpu-symbolic"
    property string cfg_ramIcon:     "memory-symbolic"
    property string cfg_swapIcon:    "memory-symbolic"
    property string cfg_tempIcon:    "temperature-symbolic"
    property string cfg_gpuIcon:     "gpu-symbolic"
    property string cfg_batteryIcon: "battery-symbolic"
    property string cfg_powerIcon:   "voltage-symbolic"
    property string cfg_networkIcon: "network-symbolic"
    property string cfg_diskIcon:    "storage-symbolic"
    property string cfg_fanIcon:     "fan-symbolic"
    property string cfg_uptimeIcon:  "system-symbolic"

    // Metric configuration adapter targeting KCM properties
    MetricConfig {
        id: metricConfig
        target: metricsPage
        propertyPrefix: "cfg_"
    }

    // Hardware discovery
    HardwareDiscovery {
        id: discovery
    }

    // Direct O(1) hardware discovery bindings
    readonly property var discoveredGpus: discovery.discoveredGpus
    readonly property var discoveredDisks: discovery.discoveredDisks
    readonly property var discoveredFans: discovery.discoveredFans
    readonly property var ifaceList: discovery.discoveredNetworkIfaces
    readonly property var batteryList: {
        var list = ["auto"].concat(discovery.discoveredBatteries || []);
        if (cfg_batteryDevice && list.indexOf(cfg_batteryDevice) === -1) {
            list.push(cfg_batteryDevice);
        }
        return list;
    }

    // Fan max-RPM check
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

    // UI
    ColumnLayout {
        spacing: 0
        Layout.fillWidth: true

        // ── Processor (CPU) ────────────────────────────────────────────────
        Kirigami.FormLayout {
            id: cpuForm
            Layout.fillWidth: true
            twinFormLayouts: [cpuForm, memForm, tempForm, gpuForm, batForm, netForm, diskForm, fanForm]

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: i18n("Processor (CPU)")
            }

            TextField {
                Kirigami.FormData.label: i18n("Display label:")
                text: cfg_cpuLabel
                placeholderText: "CPU"
                implicitWidth: Kirigami.Units.gridUnit * 14
                onTextEdited: cfg_cpuLabel = text.trim() || "CPU"
            }
        }

        // ── Memory (RAM & Swap) ────────────────────────────────────────────
        Kirigami.FormLayout {
            id: memForm
            Layout.fillWidth: true
            twinFormLayouts: [cpuForm, memForm, tempForm, gpuForm, batForm, netForm, diskForm, fanForm]

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: i18n("Memory (RAM & Swap)")
            }

            TextField {
                Kirigami.FormData.label: i18n("RAM label:")
                text: cfg_ramLabel
                placeholderText: "RAM"
                implicitWidth: Kirigami.Units.gridUnit * 14
                onTextEdited: cfg_ramLabel = text.trim() || "RAM"
            }

            TextField {
                Kirigami.FormData.label: i18n("Swap label:")
                text: cfg_swapLabel
                placeholderText: "SWAP"
                implicitWidth: Kirigami.Units.gridUnit * 14
                onTextEdited: cfg_swapLabel = text.trim() || "SWAP"
            }
        }

        // ── Temperature ────────────────────────────────────────────────────
        Kirigami.FormLayout {
            id: tempForm
            Layout.fillWidth: true
            twinFormLayouts: [cpuForm, memForm, tempForm, gpuForm, batForm, netForm, diskForm, fanForm]

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: i18n("Temperature")
            }

            TextField {
                Kirigami.FormData.label: i18n("System temp label:")
                text: cfg_tempLabel
                placeholderText: "System"
                implicitWidth: Kirigami.Units.gridUnit * 14
                onTextEdited: cfg_tempLabel = text.trim() || "System"
            }
        }

        // ── Graphics (GPU) ─────────────────────────────────────────────────
        Kirigami.FormLayout {
            id: gpuForm
            Layout.fillWidth: true
            twinFormLayouts: [cpuForm, memForm, tempForm, gpuForm, batForm, netForm, diskForm, fanForm]

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: i18n("Graphics (GPU)")
            }

            Label {
                visible: metricsPage.discoveredGpus.length === 0
                text: i18n("No GPU detected")
                opacity: 0.7
                font.italic: true
            }

            Repeater {
                id: gpuSelectorRepeater
                model: metricsPage.discoveredGpus

                delegate: RowLayout {
                    id: gpuDelegate
                    required property var modelData
                    Kirigami.FormData.label: gpuDelegate.modelData.name + " (" + gpuDelegate.modelData.id + "):"
                    spacing: Kirigami.Units.smallSpacing

                    property bool _gpuEnabled: metricConfig.isGpuSelected(modelData.id)

                    CheckBox {
                        text: i18n("Enabled")
                        checked: gpuDelegate._gpuEnabled
                        onToggled: {
                            var allIds = gpuSelectorRepeater.model.map(function(g){ return g.id; });
                            metricConfig.setGpuSelected(modelData.id, checked, allIds);
                        }
                    }

                    TextField {
                        implicitWidth: Kirigami.Units.gridUnit * 12
                        text: metricConfig.parseGpuLabels()[gpuDelegate.modelData.id] || ""
                        placeholderText: gpuDelegate.modelData.name
                        onTextEdited: metricConfig.saveGpuLabel(gpuDelegate.modelData.id, text)
                    }

                    Kirigami.ContextualHelpButton {
                        visible: metricsPage.discoveredGpus.length > 1
                        toolTipText: i18n("On hybrid-GPU laptops, uncheck the discrete GPU to allow it to power down and save battery.")
                    }
                }
            }
        }

        // ── Battery & Power ────────────────────────────────────────────────
        Kirigami.FormLayout {
            id: batForm
            Layout.fillWidth: true
            twinFormLayouts: [cpuForm, memForm, tempForm, gpuForm, batForm, netForm, diskForm, fanForm]

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: i18n("Battery & Power")
            }

            TextField {
                Kirigami.FormData.label: i18n("Display label:")
                text: cfg_batLabel
                placeholderText: "BAT"
                implicitWidth: Kirigami.Units.gridUnit * 14
                onTextEdited: cfg_batLabel = text.trim() || "BAT"
            }

            RowLayout {
                Kirigami.FormData.label: i18n("Battery device:")
                spacing: Kirigami.Units.smallSpacing

                ComboBox {
                    id: batDeviceCombo
                    model: metricsPage.batteryList
                    currentIndex: {
                        var idx = metricsPage.batteryList.indexOf(cfg_batteryDevice);
                        return idx >= 0 ? idx : 0;
                    }
                    onActivated: cfg_batteryDevice = metricsPage.batteryList[currentIndex]
                    implicitWidth: Kirigami.Units.gridUnit * 14
                }

                Kirigami.ContextualHelpButton {
                    toolTipText: i18n("Select 'auto' for automatic detection, or select a specific battery if multiple are installed.")
                }
            }
        }

        // ── Network ────────────────────────────────────────────────────────
        Kirigami.FormLayout {
            id: netForm
            Layout.fillWidth: true
            twinFormLayouts: [cpuForm, memForm, tempForm, gpuForm, batForm, netForm, diskForm, fanForm]

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: i18n("Network")
            }

            ComboBox {
                id: ifaceCombo
                Kirigami.FormData.label: i18n("Interface:")
                model: metricsPage.ifaceList
                currentIndex: {
                    var idx = metricsPage.ifaceList.indexOf(cfg_networkInterface);
                    return idx >= 0 ? idx : 0;
                }
                onActivated: cfg_networkInterface = metricsPage.ifaceList[currentIndex]
                implicitWidth: Kirigami.Units.gridUnit * 14
            }

            TextField {
                Kirigami.FormData.label: i18n("Display label:")
                text: cfg_netLabel
                placeholderText: "NET"
                implicitWidth: Kirigami.Units.gridUnit * 14
                onTextEdited: cfg_netLabel = text.trim() || "NET"
            }
        }

        // ── Storage (Disks) ────────────────────────────────────────────────
        Kirigami.FormLayout {
            id: diskForm
            Layout.fillWidth: true
            twinFormLayouts: [cpuForm, memForm, tempForm, gpuForm, batForm, netForm, diskForm, fanForm]

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: i18n("Storage (Disks)")
            }

            TextField {
                Kirigami.FormData.label: i18n("Global disk label:")
                text: cfg_diskLabel
                placeholderText: "DSK"
                implicitWidth: Kirigami.Units.gridUnit * 14
                onTextEdited: cfg_diskLabel = text.trim() || "DSK"
            }

            Repeater {
                model: metricsPage.discoveredDisks

                delegate: TextField {
                    required property var modelData
                    Kirigami.FormData.label: modelData.name + " (" + modelData.id + "):"
                    implicitWidth: Kirigami.Units.gridUnit * 14
                    text: metricConfig.parseDiskLabels()[modelData.id] || ""
                    placeholderText: modelData.name
                    onTextEdited: metricConfig.saveDiskLabel(modelData.id, text)
                }
            }
        }

        // ── Cooling (Fans) ─────────────────────────────────────────────────
        Kirigami.FormLayout {
            id: fanForm
            Layout.fillWidth: true
            twinFormLayouts: [cpuForm, memForm, tempForm, gpuForm, batForm, netForm, diskForm, fanForm]

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: i18n("Cooling (Fans)")
            }

            TextField {
                Kirigami.FormData.label: i18n("Global fan label:")
                text: cfg_fanLabel
                placeholderText: "FAN"
                implicitWidth: Kirigami.Units.gridUnit * 14
                onTextEdited: cfg_fanLabel = text.trim() || "FAN"
            }

            RowLayout {
                visible: metricsPage.fanMaxFallbackNeeded
                Kirigami.FormData.label: i18n("Max RPM fallback:")
                spacing: Kirigami.Units.smallSpacing

                SpinBox {
                    from: 500
                    to: 9999
                    stepSize: 100
                    value: cfg_fanMaxRpm
                    onValueChanged: cfg_fanMaxRpm = value
                }

                Kirigami.ContextualHelpButton {
                    toolTipText: i18n("Used as the maximum baseline RPM to calculate fan speed percentage when the hardware driver does not report a maximum RPM.")
                }
            }

            Repeater {
                model: metricsPage.discoveredFans

                delegate: TextField {
                    required property var modelData
                    Kirigami.FormData.label: modelData.name + ":"
                    implicitWidth: Kirigami.Units.gridUnit * 14
                    text: metricConfig.parseFanLabels()[modelData.id] || ""
                    placeholderText: modelData.name
                    onTextEdited: metricConfig.saveFanLabel(modelData.id, text)
                }
            }
        }
    }
}
