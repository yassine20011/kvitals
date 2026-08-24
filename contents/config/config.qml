import QtQuick 2.0

import org.kde.plasma.configuration 2.0

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "configure"
        source: "configGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Panel Items")
        icon: "edit-list-order"
        source: "configPanelOrder.qml"
    }
    ConfigCategory {
        name: i18n("Sensors & Hardware")
        icon: "preferences-system-hardware"
        source: "configMetrics.qml"
    }
    ConfigCategory {
        name: i18n("Icons")
        icon: "preferences-desktop-icons"
        source: "configIcons.qml"
    }
    ConfigCategory {
        name: i18n("Colors")
        icon: "color-management"
        source: "configColors.qml"
    }
}
