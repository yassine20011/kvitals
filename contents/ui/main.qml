import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "./sensors"
import "./models"
import "./models/ViewHelpers.js" as ViewHelpers

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation

    property bool pinned: false
    hideOnWindowDeactivate: !pinned

    function isValidColor(s) {
        return typeof s === "string" && /^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(s);
    }

    // Display and appearance properties
    property string displayMode: Plasmoid.configuration.displayMode
    property string layoutType:  Plasmoid.configuration.layoutType
    property int iconSize:       Plasmoid.configuration.iconSize
    property string fontFamily:  Plasmoid.configuration.fontFamily
    property int fontSize:       Plasmoid.configuration.fontSize
    property bool fontBold:      Plasmoid.configuration.fontBold
    property real labelOpacity:  Plasmoid.configuration.labelOpacity
    property real separatorOpacity: Plasmoid.configuration.separatorOpacity
    property int effectiveFontSize: fontSize > 0 ? fontSize : -1
    property bool mergeFamilyMetrics: Plasmoid.configuration.mergeFamilyMetrics !== undefined ? Plasmoid.configuration.mergeFamilyMetrics : true

    property bool useIcons: displayMode === "icons" || displayMode === "icons+text"
    property bool useText:  displayMode === "text"  || displayMode === "icons+text"

    // Colors
    property bool useCustomColors: Plasmoid.configuration.useCustomColors
    property string fontColor:     Plasmoid.configuration.fontColor
    property string labelColor:    Plasmoid.configuration.labelColor || ""
    property string iconColor:     Plasmoid.configuration.iconColor || ""
    property color baseTextColor:  (useCustomColors && isValidColor(fontColor)) ? fontColor : Kirigami.Theme.textColor
    property color resolvedLabelColor: (useCustomColors && isValidColor(labelColor)) ? labelColor : baseTextColor
    property color resolvedIconColor:  (useCustomColors && isValidColor(iconColor)) ? iconColor : resolvedLabelColor

    // Metric configuration adapter
    MetricConfig {
        id: metricConfig
    }

    // Runtime metric store
    MetricStore {
        id: metricStore
        config: metricConfig
        sensors: sensorLoader.item
        sensorsReady: sensorLoader.status === Loader.Ready
        baseTextColor: root.baseTextColor
    }

    // Deferred sensor loader
    Loader {
        id: sensorLoader
        active: false
        sourceComponent: Item {
            property alias discovery: _discovery
            property alias cpu:       _cpu
            property alias memory:    _memory
            property alias swap:      _swap
            property alias temp:      _temp
            property alias gpu:       _gpu
            property alias battery:   _battery
            property alias network:   _network
            property alias disk:      _disk
            property alias fans:      _fans
            property alias uptime:    _uptime

            HardwareDiscovery {
                id: _discovery
            }

            CpuSensors {
                id: _cpu
                updateInterval: metricConfig.updateInterval
            }

            MemorySensors {
                id: _memory
                updateInterval: metricConfig.updateInterval
            }

            SwapSensors {
                id: _swap
                updateInterval: metricConfig.updateInterval
            }

            TempSensors {
                id: _temp
                discovery: _discovery
                updateInterval: metricConfig.updateInterval
                tempUnit: metricConfig.tempUnit
            }

            GpuSensors {
                id: _gpu
                discovery: _discovery
                updateInterval: metricConfig.updateInterval
                gpuSubMetrics: metricConfig.gpuSubMetrics
                gpuSelection: metricConfig.gpuSelection
                gpuLabels: metricConfig.gpuLabels
                tempUnit: metricConfig.tempUnit
            }

            BatterySensors {
                id: _battery
                discovery: _discovery
                updateInterval: metricConfig.updateInterval
                batteryDevice: metricConfig.batteryDevice || "auto"
            }

            NetworkSensors {
                id: _network
                discovery: _discovery
                updateInterval: metricConfig.updateInterval
                networkInterface: metricConfig.networkInterface
                networkUnit: metricConfig.networkUnit
            }

            DiskSensors {
                id: _disk
                discovery: _discovery
                updateInterval: metricConfig.updateInterval
                enabled: true
                tempUnit: metricConfig.tempUnit
                networkUnit: metricConfig.networkUnit
                diskLabels: metricConfig.diskLabels
            }

            FanSensors {
                id: _fans
                discovery: _discovery
                updateInterval: metricConfig.updateInterval
                fanUnit: metricConfig.fanUnit
                fanLabels: metricConfig.fanLabels
                fanMaxRpm: metricConfig.fanMaxRpm
            }

            UptimeSensors {
                id: _uptime
                updateInterval: metricConfig.updateInterval
            }
        }
    }

    Timer {
        id: sensorActivationTimer
        interval: 0
        repeat: false
        onTriggered: sensorLoader.active = true
    }

    Connections {
        target: sensorLoader
        function onStatusChanged() {
            if (sensorLoader.status === Loader.Ready && !Plasmoid.configuration.configMigrated) {
                var hw = {
                    gpus: sensorLoader.item ? sensorLoader.item.gpu.discoveredGpus : [],
                    disks: sensorLoader.item ? sensorLoader.item.disk.discoveredDisks : [],
                    fans: sensorLoader.item ? sensorLoader.item.fans.discoveredFans : []
                };
                metricConfig.migrateLegacyConfig(hw);
            }
        }
    }

    Binding {
        target: Plasmoid.configuration
        property: "_tempFallbackActive"
        value: sensorLoader.item ? sensorLoader.item.temp.sysIsFallback : false
        when: sensorLoader.status === Loader.Ready
    }

    Binding {
        target: Plasmoid.configuration
        property: "_ramTempDetected"
        value: sensorLoader.item ? sensorLoader.item.temp.ramTempExists : false
        when: sensorLoader.status === Loader.Ready
    }

    Component.onCompleted: {
        sensorActivationTimer.start();
    }

    // Pre-computed model caches — rebuilt once per MetricStore tick, not per binding consumer.
    property var _compactItems: []
    property var _popupGroups: []

    onMergeFamilyMetricsChanged: {
        root._compactItems = ViewHelpers.buildCompactItems(metricStore.metrics, metricConfig.pinnedList, root.mergeFamilyMetrics);
    }

    Connections {
        target: metricStore
        function onMetricsChanged() {
            root._compactItems = ViewHelpers.buildCompactItems(metricStore.metrics, metricConfig.pinnedList, root.mergeFamilyMetrics);
            root._popupGroups  = ViewHelpers.buildPopupGroups(metricStore.metrics, metricConfig.orderedKeys);
        }
    }

    Connections {
        target: metricConfig
        function onPinnedListChanged() {
            root._compactItems = ViewHelpers.buildCompactItems(metricStore.metrics, metricConfig.pinnedList, root.mergeFamilyMetrics);
            root._popupGroups  = ViewHelpers.buildPopupGroups(metricStore.metrics, metricConfig.orderedKeys);
        }
        function onOrderedKeysChanged() {
            root._popupGroups = ViewHelpers.buildPopupGroups(metricStore.metrics, metricConfig.orderedKeys);
        }
    }

    // Representations
    compactRepresentation: CompactView {
        metricsModel: root._compactItems
        layoutType: root.layoutType
        useIcons: root.useIcons
        useText: root.useText
        effectiveFontSize: root.effectiveFontSize
        fontFamily: root.fontFamily
        fontBold: root.fontBold
        iconSize: root.iconSize
        baseTextColor: root.baseTextColor
        labelColor: root.resolvedLabelColor
        iconColor: root.resolvedIconColor
        labelOpacity: root.labelOpacity
        separatorOpacity: root.separatorOpacity
        onToggleExpanded: root.expanded = !root.expanded
    }

    fullRepresentation: FullView {
        groupsModel: root._popupGroups
        baseTextColor: root.baseTextColor
        labelColor: root.resolvedLabelColor
        iconColor: root.resolvedIconColor
        fontBold: root.fontBold
        pinned: root.pinned
        onTogglePinned: root.pinned = !root.pinned
        onToggleMetricPin: function(metricId) {
            metricConfig.togglePin(metricId);
        }
        onRefreshRequested: {
            if (sensorLoader.item && sensorLoader.item.discovery) {
                sensorLoader.item.discovery.rescan();
            }
        }
    }

    toolTipMainText: "KVitals"
}
