import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasmoid
import "./models"
import "./models/MetricDefinitions.js" as MetricDefinitions

KCM.SimpleKCM {
    id: panelOrderPage

    property string cfg_pinnedMetrics: ""
    property string cfg_cpuLabel: "CPU"
    property string cfg_ramLabel: "RAM"
    property string cfg_swapLabel: "SWAP"
    property string cfg_tempLabel: "System"
    property string cfg_netLabel: "NET"
    property string cfg_diskLabel: "DSK"
    property string cfg_fanLabel: "FAN"
    property string cfg_batLabel: "BAT"

    MetricConfig {
        id: metricConfig
        target: panelOrderPage
        propertyPrefix: "cfg_"
    }

    HardwareDiscovery {
        id: discovery
    }

    // Icon resolver
    function resolveIcon(name) {
        if (!name) return "configure";
        if (name.indexOf("-symbolic") !== -1 && name.indexOf("/") === -1) {
            return Qt.resolvedUrl("../../icons/" + name + ".svg");
        }
        return name;
    }

    // Computed list of pinned items
    readonly property var currentList: {
        if (!cfg_pinnedMetrics) return [];
        return cfg_pinnedMetrics.split(",").map(function(s){ return s.trim(); }).filter(function(s){ return s.length > 0; });
    }

    function isPinned(id) {
        return currentList.indexOf(id) !== -1;
    }

    function toggleItem(id) {
        if (!id) return;
        var list = currentList.slice();
        var idx = list.indexOf(id);
        var oldX = stripList.contentX;
        if (idx !== -1) {
            list.splice(idx, 1);
            cfg_pinnedMetrics = list.join(",");
            Qt.callLater(function() {
                stripList.contentX = Math.max(0, Math.min(oldX, stripList.contentWidth - stripList.width));
            });
        } else {
            list.push(id);
            cfg_pinnedMetrics = list.join(",");
            Qt.callLater(function() {
                stripList.positionViewAtIndex(list.length - 1, ListView.Contain);
            });
        }
    }

    function removeItem(index) {
        if (index < 0 || index >= currentList.length) return;
        var list = currentList.slice();
        list.splice(index, 1);
        var oldX = stripList.contentX;
        cfg_pinnedMetrics = list.join(",");
        Qt.callLater(function() {
            stripList.contentX = Math.max(0, Math.min(oldX, stripList.contentWidth - stripList.width));
        });
    }

    function moveItem(fromIdx, toIdx) {
        if (fromIdx < 0 || fromIdx >= currentList.length || toIdx < 0 || toIdx >= currentList.length || fromIdx === toIdx) return;
        var list = currentList.slice();
        var item = list.splice(fromIdx, 1)[0];
        list.splice(toIdx, 0, item);
        var oldX = stripList.contentX;
        cfg_pinnedMetrics = list.join(",");
        Qt.callLater(function() {
            stripList.contentX = Math.max(0, Math.min(oldX, stripList.contentWidth - stripList.width));
            stripList.positionViewAtIndex(toIdx, ListView.Contain);
        });
    }

    function describeMetric(instanceId) {
        if (!instanceId) return { id: "", label: "", icon: "configure", preview: "" };
        var colonIdx = instanceId.indexOf(":");
        var slashIdx = instanceId.indexOf("/");
        var group = "";
        var devId = "";
        var subKey = "";

        if (colonIdx !== -1) {
            group = instanceId.substring(0, colonIdx);
            devId = instanceId.substring(colonIdx + 1, slashIdx !== -1 ? slashIdx : instanceId.length);
            subKey = slashIdx !== -1 ? instanceId.substring(slashIdx + 1) : "";
        } else if (slashIdx !== -1) {
            group = instanceId.substring(0, slashIdx);
            subKey = instanceId.substring(slashIdx + 1);
        } else {
            group = instanceId;
        }

        var defKey = group + "." + subKey;
        var def = MetricDefinitions.DEFINITIONS[defKey] || {};
        var grp = MetricDefinitions.GROUPS[group] || {};

        var icon = (subKey === "temp" || group === "temp") ? "temperature-symbolic" : (grp.defaultIcon || "configure");
        var groupTitle = grp.name || group.toUpperCase();
        var subLabel = def.label || subKey;
        var displayName = (devId ? devId + " " : "") + subLabel;

        // Mockup preview values
        var previewVal = "";
        if (group === "cpu") {
            if (subKey === "core") {
                var cNum = parseInt(devId.replace("cpu", ""), 10);
                displayName = "Core " + (!isNaN(cNum) ? (cNum + 1) : devId);
                previewVal = "28%";
            } else {
                previewVal = subKey === "usage" ? "22%" : (subKey === "freq" ? "3.6 GHz" : (subKey === "temp" ? "62°C" : (subKey === "load1" ? "1.20" : (subKey === "load5" ? "1.05" : (subKey === "load15" ? "0.95" : "22%")))));
            }
        } else if (group === "ram") {
            previewVal = subKey === "percentage" ? "35%" : (subKey === "used" ? "8.4/32G" : "42°C");
        } else if (group === "swap") {
            previewVal = subKey === "percent" ? "0%" : "0 MB";
        } else if (group === "temp") {
            previewVal = "62°C";
        } else if (group === "bat") {
            previewVal = subKey === "percentage" ? "85%" : (subKey === "power" ? "14.2W" : (subKey === "health" ? "98%" : "85%"));
        } else if (group === "net") {
            if (subKey === "signal") {
                icon = "network-wireless-symbolic";
                previewVal = "78%";
            } else if (subKey === "totalDown") {
                icon = "network-download-symbolic";
                previewVal = "1.24 GB";
            } else if (subKey === "totalUp") {
                icon = "network-upload-symbolic";
                previewVal = "240 MB";
            } else {
                previewVal = subKey === "down" ? "↓ 1.2MB" : (subKey === "up" ? "↑ 240KB" : "192.168.1.1");
            }
        } else if (group === "disk") {
            previewVal = subKey === "read" ? "↓ 45MB" : (subKey === "write" ? "↑ 12MB" : (subKey === "usage" ? "45%" : (subKey === "space" ? "220/512G" : "54°C")));
        } else if (group === "fan") {
            previewVal = "2400 RPM";
        } else if (group === "uptime") {
            previewVal = "2h 45m";
        } else if (group === "gpu") {
            previewVal = subKey === "usage" ? "15%" : (subKey === "vram" ? "1.2/8G" : (subKey === "freq" ? "1850 MHz" : (subKey === "power" ? "65.0W" : "48°C")));
        }

        return {
            id: instanceId,
            group: group,
            deviceId: devId,
            subKey: subKey,
            icon: icon,
            groupTitle: groupTitle,
            label: displayName,
            preview: previewVal
        };
    }

    // Palette categories
    readonly property var paletteCategories: {
        var cats = [];

        // 1. Processor (CPU)
        var cores = discovery.discoveredCores || [];
        var cpuItems = [
            { id: "cpu/usage", label: i18n("CPU Usage"), icon: "cpu-symbolic" },
            { id: "cpu/freq", label: i18n("CPU Frequency"), icon: "cpu-symbolic" },
            { id: "cpu/temp", label: i18n("CPU Temperature"), icon: "temperature-symbolic" },
            { id: "cpu/load1", label: i18n("CPU Load (1m)"), icon: "cpu-symbolic" },
            { id: "cpu/load5", label: i18n("CPU Load (5m)"), icon: "cpu-symbolic" },
            { id: "cpu/load15", label: i18n("CPU Load (15m)"), icon: "cpu-symbolic" }
        ];
        for (var ci = 0; ci < cores.length; ci++) {
            cpuItems.push({ id: "cpu:" + cores[ci].id + "/core", label: cores[ci].name, icon: "cpu-symbolic" });
        }
        cats.push({
            title: i18n("Processor (CPU)"),
            icon: "cpu-symbolic",
            items: cpuItems
        });

        // 2. Memory (RAM & Swap)
        cats.push({
            title: i18n("Memory (RAM & Swap)"),
            icon: "memory-symbolic",
            items: [
                { id: "ram/percentage", label: i18n("RAM Percentage"), icon: "memory-symbolic" },
                { id: "ram/used", label: i18n("RAM Used / Total"), icon: "memory-symbolic" },
                { id: "swap/percent", label: i18n("Swap Percentage"), icon: "memory-symbolic" },
                { id: "swap/used", label: i18n("Swap Used"), icon: "memory-symbolic" }
            ]
        });

        // 3. Temperature
        cats.push({
            title: i18n("Temperature"),
            icon: "temperature-symbolic",
            items: [
                { id: "temp/system", label: i18n("System Temperature"), icon: "temperature-symbolic" }
            ]
        });

        // 4. Battery & Power
        cats.push({
            title: i18n("Battery & Power"),
            icon: "battery-symbolic",
            items: [
                { id: "bat/percentage", label: i18n("Battery Percentage"), icon: "battery-symbolic" },
                { id: "bat/power", label: i18n("Power Draw (W)"), icon: "voltage-symbolic" },
                { id: "bat/health", label: i18n("Battery Health"), icon: "battery-symbolic" }
            ]
        });

        // 5. Network
        var netItems = [
            { id: "net/down", label: i18n("Download"), icon: "network-download-symbolic" },
            { id: "net/up", label: i18n("Upload"), icon: "network-upload-symbolic" },
            { id: "net/totalDown", label: i18n("Total Download"), icon: "network-download-symbolic" },
            { id: "net/totalUp", label: i18n("Total Upload"), icon: "network-upload-symbolic" },
            { id: "net/ip", label: i18n("Local IP"), icon: "network-symbolic" }
        ];
        var hasWifi = discovery.queryIds(/^network\/[^/]+\/signal$/).length > 0;
        if (hasWifi) {
            netItems.push({ id: "net/signal", label: i18n("Wi-Fi Signal"), icon: "network-wireless-symbolic" });
        }
        cats.push({
            title: i18n("Network"),
            icon: "network-symbolic",
            items: netItems
        });

        // 6. Graphics (GPU)
        var gpus = discovery.discoveredGpus || [];
        if (gpus.length > 0) {
            var gpuItems = [];
            for (var gi = 0; gi < gpus.length; gi++) {
                var gid = gpus[gi].id;
                var gName = gpus[gi].name;
                gpuItems.push({ id: "gpu:" + gid + "/usage", label: gName + " Usage", icon: "gpu-symbolic" });
                gpuItems.push({ id: "gpu:" + gid + "/vram", label: gName + " VRAM", icon: "gpu-symbolic" });
                gpuItems.push({ id: "gpu:" + gid + "/temp", label: gName + " Temp", icon: "temperature-symbolic" });
                gpuItems.push({ id: "gpu:" + gid + "/freq", label: gName + " Frequency", icon: "gpu-symbolic" });
                gpuItems.push({ id: "gpu:" + gid + "/power", label: gName + " Power", icon: "voltage-symbolic" });
            }
            cats.push({
                title: i18n("Graphics (GPU)"),
                icon: "gpu-symbolic",
                items: gpuItems
            });
        }

        // 7. Storage (Disks)
        var disks = discovery.discoveredDisks || [];
        var diskItems = [
            { id: "disk/usage", label: i18n("Overall Usage (%)"), icon: "storage-symbolic" },
            { id: "disk/space", label: i18n("Overall Space"), icon: "storage-symbolic" }
        ];
        for (var di = 0; di < disks.length; di++) {
            var did = disks[di].id;
            var dName = did.indexOf("nvme") !== -1 ? "NVMe" : did;
            diskItems.push({ id: "disk:" + did + "/read", label: dName + " Read", icon: "network-download-symbolic" });
            diskItems.push({ id: "disk:" + did + "/write", label: dName + " Write", icon: "network-upload-symbolic" });
            diskItems.push({ id: "disk:" + did + "/temp", label: dName + " Temp", icon: "temperature-symbolic" });
        }
        if (diskItems.length > 0) {
            cats.push({
                title: i18n("Storage (Disks)"),
                icon: "storage-symbolic",
                items: diskItems
            });
        }

        // 8. Cooling (Fans)
        var fans = discovery.discoveredFans || [];
        if (fans.length > 0) {
            var fanItems = [];
            for (var fi = 0; fi < fans.length; fi++) {
                fanItems.push({ id: "fan:" + fans[fi].id + "/speed", label: i18n("Fan %1 Speed", (fi + 1)), icon: "fan-symbolic" });
            }
            cats.push({
                title: i18n("Cooling (Fans)"),
                icon: "fan-symbolic",
                items: fanItems
            });
        }

        // 9. System
        cats.push({
            title: i18n("System"),
            icon: "system-symbolic",
            items: [
                { id: "uptime/uptime", label: i18n("System Uptime"), icon: "system-symbolic" }
            ]
        });

        return cats;
    }

    Kirigami.FormLayout {
        id: formLayout

        // ── Section 1: Live Panel Preview ───────────────────────────────────

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Live Panel Preview")
        }

        QQC2.Label {
            text: i18n("The strip below shows your active panel order. Use ◀ / ▶ on any tile to swap positions, or click ✕ to unpin.")
            opacity: 0.7
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // Live Horizontal Strip Mockup
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 82
            radius: 8
            color: Qt.rgba(0.08, 0.1, 0.14, 0.85)
            border.color: Qt.rgba(1, 1, 1, 0.15)
            border.width: 1

            QQC2.Label {
                anchors.centerIn: parent
                visible: panelOrderPage.currentList.length === 0
                text: i18n("No metrics pinned. Click any chip below to add it.")
                opacity: 0.5
                font.italic: true
            }

            ListView {
                id: stripList
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: scrollBar.visible ? scrollBar.top : parent.bottom
                anchors.topMargin: 8
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.bottomMargin: scrollBar.visible ? 2 : 8
                orientation: ListView.Horizontal
                spacing: 8
                clip: true
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds
                model: panelOrderPage.currentList

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: (event) => {
                        var delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                        stripList.contentX = Math.max(0, Math.min(stripList.contentX - delta, stripList.contentWidth - stripList.width));
                    }
                }

                delegate: Rectangle {
                    id: chipCard
                    required property var modelData
                    required property int index

                    width: cardRow.implicitWidth + 14
                    height: stripList.height
                    radius: 6
                    color: Qt.rgba(0.18, 0.22, 0.28, 0.9)
                    border.color: Qt.rgba(1, 1, 1, 0.18)
                    border.width: 1

                    RowLayout {
                        id: cardRow
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        spacing: 6

                        Kirigami.Icon {
                            property var info: panelOrderPage.describeMetric(chipCard.modelData)
                            source: panelOrderPage.resolveIcon(info.icon)
                            implicitWidth: 16
                            implicitHeight: 16
                            Layout.alignment: Qt.AlignVCenter
                        }

                        ColumnLayout {
                            spacing: 1
                            Layout.alignment: Qt.AlignVCenter

                            QQC2.Label {
                                property var info: panelOrderPage.describeMetric(chipCard.modelData)
                                text: info.label
                                font.pixelSize: Math.max(9, Kirigami.Theme.defaultFont.pixelSize - 3)
                                opacity: 0.65
                            }

                            QQC2.Label {
                                property var info: panelOrderPage.describeMetric(chipCard.modelData)
                                text: info.preview
                                font.bold: true
                                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize - 1
                                color: Kirigami.Theme.highlightColor
                            }
                        }

                        QQC2.ToolButton {
                            icon.name: "go-previous"
                            implicitWidth: 20
                            implicitHeight: 20
                            enabled: chipCard.index > 0
                            onClicked: panelOrderPage.moveItem(chipCard.index, chipCard.index - 1)
                            QQC2.ToolTip.text: i18n("Shift Left")
                            QQC2.ToolTip.visible: hovered
                        }

                        QQC2.ToolButton {
                            icon.name: "go-next"
                            implicitWidth: 20
                            implicitHeight: 20
                            enabled: chipCard.index < panelOrderPage.currentList.length - 1
                            onClicked: panelOrderPage.moveItem(chipCard.index, chipCard.index + 1)
                            QQC2.ToolTip.text: i18n("Shift Right")
                            QQC2.ToolTip.visible: hovered
                        }

                        QQC2.ToolButton {
                            icon.name: "dialog-close"
                            implicitWidth: 20
                            implicitHeight: 20
                            onClicked: panelOrderPage.removeItem(chipCard.index)
                            QQC2.ToolTip.text: i18n("Unpin")
                            QQC2.ToolTip.visible: hovered
                        }
                    }
                }
            }

            QQC2.ScrollBar {
                id: scrollBar
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 4
                height: 6
                orientation: Qt.Horizontal
                size: stripList.width / Math.max(stripList.width, stripList.contentWidth)
                position: stripList.contentX / Math.max(1, stripList.contentWidth)
                visible: stripList.contentWidth > stripList.width
                active: visible
                onPositionChanged: {
                    if (pressed) {
                        stripList.contentX = position * stripList.contentWidth;
                    }
                }
            }
        }

        RowLayout {
            spacing: Kirigami.Units.smallSpacing

            QQC2.Button {
                text: i18n("Reset Default Order")
                icon.name: "edit-undo"
                onClicked: {
                    cfg_pinnedMetrics = "cpu/usage,cpu/freq,cpu/temp,ram/percentage,temp/system,net/down,net/up";
                }
            }

            QQC2.Button {
                text: i18n("Clear All")
                icon.name: "edit-clear"
                enabled: panelOrderPage.currentList.length > 0
                onClicked: {
                    cfg_pinnedMetrics = "";
                }
            }
        }

        // ── Section 2: Available Metric Palette ─────────────────────────────

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Metric Palette (Click to Add / Remove)")
        }

        Repeater {
            model: panelOrderPage.paletteCategories

            delegate: Flow {
                id: catFlow
                required property var modelData
                Kirigami.FormData.label: catFlow.modelData.title + ":"
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Repeater {
                    model: catFlow.modelData.items

                    delegate: QQC2.Button {
                        id: metricChip
                        required property var modelData

                        property bool isSelected: panelOrderPage.isPinned(modelData.id)

                        icon.name: isSelected ? "dialog-ok-apply" : "list-add"
                        text: modelData.label
                        highlighted: isSelected

                        onClicked: panelOrderPage.toggleItem(modelData.id)

                        QQC2.ToolTip.text: isSelected ? i18n("Pinned — click to remove") : i18n("Click to add to panel")
                        QQC2.ToolTip.visible: hovered
                    }
                }
            }
        }
    }
}
