import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
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

    readonly property bool isPlanar: Plasmoid.formFactor === PlasmaCore.Types.Planar
    Layout.preferredWidth: compactRepresentationItem ? compactRepresentationItem.implicitWidth : -1
    Layout.preferredHeight: compactRepresentationItem ? compactRepresentationItem.implicitHeight : -1

    // Display and appearance properties
    property string displayMode: Plasmoid.configuration.displayMode
    property string layoutType:  Plasmoid.configuration.layoutType
    property string backgroundType: Plasmoid.configuration.backgroundType || "default"
    property int iconSize:       Plasmoid.configuration.iconSize
    property string fontFamily:  Plasmoid.configuration.fontFamily
    property int fontSize:       Plasmoid.configuration.fontSize
    property bool fontBold:      Plasmoid.configuration.fontBold
    property real labelOpacity:  Plasmoid.configuration.labelOpacity
    property real separatorOpacity: Plasmoid.configuration.separatorOpacity
    property int effectiveFontSize: fontSize > 0 ? fontSize : -1
    property bool mergeFamilyMetrics: Plasmoid.configuration.mergeFamilyMetrics !== undefined ? Plasmoid.configuration.mergeFamilyMetrics : true

    property bool showSeparators: Plasmoid.configuration.showSeparators !== undefined ? Plasmoid.configuration.showSeparators : true

    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground

    function applyBackgroundType() {
        if (!root.isPlanar) {
            if (Plasmoid.userBackgroundHints !== PlasmaCore.Types.DefaultBackground) {
                Plasmoid.userBackgroundHints = PlasmaCore.Types.DefaultBackground;
            }
            return;
        }

        var targetHint;
        if (root.backgroundType === "shadow") {
            targetHint = PlasmaCore.Types.ShadowBackground;
        } else {
            targetHint = PlasmaCore.Types.NoBackground;
        }
        if (Plasmoid.userBackgroundHints !== targetHint) {
            Plasmoid.userBackgroundHints = targetHint;
        }
    }

    onBackgroundTypeChanged: applyBackgroundType()
    onIsPlanarChanged: applyBackgroundType()

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
        popupExpanded: root.expanded
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
                popupExpanded: root.expanded
                hasPinnedCores: {
                    var pl = metricConfig.pinnedList || [];
                    for (var i = 0; i < pl.length; i++) {
                        if (pl[i].indexOf("/core") !== -1) return true;
                    }
                    return false;
                }
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
        applyBackgroundType();
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

    // Popup item components
    component PopupMetric: QtObject {
        property string id: ""
        property string label: ""
        property string subLabel: ""
        property var icon: ""
        property string displayValue: ""
        property var color: ""
        property bool isPinned: false
    }

    component PopupSection: QtObject {
        property string sectionLabel: ""
        property var metrics: []
    }

    component PopupCategory: QtObject {
        property string key: ""
        property string groupLabel: ""
        property var icon: ""
        property string aggregateValue: ""
        property var aggregateColor: ""
        property var sections: []
    }

    Component { id: popupMetricComp; PopupMetric {} }
    Component { id: popupSectionComp; PopupSection {} }
    Component { id: popupCategoryComp; PopupCategory {} }

    function _createPopupGroupObject(rawCat) {
        var secList = [];
        if (rawCat.sections && rawCat.sections.length) {
            for (var s = 0; s < rawCat.sections.length; s++) {
                var rawSec = rawCat.sections[s];
                var metList = [];
                if (rawSec.metrics && rawSec.metrics.length) {
                    for (var m = 0; m < rawSec.metrics.length; m++) {
                        var rawMet = rawSec.metrics[m];
                        var metObj = popupMetricComp.createObject(root, {
                            id: rawMet.id || "",
                            label: rawMet.label || "",
                            subLabel: rawMet.subLabel || "",
                            icon: rawMet.icon || "",
                            displayValue: rawMet.displayValue || "",
                            color: rawMet.color || "",
                            isPinned: Boolean(rawMet.isPinned)
                        });
                        metList.push(metObj);
                    }
                }
                var secObj = popupSectionComp.createObject(root, {
                    sectionLabel: rawSec.sectionLabel || "",
                    metrics: metList
                });
                secList.push(secObj);
            }
        }
        return popupCategoryComp.createObject(root, {
            key: rawCat.key || "",
            groupLabel: rawCat.groupLabel || "",
            icon: rawCat.icon || "",
            aggregateValue: rawCat.aggregateValue || "",
            aggregateColor: rawCat.aggregateColor || "",
            sections: secList
        });
    }

    function _destroyPopupGroups(groups) {
        if (!groups) return;
        for (var i = 0; i < groups.length; i++) {
            var cat = groups[i];
            if (cat) {
                if (cat.sections) {
                    for (var s = 0; s < cat.sections.length; s++) {
                        var sec = cat.sections[s];
                        if (sec) {
                            if (sec.metrics) {
                                for (var m = 0; m < sec.metrics.length; m++) {
                                    if (sec.metrics[m]) sec.metrics[m].destroy();
                                }
                            }
                            sec.destroy();
                        }
                    }
                }
                cat.destroy();
            }
        }
    }

    function _updatePopupGroups() {
        if (!root.expanded) {
            return;
        }
        var rawGroups = ViewHelpers.buildPopupGroups(metricStore.metrics, metricConfig.orderedKeys);
        if (ViewHelpers.syncPopupGroups(root._popupGroups, rawGroups)) {
            return;
        }
        var old = root._popupGroups;
        var newList = [];
        for (var i = 0; i < rawGroups.length; i++) {
            newList.push(_createPopupGroupObject(rawGroups[i]));
        }
        root._popupGroups = newList;
        _destroyPopupGroups(old);
    }

    property var _compactItems: []
    property var _popupGroups: []

    onExpandedChanged: {
        if (root.expanded) {
            _updatePopupGroups();
        } else {
            var old = root._popupGroups;
            root._popupGroups = [];
            _destroyPopupGroups(old);
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
                root._updatePopupGroups();
            }
        }
    }

    Connections {
        target: metricConfig
        function onPinnedListChanged() {
            root._updateCompactItems();
            if (root.expanded) {
                root._updatePopupGroups();
            }
        }
        function onOrderedKeysChanged() {
            if (root.expanded) {
                root._updatePopupGroups();
            }
        }
    }

    // Representations
    compactRepresentation: CompactView {
        metricsModel: root._compactItems
        layoutType: root.layoutType
        backgroundType: root.backgroundType
        isPlanar: root.isPlanar
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

        Layout.preferredWidth: implicitWidth
        Layout.preferredHeight: implicitHeight
        Layout.minimumWidth: implicitWidth
        Layout.minimumHeight: implicitHeight
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
