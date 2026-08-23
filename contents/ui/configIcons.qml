import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import org.kde.kirigami 2.5 as Kirigami
import org.kde.kcmutils as KCM
import org.kde.iconthemes as KIconThemes

KCM.SimpleKCM {
    id: iconsPage

    // Mirrors main.qml's resolveIcon(): these names only exist in third-party
    // icon themes (e.g. Win11/Win11-dark), so fall back to the bundled SVG
    // for the preview instead of showing a blank icon on Breeze etc.
    function resolveIcon(name) {
        if (!name) return "configure";
        if (name.indexOf("-symbolic") !== -1 && name.indexOf("/") === -1) {
            return Qt.resolvedUrl("../icons/" + name + ".svg");
        }
        return name;
    }

    property string cfg_cpuIcon: "cpu-symbolic"
    property string cfg_ramIcon: "memory-symbolic"
    property string cfg_swapIcon: "memory-symbolic"
    property string cfg_tempIcon: "temperature-symbolic"
    property string cfg_gpuIcon: "gpu-symbolic"
    property string cfg_batteryIcon: "battery-symbolic"
    property string cfg_powerIcon: "voltage-symbolic"
    property string cfg_networkIcon: "network-symbolic"
    property string cfg_diskIcon: "storage-symbolic"
    property string cfg_fanIcon: "fan-symbolic"
    property string cfg_uptimeIcon: "system-symbolic"

    KIconThemes.IconDialog {
        id: cpuIconDialog
        onIconNameChanged: if (iconName) cfg_cpuIcon = iconName
    }
    KIconThemes.IconDialog {
        id: ramIconDialog
        onIconNameChanged: if (iconName) cfg_ramIcon = iconName
    }
    KIconThemes.IconDialog {
        id: swapIconDialog
        onIconNameChanged: if (iconName) cfg_swapIcon = iconName
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
            Kirigami.Icon { source: resolveIcon(cfg_cpuIcon); isMask: true; Layout.preferredWidth: 22; Layout.preferredHeight: 22 }
            Button { text: i18n("Change..."); onClicked: cpuIconDialog.open(); icon.name: "document-edit" }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("RAM:")
            Kirigami.Icon { source: resolveIcon(cfg_ramIcon); isMask: true; Layout.preferredWidth: 22; Layout.preferredHeight: 22 }
            Button { text: i18n("Change..."); onClicked: ramIconDialog.open(); icon.name: "document-edit" }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Swap:")
            Kirigami.Icon { source: resolveIcon(cfg_swapIcon); isMask: true; Layout.preferredWidth: 22; Layout.preferredHeight: 22 }
            Button { text: i18n("Change..."); onClicked: swapIconDialog.open(); icon.name: "document-edit" }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Temperature:")
            Kirigami.Icon { source: cfg_tempIcon; isMask: true; Layout.preferredWidth: 22; Layout.preferredHeight: 22 }
            Button { text: i18n("Change..."); onClicked: tempIconDialog.open(); icon.name: "document-edit" }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("GPU:")
            Kirigami.Icon { source: resolveIcon(cfg_gpuIcon); isMask: true; Layout.preferredWidth: 22; Layout.preferredHeight: 22 }
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
            Kirigami.Icon { source: resolveIcon(cfg_diskIcon); isMask: true; Layout.preferredWidth: 22; Layout.preferredHeight: 22 }
            Button { text: i18n("Change..."); onClicked: diskIconDialog.open(); icon.name: "document-edit" }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Fan:")
            Kirigami.Icon { source: resolveIcon(cfg_fanIcon); isMask: true; Layout.preferredWidth: 22; Layout.preferredHeight: 22 }
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
                cfg_cpuIcon = "cpu-symbolic";
                cfg_ramIcon = "memory-symbolic";
                cfg_swapIcon = "memory-symbolic";
                cfg_tempIcon = "temperature-symbolic";
                cfg_gpuIcon = "gpu-symbolic";
                cfg_batteryIcon = "battery-symbolic";
                cfg_powerIcon = "voltage-symbolic";
                cfg_networkIcon = "network-symbolic";
                cfg_diskIcon = "storage-symbolic";
                cfg_fanIcon = "fan-symbolic";
                cfg_uptimeIcon = "system-symbolic";
            }
        }
    }
}
