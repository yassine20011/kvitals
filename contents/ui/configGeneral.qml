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
    property alias cfg_labelOpacity: labelOpacitySlider.value
    property alias cfg_separatorOpacity: separatorOpacitySlider.value
    property string cfg_displayMode: "text"
    property string cfg_fontFamily: "monospace"
    property string cfg_layoutType: "horizontal"
    property string cfg_tempUnit: "C"
    property string cfg_networkUnit: "bytes"
    property string cfg_fanUnit: "rpm"

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

        RowLayout {
            id: fontRow
            Kirigami.FormData.label: i18n("Font:")

            property var allFonts: []
            property var installedDefaults: []

            readonly property var candidateFonts: [
                "monospace", "Sans Serif", "Hack", "Fira Code",
                "JetBrains Mono", "Noto Sans", "Roboto", "Inter",
                "DejaVu Sans Mono", "Liberation Mono"
            ]

            function ensureFontsLoaded() {
                if (allFonts.length === 0) {
                    allFonts = Qt.fontFamilies();
                    var installed = [];
                    for (var i = 0; i < candidateFonts.length; i++) {
                        if (allFonts.indexOf(candidateFonts[i]) !== -1) {
                            installed.push(candidateFonts[i]);
                        }
                    }
                    installedDefaults = installed;
                }
            }

            function buildInitialList() {
                ensureFontsLoaded();
                var list = installedDefaults.slice();
                if (cfg_fontFamily && list.indexOf(cfg_fontFamily) === -1) {
                    list.unshift(cfg_fontFamily);
                }
                return list;
            }

            function filterFonts(query) {
                ensureFontsLoaded();
                var q = query.trim().toLowerCase();
                if (q === "") return buildInitialList();
                var results = [];
                for (var i = 0; i < allFonts.length && results.length < 50; i++) {
                    if (allFonts[i].toLowerCase().indexOf(q) !== -1) {
                        results.push(allFonts[i]);
                    }
                }
                return results;
            }

            function populateList(query) {
                fontSuggestionsModel.clear();
                var filtered = filterFonts(query);
                for (var i = 0; i < filtered.length; i++) {
                    fontSuggestionsModel.append({ name: filtered[i] });
                }
            }

            TextField {
                id: fontInput
                Layout.preferredWidth: 200
                text: cfg_fontFamily
                placeholderText: i18n("Type to search fonts...")

                onTextEdited: {
                    fontRow.populateList(text);
                    fontPopup.open();
                }

                onEditingFinished: {
                    if (!fontSuggestionsList.activeFocus) {
                        cfg_fontFamily = text;
                        fontPopup.close();
                    }
                }

                Keys.onEscapePressed: {
                    fontPopup.close();
                }
                Keys.onDownPressed: {
                    fontRow.populateList(text);
                    fontPopup.open();
                    fontSuggestionsList.currentIndex = -1;
                    fontSuggestionsList.forceActiveFocus();
                }
            }

            Popup {
                id: fontPopup
                parent: fontInput
                x: 0
                y: fontInput.height
                width: fontInput.width
                height: Math.min(fontSuggestionsList.contentHeight, 250)
                padding: 0
                closePolicy: Popup.CloseOnPressOutside

                ListView {
                    id: fontSuggestionsList
                    anchors.fill: parent
                    clip: true
                    model: ListModel { id: fontSuggestionsModel }

                    delegate: ItemDelegate {
                        width: fontSuggestionsList.width
                        text: model.name
                        highlighted: fontSuggestionsList.currentIndex === index
                        onClicked: {
                            cfg_fontFamily = model.name;
                            fontInput.text = model.name;
                            fontPopup.close();
                            fontInput.forceActiveFocus();
                        }
                    }

                    Keys.onReturnPressed: {
                        if (currentIndex >= 0) {
                            var item = fontSuggestionsModel.get(currentIndex);
                            cfg_fontFamily = item.name;
                            fontInput.text = item.name;
                        }
                        fontPopup.close();
                        fontInput.forceActiveFocus();
                    }

                    Keys.onEscapePressed: {
                        fontPopup.close();
                        fontInput.forceActiveFocus();
                    }
                }
            }
        }



        Label {
            text: i18n("Type to search, ↓ to browse, Enter or click to select")
            opacity: 0.6
            font.pointSize: fontSizeSlider.value > 0 ? fontSizeSlider.value * 0.8 : -1
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
            id: labelOpacitySlider
            Kirigami.FormData.label: i18n("Label opacity:")
            from: 0
            to: 1
            stepSize: 0.05
            value: 0.65
        }

        Label {
            text: Math.round(labelOpacitySlider.value * 100) + "%"
            opacity: 0.7
        }

        Slider {
            id: separatorOpacitySlider
            Kirigami.FormData.label: i18n("Separator opacity:")
            from: 0
            to: 1
            stepSize: 0.05
            value: 0.4
        }

        Label {
            text: Math.round(separatorOpacitySlider.value * 100) + "%"
            opacity: 0.7
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

        ComboBox {
            id: fanUnitCombo
            Kirigami.FormData.label: i18n("Fan Speed unit:")
            model: [i18n("RPM"), i18n("Percentage (%)")]
            currentIndex: cfg_fanUnit === "percent" ? 1 : 0
            onActivated: cfg_fanUnit = (currentIndex === 1 ? "percent" : "rpm")
        }
    }
}
