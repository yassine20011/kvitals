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

    property bool showSeparators: Plasmoid.configuration.showSeparators !== undefined ? Plasmoid.configuration.showSeparators : true

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
                discovery: _discovery
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

    Component.onCompleted: {
        sensorActivationTimer.start();
    }

    // Compact item components
    component CompactSegment: QtObject {
        property string value: ""
        property color color: "transparent"
        property string label: ""
        property string icon: ""
        property string key: ""
    }

    component CompactItem: QtObject {
        property string id: ""
        property var icon: ""
        property string label: ""
        property string value: ""
        property color color: "transparent"
        property string key: ""
        property var segments: null
        property bool hideSeparator: false
        property string _groupBaseLabel: ""
        property string _firstSubLabel: ""
        property string _firstSubIcon: ""
        property string _firstSubKey: ""
    }

    Component { id: compactSegComp; CompactSegment {} }
    Component { id: compactItemComp; CompactItem {} }

    function _createCompactItemObject(raw) {
        var segs = null;
        if (raw.segments && raw.segments.length) {
            segs = [];
            for (var s = 0; s < raw.segments.length; s++) {
                var rawSeg = raw.segments[s];
                var segObj = compactSegComp.createObject(root, {
                    value: rawSeg.value || "",
                    color: rawSeg.color || "transparent",
                    label: rawSeg.label || "",
                    icon: rawSeg.icon || "",
                    key: rawSeg.key || ""
                });
                segs.push(segObj);
            }
        }
        return compactItemComp.createObject(root, {
            id: raw.id || "",
            icon: raw.icon || "",
            label: raw.label || "",
            value: raw.value || "",
            color: raw.color || "transparent",
            key: raw.key || "",
            segments: segs,
            hideSeparator: Boolean(raw.hideSeparator),
            _groupBaseLabel: raw._groupBaseLabel || "",
            _firstSubLabel: raw._firstSubLabel || "",
            _firstSubIcon: raw._firstSubIcon || "",
            _firstSubKey: raw._firstSubKey || ""
        });
    }

    function _updateCompactItems() {
        var rawItems = ViewHelpers.buildCompactItems(metricStore.metrics, metricConfig.pinnedList, root.mergeFamilyMetrics);
        if (ViewHelpers.syncCompactValues(root._compactItems, rawItems)) {
            return;
        }
        var old = root._compactItems;
        var newList = [];
        for (var i = 0; i < rawItems.length; i++) {
            newList.push(_createCompactItemObject(rawItems[i]));
        }
        root._compactItems = newList;
        for (var j = 0; j < old.length; j++) {
            if (old[j] && old[j].segments) {
                for (var s = 0; s < old[j].segments.length; s++) {
                    old[j].segments[s].destroy();
                }
            }
            if (old[j]) old[j].destroy();
        }
    }

    function _updatePopupGroups() {
        if (root.expanded) {
            root._popupGroups = ViewHelpers.buildPopupGroups(metricStore.metrics, metricConfig.orderedKeys);
        }
    }

    property var _compactItems: []
    property var _popupGroups: []

    onExpandedChanged: {
        if (expanded) {
            _updatePopupGroups();
        }
    }

    onMergeFamilyMetricsChanged: {
        root._updateCompactItems();
    }

    Connections {
        target: metricStore
        function onMetricsChanged() {
            root._updateCompactItems();
            if (root.expanded) {
                root._popupGroups = ViewHelpers.buildPopupGroups(metricStore.metrics, metricConfig.orderedKeys);
            }
        }
    }

    Connections {
        target: metricConfig
        function onPinnedListChanged() {
            root._updateCompactItems();
            if (root.expanded) {
                root._popupGroups = ViewHelpers.buildPopupGroups(metricStore.metrics, metricConfig.orderedKeys);
            }
        }
        function onOrderedKeysChanged() {
            if (root.expanded) {
                root._popupGroups = ViewHelpers.buildPopupGroups(metricStore.metrics, metricConfig.orderedKeys);
            }
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
        showSeparators: root.showSeparators
        onToggleExpanded: root.expanded = !root.expanded
    }

    fullRepresentation: Loader {
        id: fullRepLoader
        Layout.preferredWidth: Kirigami.Units.gridUnit * 18
        Layout.preferredHeight: Kirigami.Units.gridUnit * 22
        Layout.minimumWidth: Kirigami.Units.gridUnit * 15
        Layout.maximumWidth: Kirigami.Units.gridUnit * 24
        Layout.minimumHeight: Kirigami.Units.gridUnit * 10
        Layout.maximumHeight: Kirigami.Units.gridUnit * 36

        active: root.expanded
        sourceComponent: FullView {
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
    }

    toolTipMainText: "KVitals"
}
