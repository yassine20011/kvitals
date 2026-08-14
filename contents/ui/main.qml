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
            property alias cpu:     _cpu
            property alias memory:  _memory
            property alias temp:    _temp
            property alias gpu:     _gpu
            property alias battery: _battery
            property alias network: _network
            property alias disk:    _disk
            property alias fans:    _fans
            property alias uptime:  _uptime

            CpuSensors {
                id: _cpu
                updateInterval: metricConfig.updateInterval
            }

            MemorySensors {
                id: _memory
                updateInterval: metricConfig.updateInterval
                memoryFormat: metricConfig.memoryFormat
            }

            TempSensors {
                id: _temp
                updateInterval: metricConfig.updateInterval
                tempUnit: metricConfig.tempUnit
            }

            GpuSensors {
                id: _gpu
                updateInterval: metricConfig.updateInterval
                gpuSubMetrics: metricConfig.gpuSubMetrics
                gpuSelection: metricConfig.gpuSelection
                gpuLabels: metricConfig.gpuLabels
                tempUnit: metricConfig.tempUnit
                memoryFormat: metricConfig.memoryFormat
            }

            BatterySensors {
                id: _battery
                updateInterval: metricConfig.updateInterval
                batteryDevice: metricConfig.batteryDevice || "auto"
            }

            NetworkSensors {
                id: _network
                updateInterval: metricConfig.updateInterval
                networkInterface: metricConfig.networkInterface
                networkUnit: metricConfig.networkUnit
            }

            DiskSensors {
                id: _disk
                updateInterval: metricConfig.updateInterval
                enabled: metricConfig.diskEnabled
                tempUnit: metricConfig.tempUnit
                networkUnit: metricConfig.networkUnit
                diskLabels: metricConfig.diskLabels
            }

            FanSensors {
                id: _fans
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

    // Representations
    compactRepresentation: CompactView {
        metricsModel: ViewHelpers.buildCompactItems(metricStore.metrics, metricConfig.orderedKeys)
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
        metricsModel: ViewHelpers.buildPopupItems(metricStore.metrics, metricConfig.orderedKeys)
        baseTextColor: root.baseTextColor
        labelColor: root.resolvedLabelColor
        iconColor: root.resolvedIconColor
        fontBold: root.fontBold
        chartHistory: metricStore.chartHistory
        chartVersion: metricStore.chartVersion
        pinned: root.pinned
        onTogglePinned: root.pinned = !root.pinned
    }

    toolTipMainText: "KVitals"
}
