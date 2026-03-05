import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import org.kde.kirigami 2.5 as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasma5support as Plasma5Support

KCM.SimpleKCM {
    id: metricsPage

    property bool cfg_showCpu
    property bool cfg_showRam
    property bool cfg_showTemp
    property bool cfg_showGpu
    property bool cfg_showBattery
    property bool cfg_showPower
    property bool cfg_showNetwork
    property string cfg_networkInterface: "auto"
    property string cfg_metricOrder: "cpu,ram,temp,gpu,bat,pwr,net"

    property var ifaceList: []

    readonly property var allKeys: ["cpu", "ram", "temp", "gpu", "bat", "pwr", "net"]

    readonly property var metricLabels: ({
        "cpu":  i18n("CPU Usage"),
        "ram":  i18n("RAM Usage"),
        "temp": i18n("CPU Temperature"),
        "gpu":  i18n("GPU Metrics"),
        "bat":  i18n("Battery Status"),
        "pwr":  i18n("Power Consumption"),
        "net":  i18n("Network Speed")
    })

    property var currentOrder: {
        var keys = cfg_metricOrder.split(",").map(function(k) { return k.trim(); }).filter(function(k) { return k.length > 0 && metricLabels[k] !== undefined; });
        // Add any missing keys at the end
        for (var j = 0; j < allKeys.length; j++) {
            if (keys.indexOf(allKeys[j]) < 0) {
                keys.push(allKeys[j]);
            }
        }
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
        }
    }

    function moveMetric(fromIndex, toIndex) {
        var keys = currentOrder.slice();
        var item = keys.splice(fromIndex, 1)[0];
        keys.splice(toIndex, 0, item);
        cfg_metricOrder = keys.join(",");
    }

    Plasma5Support.DataSource {
        id: ifaceSource
        engine: "executable"
        connectedSources: ["ls /sys/class/net/"]

        onNewData: function(source, data) {
            if (data["exit code"] !== 0) return;
            var raw = data["stdout"].trim();
            if (raw.length === 0) return;
            var ifaces = raw.split("\n").filter(function(name) {
                return name !== "lo" && name.length > 0;
            });
            ifaces.unshift("auto");
            metricsPage.ifaceList = ifaces;
        }
    }

    Kirigami.FormLayout {

        Label {
            Kirigami.FormData.label: i18n("Metric order:")
            text: i18n("Use ↑ ↓ to reorder metrics in the panel.")
            opacity: 0.7
            font.italic: true
        }

        ColumnLayout {
            spacing: 2

            Repeater {
                model: metricsPage.currentOrder

                delegate: RowLayout {
                    spacing: Kirigami.Units.smallSpacing
                    Layout.fillWidth: true

                    CheckBox {
                        checked: metricsPage.isChecked(modelData)
                        onToggled: metricsPage.setChecked(modelData, checked)
                    }

                    Label {
                        text: metricsPage.metricLabels[modelData] || modelData
                        Layout.fillWidth: true
                    }

                    Button {
                        icon.name: "arrow-up"
                        enabled: index > 0
                        flat: true
                        implicitWidth: 32
                        implicitHeight: 32
                        onClicked: metricsPage.moveMetric(index, index - 1)
                    }

                    Button {
                        icon.name: "arrow-down"
                        enabled: index < metricsPage.currentOrder.length - 1
                        flat: true
                        implicitWidth: 32
                        implicitHeight: 32
                        onClicked: metricsPage.moveMetric(index, index + 1)
                    }
                }
            }
        }

        ComboBox {
            id: ifaceCombo
            Kirigami.FormData.label: i18n("Network interface:")
            model: metricsPage.ifaceList
            enabled: cfg_showNetwork
            currentIndex: {
                var idx = metricsPage.ifaceList.indexOf(cfg_networkInterface);
                return idx >= 0 ? idx : 0;
            }
            onActivated: {
                cfg_networkInterface = metricsPage.ifaceList[currentIndex];
            }
        }
    }
}
