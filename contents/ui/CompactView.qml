import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "models/MetricDefinitions.js" as MetricDefinitions

Item {
    id: compactRoot

    required property var metricsModel
    required property bool useIcons
    required property bool useText
    required property int effectiveFontSize
    required property string fontFamily
    required property bool fontBold
    required property int iconSize
    required property color baseTextColor
    required property color labelColor
    required property color iconColor
    required property string layoutType
    required property real labelOpacity
    required property real separatorOpacity
    required property bool showSeparators
    required property string backgroundType
    required property bool isPlanar

    readonly property bool isVertical: layoutType === "vertical"
    readonly property bool customFont: effectiveFontSize > 0

    readonly property int hPadding: (isPlanar && backgroundType !== "transparent" && backgroundType !== "shadow") ? Math.round(Kirigami.Units.gridUnit * 0.75) : 0
    readonly property int vPadding: (isPlanar && backgroundType !== "transparent" && backgroundType !== "shadow") ? Math.round(Kirigami.Units.smallSpacing * 0.75) : 0

    implicitWidth: compactRow.implicitWidth + (hPadding * 2)
    implicitHeight: compactRow.implicitHeight + (vPadding * 2)

    signal toggleExpanded()

    Rectangle {
        id: desktopBg
        visible: compactRoot.isPlanar && compactRoot.backgroundType !== "transparent" && compactRoot.backgroundType !== "shadow"
        anchors.centerIn: parent
        width: Math.min(parent ? parent.width : implicitWidth, compactRow.implicitWidth + (compactRoot.hPadding * 2))
        height: Math.min(parent ? parent.height : implicitHeight, compactRow.implicitHeight + (compactRoot.vPadding * 2))
        radius: Math.round(height * 0.5)
        color: {
            if (compactRoot.backgroundType === "translucent") {
                return Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.45);
            }
            return Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.80);
        }
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
        border.width: 1
    }

    TapHandler {
        onTapped: compactRoot.toggleExpanded()
    }

    RowLayout {
        id: compactRow
        anchors.centerIn: parent
        spacing: Math.round(Kirigami.Units.gridUnit * 0.65)

        readonly property var metricsModel: compactRoot.metricsModel
        readonly property bool useIcons: compactRoot.useIcons
        readonly property bool useText: compactRoot.useText
        readonly property int effectiveFontSize: compactRoot.effectiveFontSize
        readonly property string fontFamily: compactRoot.fontFamily
        readonly property bool fontBold: compactRoot.fontBold
        readonly property int iconSize: compactRoot.iconSize
        readonly property color baseTextColor: compactRoot.baseTextColor
        readonly property color labelColor: compactRoot.labelColor
        readonly property color iconColor: compactRoot.iconColor
        readonly property string layoutType: compactRoot.layoutType
        readonly property real labelOpacity: compactRoot.labelOpacity
        readonly property real separatorOpacity: compactRoot.separatorOpacity
        readonly property bool showSeparators: compactRoot.showSeparators
        readonly property bool isVertical: compactRoot.isVertical
        readonly property bool customFont: compactRoot.customFont

        // Defers isMask+color on Kirigami.Icon items until after the Plasma startup
        // window-attachment sequence (ShellCorona::addOutput) completes. This prevents
        // PlatformThemeData::setColor from being called while uninitialized (SIGSEGV #41).
        property bool _themeReady: false
        Timer {
            interval: 0
            repeat: false
            running: true
            onTriggered: compactRow._themeReady = true
        }

        // Sticky width cache
        property var _stickyWidths: ({})

        function resetStickyWidths() {
            _stickyWidths = ({});
        }

        onEffectiveFontSizeChanged: resetStickyWidths()
        onFontFamilyChanged: resetStickyWidths()
        onIconSizeChanged: resetStickyWidths()
        onLayoutTypeChanged: resetStickyWidths()
        onUseIconsChanged: resetStickyWidths()
        onUseTextChanged: resetStickyWidths()

        function _stickyWidth(key, w) {
            var cur = _stickyWidths[key] || 0;
            if (w > cur) {
                _stickyWidths[key] = w;
                cur = w;
            }
            return cur;
        }

    function resolveIcon(name) {
        if (!name) return "";
        var str = String(name);
        if (MetricDefinitions.isBundledIcon(str)) {
            return Qt.resolvedUrl("../icons/" + str + ".svg");
        }
        return name;
    }

    // Shared segments renderer
    component SegmentsRow: Row {
        id: segRoot
        required property var segments
        property string parentKey: ""
        spacing: 2

        Repeater {
            model: segments
            delegate: Row {
                required property var modelData
                required property int index
                spacing: 2

                PlasmaComponents.Label {
                    visible: index > 0
                    text: "·"
                    font.pixelSize: compactRow.customFont ? compactRow.effectiveFontSize : -1
                    font.family: compactRow.fontFamily
                    font.bold: compactRow.fontBold
                    color: compactRow.baseTextColor
                    opacity: compactRow.separatorOpacity
                    anchors.verticalCenter: parent.verticalCenter
                }

                Kirigami.Icon {
                    visible: !!modelData.icon && compactRow.useIcons
                    source: compactRow.resolveIcon(modelData.icon)
                    isMask: compactRow._themeReady
                    color: compactRow._themeReady ? compactRow.iconColor : Qt.rgba(0, 0, 0, 0)
                    width: Math.round(compactRow.iconSize * 0.85)
                    height: Math.round(compactRow.iconSize * 0.85)
                    anchors.verticalCenter: parent.verticalCenter
                }

                PlasmaComponents.Label {
                    visible: !!modelData.label && (!compactRow.useIcons || !modelData.icon)
                    text: modelData.label || ""
                    font.pixelSize: compactRow.customFont ? compactRow.effectiveFontSize : -1
                    font.family: compactRow.fontFamily
                    font.bold: compactRow.fontBold
                    color: compactRow.labelColor
                    opacity: compactRow.labelOpacity
                    anchors.verticalCenter: parent.verticalCenter
                }
                PlasmaComponents.Label {
                    text: modelData.value
                    font.pixelSize: compactRow.customFont ? compactRow.effectiveFontSize : -1
                    font.family: compactRow.fontFamily
                    font.bold: compactRow.fontBold
                    color: modelData.color
                    horizontalAlignment: Text.AlignRight
                    anchors.verticalCenter: parent.verticalCenter
                    // Row is a positioner, not a Layout: pad via plain `width`
                    // (Layout.preferredWidth has no effect here). Width only
                    // ever grows within the session to avoid reflow when a
                    // fluctuating value crosses a digit-count boundary.
                    width: compactRow._stickyWidth(
                        segRoot.parentKey + ":" + (modelData.key !== undefined ? modelData.key : index),
                        implicitWidth)
                }
            }
        }
    }

    RowLayout {
        visible: !compactRow.metricsModel || compactRow.metricsModel.length === 0
        spacing: Kirigami.Units.smallSpacing
        Layout.fillHeight: true

        Kirigami.Icon {
            source: "utilities-system-monitor"
            isMask: compactRow._themeReady
            color: compactRow._themeReady ? compactRow.iconColor : Qt.rgba(0, 0, 0, 0)
            width: compactRow.iconSize
            height: compactRow.iconSize
        }

        PlasmaComponents.Label {
            text: "KVitals"
            font.pixelSize: compactRow.customFont ? compactRow.effectiveFontSize : -1
            font.family: compactRow.fontFamily
            color: compactRow.labelColor
            opacity: compactRow.labelOpacity
        }
    }

    Repeater {
        model: compactRow.metricsModel

        delegate: Item {
            required property var modelData
            required property int index

            implicitWidth:  loader.implicitWidth
            implicitHeight: loader.implicitHeight

            Loader {
                id: loader
                anchors.fill: parent
                sourceComponent: compactRow.isVertical ? verticalDelegate : horizontalDelegate

                property var itemData:  modelData
                property int itemIndex: index
            }
        }
    }

    // ── Horizontal delegate ────────────────────────────────────────────────

    Component {
        id: horizontalDelegate

        RowLayout {
            spacing: Kirigami.Units.smallSpacing
            Layout.fillHeight: true

            // Thin line separator between metrics
            Rectangle {
                visible: itemIndex > 0 && compactRow.showSeparators && !itemData.hideSeparator
                width: 1
                Layout.fillHeight: true
                color: compactRow.baseTextColor
                opacity: compactRow.separatorOpacity
            }

            Row {
                visible: compactRow.useIcons
                spacing: 1
                Layout.alignment: Qt.AlignVCenter
                Repeater {
                    model: {
                        var src = itemData.icon;
                        if (!src) return [];
                        return typeof src === "string" ? [src] : src;
                    }
                    delegate: Kirigami.Icon {
                        source: compactRow.resolveIcon(modelData)
                        isMask: compactRow._themeReady
                        color: compactRow._themeReady ? compactRow.iconColor : Qt.rgba(0, 0, 0, 0)
                        width: compactRow.iconSize
                        height: compactRow.iconSize
                    }
                }
            }

            PlasmaComponents.Label {
                visible: compactRow.useText
                text: itemData.label
                font.pixelSize: compactRow.customFont ? compactRow.effectiveFontSize : -1
                font.family: compactRow.fontFamily
                color: compactRow.labelColor
                opacity: compactRow.labelOpacity
                Layout.alignment: Qt.AlignVCenter
            }

            PlasmaComponents.Label {
                id: valueLabel
                visible: !itemData.segments
                text: itemData.value || ""
                font.pixelSize: compactRow.customFont ? compactRow.effectiveFontSize : -1
                font.family: compactRow.fontFamily
                font.bold: compactRow.fontBold
                color: itemData.color || compactRow.baseTextColor
                horizontalAlignment: Text.AlignRight
                Layout.alignment: Qt.AlignVCenter
                // Width only ever grows within the session: avoids the panel
                // reflowing every time a fluctuating value (e.g. RPM) crosses
                // a digit-count boundary.
                Layout.preferredWidth: compactRow._stickyWidth(itemData.key || ("idx:" + itemIndex), implicitWidth)
            }

            SegmentsRow {
                visible: !!itemData.segments
                segments: itemData.segments || []
                parentKey: itemData.key || ("idx:" + itemIndex)
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    // ── Vertical delegate (value on top, icon+label below) ─────────────────

    Component {
        id: verticalDelegate

        RowLayout {
            spacing: Kirigami.Units.smallSpacing
            Layout.fillHeight: true

            // Thin line separator between metrics
            Rectangle {
                visible: itemIndex > 0 && compactRow.showSeparators && !itemData.hideSeparator
                width: 1
                Layout.fillHeight: true
                color: compactRow.baseTextColor
                opacity: compactRow.separatorOpacity
            }

            ColumnLayout {
                spacing: 1
                Layout.alignment: Qt.AlignVCenter

                // Top: value(s)
                RowLayout {
                    spacing: 0
                    Layout.alignment: Qt.AlignHCenter

                    PlasmaComponents.Label {
                        visible: !itemData.segments
                        text: itemData.value || ""
                        font.pixelSize: compactRow.customFont ? compactRow.effectiveFontSize : -1
                        font.family: compactRow.fontFamily
                        font.bold: compactRow.fontBold
                        color: itemData.color || compactRow.baseTextColor
                        horizontalAlignment: Text.AlignHCenter
                        // Width only ever grows within the session: avoids the panel
                        // reflowing every time a fluctuating value (e.g. RPM) crosses
                        // a digit-count boundary.
                        Layout.preferredWidth: compactRow._stickyWidth(itemData.key || ("idx:" + itemIndex), implicitWidth)
                    }

                    SegmentsRow {
                        visible: !!itemData.segments
                        segments: itemData.segments || []
                        parentKey: itemData.key || ("idx:" + itemIndex)
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                // Bottom: icon + label
                RowLayout {
                    visible: compactRow.useIcons || compactRow.useText
                    spacing: 2
                    Layout.alignment: Qt.AlignHCenter

                    Row {
                        visible: compactRow.useIcons
                        spacing: 1
                        Layout.alignment: Qt.AlignVCenter
                        Repeater {
                            model: {
                                var src = itemData.icon;
                                if (!src) return [];
                                return typeof src === "string" ? [src] : src;
                            }
                            delegate: Kirigami.Icon {
                                source: compactRow.resolveIcon(modelData)
                                isMask: compactRow._themeReady
                                color: compactRow._themeReady ? compactRow.iconColor : Qt.rgba(0, 0, 0, 0)
                                width:  Math.round(compactRow.iconSize * 0.85)
                                height: Math.round(compactRow.iconSize * 0.85)
                            }
                        }
                    }

                    PlasmaComponents.Label {
                        visible: compactRow.useText
                        text: {
                            var lbl = itemData.label || "";
                            return lbl.endsWith(":") ? lbl.slice(0, -1) : lbl;
                        }
                        font.pixelSize: compactRow.customFont
                            ? Math.max(8, compactRow.effectiveFontSize - 2)
                            : -1
                        font.family: compactRow.fontFamily
                        color: compactRow.labelColor
                        opacity: compactRow.labelOpacity
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }
    }
}
}
