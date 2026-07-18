import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import org.kde.kirigami 2.5 as Kirigami
import org.kde.kcmutils as KCM
import org.kde.iconthemes as KIconThemes

KCM.SimpleKCM {
    id: iconsPage

    property string cfg_cpuIcon: "am-cpu-symbolic"
    property string cfg_ramIcon: "nvidia-ram-symbolic"
    property string cfg_tempIcon: "temperature-normal"
    property string cfg_gpuIcon: "gpu-symbolic"
    property string cfg_batteryIcon: "battery-good"
    property string cfg_powerIcon: "battery-charging-60"
    property string cfg_networkIcon: "network-wireless"
    property string cfg_diskIcon: "am-disk-utility-symbolic"
    property string cfg_fanIcon: "am-fan-symbolic"
    property string cfg_uptimeIcon: "clock"

    KIconThemes.IconDialog {
        id: cpuIconDialog
        onIconNameChanged: if (iconName) cfg_cpuIcon = iconName
    }
    KIconThemes.IconDialog {
        id: ramIconDialog
        onIconNameChanged: if (iconName) cfg_ramIcon = iconName
    }
    KIconThemes.IconDialog {
        id: tempIconDialog
        onIconNameChanged: if (iconName) cfg_tempIcon = iconName
    }
    KIconThemes.IconDialog {
        id: gpuIconDialog
        onIconNameChanged: if (iconName) cfg_gpuIcon = iconName
    }
    KIconThemes.IconDialog {
        id: batteryIconDialog
        onIconNameChanged: if (iconName) cfg_batteryIcon = iconName
    }
    KIconThemes.IconDialog {
        id: powerIconDialog
        onIconNameChanged: if (iconName) cfg_powerIcon = iconName
    }
    KIconThemes.IconDialog {
        id: networkIconDialog
        onIconNameChanged: if (iconName) cfg_networkIcon = iconName
    }
    KIconThemes.IconDialog {
        id: diskIconDialog
        onIconNameChanged: if (iconName) cfg_diskIcon = iconName
    }
    KIconThemes.IconDialog {
        id: fanIconDialog
        onIconNameChanged: if (iconName) cfg_fanIcon = iconName
    }

    KIconThemes.IconDialog {
        id: uptimeIconDialog
        onIconNameChanged: if (iconName) cfg_uptimeIcon = iconName
    }

    Kirigami.FormLayout {

        RowLayout {
            Kirigami.FormData.label: i18n("CPU:")
            Kirigami.Icon { source: cfg_cpuIcon; isMask: true; Layout.preferredWidth: 22; Layout.preferredHeight: 22 }
            Button { text: i18n("Change..."); onClicked: cpuIconDialog.open(); icon.name: "document-edit" }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("RAM:")
            Kirigami.Icon { source: cfg_ramIcon; isMask: true; Layout.preferredWidth: 22; Layout.preferredHeight: 22 }
            Button { text: i18n("Change..."); onClicked: ramIconDialog.open(); icon.name: "document-edit" }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Temperature:")
            Kirigami.Icon { source: cfg_tempIcon; isMask: true; Layout.preferredWidth: 22; Layout.preferredHeight: 22 }
            Button { text: i18n("Change..."); onClicked: tempIconDialog.open(); icon.name: "document-edit" }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("GPU:")
            Kirigami.Icon { source: cfg_gpuIcon; isMask: true; Layout.preferredWidth: 22; Layout.preferredHeight: 22 }
            Button { text: i18n("Change..."); onClicked: gpuIconDialog.open(); icon.name: "document-edit" }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Battery:")
            Kirigami.Icon { source: cfg_batteryIcon; isMask: true; Layout.preferredWidth: 22; Layout.preferredHeight: 22 }
            Button { text: i18n("Change..."); onClicked: batteryIconDialog.open(); icon.name: "document-edit" }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Power:")
            Kirigami.Icon { source: cfg_powerIcon; isMask: true; Layout.preferredWidth: 22; Layout.preferredHeight: 22 }
            Button { text: i18n("Change..."); onClicked: powerIconDialog.open(); icon.name: "document-edit" }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Network:")
            Kirigami.Icon { source: cfg_networkIcon; isMask: true; Layout.preferredWidth: 22; Layout.preferredHeight: 22 }
            Button { text: i18n("Change..."); onClicked: networkIconDialog.open(); icon.name: "document-edit" }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Disk:")
            Kirigami.Icon { source: cfg_diskIcon; isMask: true; Layout.preferredWidth: 22; Layout.preferredHeight: 22 }
            Button { text: i18n("Change..."); onClicked: diskIconDialog.open(); icon.name: "document-edit" }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Fan:")
            Kirigami.Icon { source: cfg_fanIcon; isMask: true; Layout.preferredWidth: 22; Layout.preferredHeight: 22 }
            Button { text: i18n("Change..."); onClicked: fanIconDialog.open(); icon.name: "document-edit" }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("System Uptime:")
            Kirigami.Icon { source: cfg_uptimeIcon; isMask: true; Layout.preferredWidth: 22; Layout.preferredHeight: 22 }
            Button { text: i18n("Change..."); onClicked: uptimeIconDialog.open(); icon.name: "document-edit" }
        }

        Button {
            icon.name: "edit-undo"
            text: i18n("Reset to defaults")
            Kirigami.FormData.label: " "
            onClicked: {
                cfg_cpuIcon = "am-cpu-symbolic";
                cfg_ramIcon = "nvidia-ram-symbolic";
                cfg_tempIcon = "temperature-normal";
                cfg_gpuIcon = "gpu-symbolic";
                cfg_batteryIcon = "battery-good";
                cfg_powerIcon = "battery-charging-60";
                cfg_networkIcon = "network-wireless";
                cfg_diskIcon = "am-disk-utility-symbolic";
                cfg_fanIcon = "am-fan-symbolic";
                cfg_uptimeIcon = "clock";
            }
        }
    }
}
