import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import org.kde.kirigami 2.5 as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasma5support as Plasma5Support

KCM.SimpleKCM {
    id: configPage

    property alias cfg_showCpu: showCpuCheck.checked
    property alias cfg_showRam: showRamCheck.checked
    property alias cfg_showTemp: showTempCheck.checked
    property alias cfg_showBattery: showBatteryCheck.checked
    property alias cfg_showPower: showPowerCheck.checked
    property alias cfg_showNetwork: showNetworkCheck.checked
    property alias cfg_updateInterval: intervalSlider.value
    property string cfg_networkInterface: "auto"

    property var ifaceList: []

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
            configPage.ifaceList = ifaces;
        }
    }

    Kirigami.FormLayout {

        CheckBox {
            id: showCpuCheck
            text: i18n("Show CPU usage")
            Kirigami.FormData.label: i18n("Metrics:")
        }

        CheckBox {
            id: showRamCheck
            text: i18n("Show RAM usage")
        }

        CheckBox {
            id: showTempCheck
            text: i18n("Show CPU temperature")
        }

        CheckBox {
            id: showBatteryCheck
            text: i18n("Show battery status")
        }

        CheckBox {
            id: showPowerCheck
            text: i18n("Show power consumption")
        }

        CheckBox {
            id: showNetworkCheck
            text: i18n("Show network speed")
        }

        ComboBox {
            id: ifaceCombo
            Kirigami.FormData.label: i18n("Network interface:")
            model: configPage.ifaceList
            enabled: showNetworkCheck.checked
            currentIndex: {
                var idx = configPage.ifaceList.indexOf(cfg_networkInterface);
                return idx >= 0 ? idx : 0;
            }
            onActivated: {
                cfg_networkInterface = configPage.ifaceList[currentIndex];
            }
        }

        Slider {
            id: intervalSlider
            Kirigami.FormData.label: i18n("Update interval:")
            from: 1000
            to: 10000
            stepSize: 500
            value: 2000
        }

        Label {
            text: (intervalSlider.value / 1000).toFixed(1) + " " + i18n("seconds")
            opacity: 0.7
        }
    }
}
