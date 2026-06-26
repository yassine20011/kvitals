import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import org.kde.kirigami 2.5 as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: configPage

    property alias cfg_updateInterval: intervalSlider.value
    property alias cfg_iconSize: iconSizeSlider.value
    property alias cfg_fontSize: fontSizeSlider.value
    property alias cfg_fontBold: fontBoldCheck.checked
    property string cfg_displayMode: "text"
    property string cfg_fontFamily: "monospace"
    property string cfg_layoutType: "horizontal"
    property string cfg_tempUnit: "C"
    property string cfg_networkUnit: "bytes"

    readonly property var displayModes: ["text", "icons", "icons+text", "none"]
    readonly property var displayModeLabels: [i18n("Text"), i18n("Icons"), i18n("Icons + Text"), i18n("None")]
    readonly property bool iconsEnabled: cfg_displayMode === "icons" || cfg_displayMode === "icons+text"

    readonly property var layoutTypes: ["horizontal", "vertical"]
    readonly property var layoutTypeLabels: [i18n("Horizontal"), i18n("Vertical")]

    Kirigami.FormLayout {

        ComboBox {
            id: displayModeCombo
            Kirigami.FormData.label: i18n("Display mode:")
            model: configPage.displayModeLabels
            currentIndex: {
                var idx = configPage.displayModes.indexOf(cfg_displayMode);
                return idx >= 0 ? idx : 0;
            }
            onActivated: {
                cfg_displayMode = configPage.displayModes[currentIndex];
            }
        }

        ComboBox {
            id: layoutTypeCombo
            Kirigami.FormData.label: i18n("Layout:")
            model: configPage.layoutTypeLabels
            currentIndex: {
                var idx = configPage.layoutTypes.indexOf(cfg_layoutType);
                return idx >= 0 ? idx : 0;
            }
            onActivated: {
                cfg_layoutType = configPage.layoutTypes[currentIndex];
            }
        }

        Slider {
            id: iconSizeSlider
            Kirigami.FormData.label: i18n("Icon size:")
            from: 8
            to: 24
            stepSize: 2
            value: 12
            visible: configPage.iconsEnabled
        }

        Label {
            text: iconSizeSlider.value + " px"
            opacity: 0.7
            visible: configPage.iconsEnabled
        }

        ComboBox {
            id: fontFamilyCombo
            Kirigami.FormData.label: i18n("Font:")
            model: Qt.fontFamilies()
            editable: true
            currentIndex: {
                var families = Qt.fontFamilies();
                var idx = families.indexOf(cfg_fontFamily);
                return idx >= 0 ? idx : 0;
            }
            onActivated: {
                cfg_fontFamily = currentText;
            }
            onAccepted: {
                cfg_fontFamily = editText;
            }
            popup.height: 300
        }

        Slider {
            id: fontSizeSlider
            Kirigami.FormData.label: i18n("Font size:")
            from: 0
            to: 24
            stepSize: 1
            value: 0
        }

        Label {
            text: fontSizeSlider.value === 0 ? i18n("System default") : fontSizeSlider.value + " px"
            opacity: 0.7
        }

        CheckBox {
            id: fontBoldCheck
            Kirigami.FormData.label: i18n("Bold font:")
            text: i18n("Bold")
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

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Unit Preferences")
        }

        ComboBox {
            id: tempUnitCombo
            Kirigami.FormData.label: i18n("Temperature unit:")
            model: [i18n("Celsius (°C)"), i18n("Fahrenheit (°F)")]
            currentIndex: cfg_tempUnit === "F" ? 1 : 0
            onActivated: cfg_tempUnit = (currentIndex === 1 ? "F" : "C")
        }

        ComboBox {
            id: networkUnitCombo
            Kirigami.FormData.label: i18n("Network/Disk I/O unit:")
            model: [i18n("Bytes  (KB, MB)"), i18n("Bits  (Kb, Mb)")]
            currentIndex: cfg_networkUnit === "bits" ? 1 : 0
            onActivated: cfg_networkUnit = (currentIndex === 1 ? "bits" : "bytes")
        }
    }
}
