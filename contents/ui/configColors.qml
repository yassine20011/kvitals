import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import Qt.labs.platform 1.0 as Platform
import org.kde.kirigami 2.5 as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: colorsPage

    property alias cfg_useCustomColors: useCustomColorsCheck.checked
    property string cfg_fontColor
    property alias cfg_enableThresholdColors: enableThresholdCheck.checked
    property string cfg_warningColor: "#e5a50a"
    property string cfg_criticalColor: "#da4453"
    property alias cfg_cpuWarningThreshold: cpuWarnSlider.value
    property alias cfg_cpuCriticalThreshold: cpuCritSlider.value
    property alias cfg_tempWarningThreshold: tempWarnSlider.value
    property alias cfg_tempCriticalThreshold: tempCritSlider.value
    property alias cfg_ramWarningThreshold: ramWarnSlider.value
    property alias cfg_ramCriticalThreshold: ramCritSlider.value
    property alias cfg_gpuWarningThreshold: gpuWarnSlider.value
    property alias cfg_gpuCriticalThreshold: gpuCritSlider.value
    property alias cfg_gpuTempWarningThreshold: gpuTempWarnSlider.value
    property alias cfg_gpuTempCriticalThreshold: gpuTempCritSlider.value
    property alias cfg_batteryWarningThreshold: batWarnSlider.value
    property alias cfg_batteryCriticalThreshold: batCritSlider.value

    readonly property string defaultWarningColor: "#e5a50a"
    readonly property string defaultCriticalColor: "#da4453"

    function isRgbHex(value) {
        return /^#[0-9A-Fa-f]{6}$/.test(value)
    }

    function colorToRgbHex(colorValue) {
        if (!colorValue || colorValue.r === undefined || colorValue.g === undefined || colorValue.b === undefined) {
            return ""
        }

        function channelToHex(channel) {
            const value = Math.max(0, Math.min(255, Math.round(channel * 255)))
            return value.toString(16).padStart(2, "0")
        }

        return "#" + channelToHex(colorValue.r) + channelToHex(colorValue.g) + channelToHex(colorValue.b)
    }

    function openColorDialog(dialog, value, fallbackColor) {
        const initialColor = isRgbHex(value) ? value : fallbackColor
        dialog.color = initialColor
        dialog.currentColor = initialColor
        dialog.open()
    }

    Kirigami.FormLayout {

        // === Section: Custom Font Color ===

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Font Color")
        }

        CheckBox {
            id: useCustomColorsCheck
            Kirigami.FormData.label: i18n("Use custom font color:")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Color:")
            enabled: cfg_useCustomColors
            spacing: Kirigami.Units.smallSpacing


            Button {
                id: fontColorButton
                text: ""
                padding: 0
                implicitWidth: Kirigami.Units.gridUnit * 2
                implicitHeight: Kirigami.Units.gridUnit * 1.5
                onClicked: colorsPage.openColorDialog(fontColorDialog, cfg_fontColor, Kirigami.Theme.textColor)

                background: Rectangle {
                    radius: 4
                    border.width: 1
                    border.color: fontColorButton.visualFocus ? Kirigami.Theme.highlightColor : Qt.rgba(1, 1, 1, 0.15)
                    color: "transparent"

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: 3
                        color: colorsPage.isRgbHex(cfg_fontColor) ? cfg_fontColor : Kirigami.Theme.textColor
                    }
                }
            }

            Platform.ColorDialog {
                id: fontColorDialog
                title: i18n("Choose Font Color")
                parentWindow: colorsPage.Window.window
                onAccepted: {
                    const hex = colorsPage.colorToRgbHex(color)
                    if (!hex) {
                        return
                    }

                    if (hex !== fontColorField.text) {
                        fontColorField.text = hex
                    }
                    cfg_fontColor = hex
                }
            }

            TextField {
                id: fontColorField
                placeholderText: "#ffffff"
                text: cfg_fontColor
                maximumLength: 7
                Layout.preferredWidth: 100
                onTextChanged: {
                    if (/^#[0-9A-Fa-f]{6}$/.test(text))
                        cfg_fontColor = text
                }
            }

            Button {
                text: i18n("Reset")
                icon.name: "edit-undo"
                onClicked: { fontColorField.text = ""; cfg_fontColor = "" }
            }
        }

        // === Section: Threshold Colors ===

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Threshold Colors")
        }

        CheckBox {
            id: enableThresholdCheck
            Kirigami.FormData.label: i18n("Enable threshold coloring:")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Warning color:")
            enabled: cfg_enableThresholdColors
            spacing: Kirigami.Units.smallSpacing


            Button {
                id: warningColorButton
                text: ""
                padding: 0
                implicitWidth: Kirigami.Units.gridUnit * 2
                implicitHeight: Kirigami.Units.gridUnit * 1.5
                onClicked: colorsPage.openColorDialog(warningColorDialog, cfg_warningColor, colorsPage.defaultWarningColor)

                background: Rectangle {
                    radius: 4
                    border.width: 1
                    border.color: warningColorButton.visualFocus ? Kirigami.Theme.highlightColor : Qt.rgba(1, 1, 1, 0.15)
                    color: "transparent"

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: 3
                        color: colorsPage.isRgbHex(cfg_warningColor) ? cfg_warningColor : colorsPage.defaultWarningColor
                    }
                }
            }

            Platform.ColorDialog {
                id: warningColorDialog
                title: i18n("Choose Warning Color")
                parentWindow: colorsPage.Window.window
                onAccepted: {
                    const hex = colorsPage.colorToRgbHex(color)
                    if (!hex) {
                        return
                    }

                    if (hex !== warningColorField.text) {
                        warningColorField.text = hex
                    }
                    cfg_warningColor = hex
                }
            }

            TextField {
                id: warningColorField
                text: cfg_warningColor
                maximumLength: 7
                Layout.preferredWidth: 100
                onTextChanged: {
                    if (/^#[0-9A-Fa-f]{6}$/.test(text))
                        cfg_warningColor = text
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Critical color:")
            enabled: cfg_enableThresholdColors
            spacing: Kirigami.Units.smallSpacing


            Button {
                id: criticalColorButton
                text: ""
                padding: 0
                implicitWidth: Kirigami.Units.gridUnit * 2
                implicitHeight: Kirigami.Units.gridUnit * 1.5
                onClicked: colorsPage.openColorDialog(criticalColorDialog, cfg_criticalColor, colorsPage.defaultCriticalColor)

                background: Rectangle {
                    radius: 4
                    border.width: 1
                    border.color: criticalColorButton.visualFocus ? Kirigami.Theme.highlightColor : Qt.rgba(1, 1, 1, 0.15)
                    color: "transparent"

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: 3
                        color: colorsPage.isRgbHex(cfg_criticalColor) ? cfg_criticalColor : colorsPage.defaultCriticalColor
                    }
                }
            }

            Platform.ColorDialog {
                id: criticalColorDialog
                title: i18n("Choose Critical Color")
                parentWindow: colorsPage.Window.window
                onAccepted: {
                    const hex = colorsPage.colorToRgbHex(color)
                    if (!hex) {
                        return
                    }

                    if (hex !== criticalColorField.text) {
                        criticalColorField.text = hex
                    }
                    cfg_criticalColor = hex
                }
            }

            TextField {
                id: criticalColorField
                text: cfg_criticalColor
                maximumLength: 7
                Layout.preferredWidth: 100
                onTextChanged: {
                    if (/^#[0-9A-Fa-f]{6}$/.test(text))
                        cfg_criticalColor = text
                }
            }
        }

        // === Section: Thresholds Grid ===

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Thresholds")
            visible: cfg_enableThresholdColors
        }

        GridLayout {
            visible: cfg_enableThresholdColors
            columns: 4
            columnSpacing: Kirigami.Units.largeSpacing
            rowSpacing: Kirigami.Units.smallSpacing
            Layout.fillWidth: true

            // --- Header ---
            Label { text: "" }
            Label { text: i18n("Warning"); font.bold: true; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true }
            Label { text: i18n("Critical"); font.bold: true; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true }
            Label { text: "" }

            // --- CPU Usage ---
            Label { text: i18n("CPU Usage") }
            RowLayout {
                Layout.fillWidth: true
                Slider { id: cpuWarnSlider; from: 10; to: 100; stepSize: 5; value: 70; Layout.fillWidth: true }
                Label { text: Math.round(cpuWarnSlider.value) + "%"; Layout.preferredWidth: 40 }
            }
            RowLayout {
                Layout.fillWidth: true
                Slider { id: cpuCritSlider; from: 10; to: 100; stepSize: 5; value: 90; Layout.fillWidth: true }
                Label { text: Math.round(cpuCritSlider.value) + "%"; Layout.preferredWidth: 40 }
            }
            Rectangle { Layout.preferredWidth: 10; Layout.preferredHeight: 10; radius: 5; color: cpuWarnSlider.value >= cpuCritSlider.value ? cfg_criticalColor : "transparent" }

            // --- CPU Temperature ---
            Label { text: i18n("CPU Temp") }
            RowLayout {
                Layout.fillWidth: true
                Slider { id: tempWarnSlider; from: 30; to: 110; stepSize: 5; value: 60; Layout.fillWidth: true }
                Label { text: Math.round(tempWarnSlider.value) + "°C"; Layout.preferredWidth: 40 }
            }
            RowLayout {
                Layout.fillWidth: true
                Slider { id: tempCritSlider; from: 30; to: 110; stepSize: 5; value: 85; Layout.fillWidth: true }
                Label { text: Math.round(tempCritSlider.value) + "°C"; Layout.preferredWidth: 40 }
            }
            Rectangle { Layout.preferredWidth: 10; Layout.preferredHeight: 10; radius: 5; color: tempWarnSlider.value >= tempCritSlider.value ? cfg_criticalColor : "transparent" }

            // --- RAM Usage ---
            Label { text: i18n("RAM Usage") }
            RowLayout {
                Layout.fillWidth: true
                Slider { id: ramWarnSlider; from: 10; to: 100; stepSize: 5; value: 70; Layout.fillWidth: true }
                Label { text: Math.round(ramWarnSlider.value) + "%"; Layout.preferredWidth: 40 }
            }
            RowLayout {
                Layout.fillWidth: true
                Slider { id: ramCritSlider; from: 10; to: 100; stepSize: 5; value: 90; Layout.fillWidth: true }
                Label { text: Math.round(ramCritSlider.value) + "%"; Layout.preferredWidth: 40 }
            }
            Rectangle { Layout.preferredWidth: 10; Layout.preferredHeight: 10; radius: 5; color: ramWarnSlider.value >= ramCritSlider.value ? cfg_criticalColor : "transparent" }

            // --- GPU Usage ---
            Label { text: i18n("GPU Usage") }
            RowLayout {
                Layout.fillWidth: true
                Slider { id: gpuWarnSlider; from: 10; to: 100; stepSize: 5; value: 70; Layout.fillWidth: true }
                Label { text: Math.round(gpuWarnSlider.value) + "%"; Layout.preferredWidth: 40 }
            }
            RowLayout {
                Layout.fillWidth: true
                Slider { id: gpuCritSlider; from: 10; to: 100; stepSize: 5; value: 90; Layout.fillWidth: true }
                Label { text: Math.round(gpuCritSlider.value) + "%"; Layout.preferredWidth: 40 }
            }
            Rectangle { Layout.preferredWidth: 10; Layout.preferredHeight: 10; radius: 5; color: gpuWarnSlider.value >= gpuCritSlider.value ? cfg_criticalColor : "transparent" }

            // --- GPU Temperature ---
            Label { text: i18n("GPU Temp") }
            RowLayout {
                Layout.fillWidth: true
                Slider { id: gpuTempWarnSlider; from: 30; to: 110; stepSize: 5; value: 60; Layout.fillWidth: true }
                Label { text: Math.round(gpuTempWarnSlider.value) + "°C"; Layout.preferredWidth: 40 }
            }
            RowLayout {
                Layout.fillWidth: true
                Slider { id: gpuTempCritSlider; from: 30; to: 110; stepSize: 5; value: 85; Layout.fillWidth: true }
                Label { text: Math.round(gpuTempCritSlider.value) + "°C"; Layout.preferredWidth: 40 }
            }
            Rectangle { Layout.preferredWidth: 10; Layout.preferredHeight: 10; radius: 5; color: gpuTempWarnSlider.value >= gpuTempCritSlider.value ? cfg_criticalColor : "transparent" }

            // --- Battery (inverted) ---
            Label { text: i18n("Battery ↓") }
            RowLayout {
                Layout.fillWidth: true
                Slider { id: batWarnSlider; from: 5; to: 60; stepSize: 5; value: 30; Layout.fillWidth: true }
                Label { text: Math.round(batWarnSlider.value) + "%"; Layout.preferredWidth: 40 }
            }
            RowLayout {
                Layout.fillWidth: true
                Slider { id: batCritSlider; from: 5; to: 60; stepSize: 5; value: 15; Layout.fillWidth: true }
                Label { text: Math.round(batCritSlider.value) + "%"; Layout.preferredWidth: 40 }
            }
            Rectangle { Layout.preferredWidth: 10; Layout.preferredHeight: 10; radius: 5; color: batWarnSlider.value <= batCritSlider.value ? cfg_criticalColor : "transparent" }
        }

        Label {
            visible: cfg_enableThresholdColors
            text: i18n("Battery uses inverted thresholds — warning/critical trigger below the set values.\nA red dot means warning ≥ critical (invalid config).")
            opacity: 0.6
            font.italic: true
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // --- Reset ---

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
        }

        Button {
            icon.name: "edit-undo"
            text: i18n("Reset all to defaults")
            onClicked: {
                useCustomColorsCheck.checked = false
                fontColorField.text = ""
                cfg_fontColor = ""
                enableThresholdCheck.checked = false
                warningColorField.text = colorsPage.defaultWarningColor
                cfg_warningColor = colorsPage.defaultWarningColor
                criticalColorField.text = colorsPage.defaultCriticalColor
                cfg_criticalColor = colorsPage.defaultCriticalColor
                cpuWarnSlider.value = 70;  cpuCritSlider.value = 90
                tempWarnSlider.value = 60; tempCritSlider.value = 85
                ramWarnSlider.value = 70;  ramCritSlider.value = 90
                gpuWarnSlider.value = 70;  gpuCritSlider.value = 90
                gpuTempWarnSlider.value = 60; gpuTempCritSlider.value = 85
                batWarnSlider.value = 30;  batCritSlider.value = 15
            }
        }
    }
}
