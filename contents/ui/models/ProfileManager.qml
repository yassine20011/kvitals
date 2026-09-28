import QtQuick
import org.kde.plasma.plasmoid

QtObject {
    id: root

    // Public API
    readonly property string activeProfileId: _activeProfileId
    readonly property string activeProfileName: _activeProfileName
    readonly property var profileSummaries: _profileSummaries  // [{id, name, createdAt}]
    readonly property QtObject activeConfig: _activeConfig

    // Internal state
    property string _activeProfileId: ""
    property string _activeProfileName: ""
    property var _profileSummaries: []
    property var _profiles: []
    property bool _syncing: false

    // Profile-system meta keys — excluded from profile data
    readonly property var _metaKeys: [
        "profileList", "activeProfileId", "migrationDone", "profileListVersion"
    ]

    // Schema defaults — mirrors main.xml <default> values
    readonly property var _defaults: ({
        pinnedMetrics:            "cpu/usage,ram/percentage,temp/system,bat/percentage,net/down,net/up",
        cpuEnabled:               true,
        cpuSubMetrics:            "usage,freq,temp",
        cpuVisibility:            "both",
        ramEnabled:               true,
        ramSubMetrics:            "percentage",
        ramWidgetShowBoth:        false,
        ramVisibility:            "both",
        swapEnabled:              false,
        swapSubMetrics:           "percent,used",
        swapVisibility:           "both",
        tempEnabled:              true,
        tempLabel:                "System",
        tempVisibility:           "both",
        gpuEnabled:               true,
        gpuSubMetrics:            "usage,vram,temp",
        gpuVisibility:            "both",
        batEnabled:               true,
        batSubMetrics:            "percentage,power",
        batVisibility:            "both",
        netEnabled:               true,
        netSubMetrics:            "down,up",
        netVisibility:            "both",
        diskEnabled:              false,
        diskSubMetrics:           "read,write",
        diskVisibility:           "both",
        fanEnabled:               false,
        fanVisibility:            "both",
        uptimeEnabled:            false,
        uptimeVisibility:         "both",
        cpuLabel:                 "CPU",
        ramLabel:                 "RAM",
        swapLabel:                "SWAP",
        diskLabel:                "DSK",
        diskLabels:               "",
        netLabel:                 "NET",
        networkInterface:         "auto",
        showNetworkIp:            false,
        batteryDevice:            "auto",
        batLabel:                 "BAT",
        gpuSelection:             "",
        gpuLabels:                "",
        fanLabel:                 "FAN",
        fanLabels:                "",
        displayMode:              "icons",
        layoutType:               "horizontal",
        iconSize:                 12,
        mergeFamilyMetrics:       true,
        showSeparators:           true,
        backgroundType:           "default",
        cpuIcon:                  "cpu-symbolic",
        ramIcon:                  "memory-symbolic",
        swapIcon:                 "memory-symbolic",
        tempIcon:                 "temperature-symbolic",
        gpuIcon:                  "gpu-symbolic",
        batteryIcon:              "battery-symbolic",
        powerIcon:                "voltage-symbolic",
        networkIcon:              "network-symbolic",
        diskIcon:                 "storage-symbolic",
        fanIcon:                  "fan-symbolic",
        uptimeIcon:               "system-symbolic",
        fontFamily:               "monospace",
        fontSize:                 0,
        fontBold:                 false,
        metricOrder:              "cpu,ram,swap,temp,gpu,bat,net,disk,fan,uptime",
        updateInterval:           2000,
        useCustomColors:          false,
        iconColor:                "",
        labelColor:               "",
        fontColor:                "",
        enableThresholdColors:    false,
        warningColor:             "#e5a50a",
        criticalColor:            "#da4453",
        cpuWarningThreshold:      70,
        cpuCriticalThreshold:     90,
        tempWarningThreshold:     60,
        tempCriticalThreshold:    85,
        systemWarningThreshold:   60,
        systemCriticalThreshold:  85,
        ramWarningThreshold:      70,
        ramCriticalThreshold:     90,
        swapWarningThreshold:     70,
        swapCriticalThreshold:    90,
        ramTempWarningThreshold:  60,
        ramTempCriticalThreshold: 85,
        gpuWarningThreshold:      70,
        gpuCriticalThreshold:     90,
        gpuTempWarningThreshold:  60,
        gpuTempCriticalThreshold: 85,
        batteryWarningThreshold:  30,
        batteryCriticalThreshold: 15,
        diskWarningThreshold:     80,
        diskCriticalThreshold:    90,
        diskTempWarningThreshold: 45,
        diskTempCriticalThreshold: 60,
        tempUnit:                 "C",
        networkUnit:              "bytes",
        fanUnit:                  "rpm",
        fanMaxRpm:                2000,
        labelOpacity:             0.65,
        separatorOpacity:         0.4
    })

    // Live config object that MetricConfig.target binds to.
    // Same object instance always — properties are reassigned on profile switch.
    property QtObject _activeConfig: QtObject {
        property string pinnedMetrics:            "cpu/usage,ram/percentage,temp/system,bat/percentage,net/down,net/up"
        property bool   cpuEnabled:               true
        property string cpuSubMetrics:            "usage,freq,temp"
        property string cpuVisibility:            "both"
        property bool   ramEnabled:               true
        property string ramSubMetrics:            "percentage"
        property bool   ramWidgetShowBoth:        false
        property string ramVisibility:            "both"
        property bool   swapEnabled:              false
        property string swapSubMetrics:           "percent,used"
        property string swapVisibility:           "both"
        property bool   tempEnabled:              true
        property string tempLabel:                "System"
        property string tempVisibility:           "both"
        property bool   gpuEnabled:               true
        property string gpuSubMetrics:            "usage,vram,temp"
        property string gpuVisibility:            "both"
        property bool   batEnabled:               true
        property string batSubMetrics:            "percentage,power"
        property string batVisibility:            "both"
        property bool   netEnabled:               true
        property string netSubMetrics:            "down,up"
        property string netVisibility:            "both"
        property bool   diskEnabled:              false
        property string diskSubMetrics:           "read,write"
        property string diskVisibility:           "both"
        property bool   fanEnabled:               false
        property string fanVisibility:            "both"
        property bool   uptimeEnabled:            false
        property string uptimeVisibility:         "both"
        property string cpuLabel:                 "CPU"
        property string ramLabel:                 "RAM"
        property string swapLabel:                "SWAP"
        property string diskLabel:                "DSK"
        property string diskLabels:               ""
        property string netLabel:                 "NET"
        property string networkInterface:         "auto"
        property bool   showNetworkIp:            false
        property string batteryDevice:            "auto"
        property string batLabel:                 "BAT"
        property string gpuSelection:             ""
        property string gpuLabels:                ""
        property string fanLabel:                 "FAN"
        property string fanLabels:                ""
        property string displayMode:              "icons"
        property string layoutType:               "horizontal"
        property int    iconSize:                 12
        property bool   mergeFamilyMetrics:       true
        property bool   showSeparators:           true
        property string backgroundType:           "default"
        property string cpuIcon:                  "cpu-symbolic"
        property string ramIcon:                  "memory-symbolic"
        property string swapIcon:                 "memory-symbolic"
        property string tempIcon:                 "temperature-symbolic"
        property string gpuIcon:                  "gpu-symbolic"
        property string batteryIcon:              "battery-symbolic"
        property string powerIcon:                "voltage-symbolic"
        property string networkIcon:              "network-symbolic"
        property string diskIcon:                 "storage-symbolic"
        property string fanIcon:                  "fan-symbolic"
        property string uptimeIcon:               "system-symbolic"
        property string fontFamily:               "monospace"
        property int    fontSize:                 0
        property bool   fontBold:                 false
        property string metricOrder:              "cpu,ram,swap,temp,gpu,bat,net,disk,fan,uptime"
        property int    updateInterval:           2000
        property bool   useCustomColors:          false
        property string iconColor:                ""
        property string labelColor:               ""
        property string fontColor:                ""
        property bool   enableThresholdColors:    false
        property string warningColor:             "#e5a50a"
        property string criticalColor:            "#da4453"
        property int    cpuWarningThreshold:      70
        property int    cpuCriticalThreshold:     90
        property int    tempWarningThreshold:     60
        property int    tempCriticalThreshold:    85
        property int    systemWarningThreshold:   60
        property int    systemCriticalThreshold:  85
        property int    ramWarningThreshold:      70
        property int    ramCriticalThreshold:     90
        property int    swapWarningThreshold:     70
        property int    swapCriticalThreshold:    90
        property int    ramTempWarningThreshold:  60
        property int    ramTempCriticalThreshold: 85
        property int    gpuWarningThreshold:      70
        property int    gpuCriticalThreshold:     90
        property int    gpuTempWarningThreshold:  60
        property int    gpuTempCriticalThreshold: 85
        property int    batteryWarningThreshold:  30
        property int    batteryCriticalThreshold: 15
        property int    diskWarningThreshold:     80
        property int    diskCriticalThreshold:    90
        property int    diskTempWarningThreshold: 45
        property int    diskTempCriticalThreshold: 60
        property string tempUnit:                 "C"
        property string networkUnit:              "bytes"
        property string fanUnit:                  "rpm"
        property int    fanMaxRpm:                2000
        property real   labelOpacity:             0.65
        property real   separatorOpacity:         0.4
    }

    // Intercept Apply/OK writes from the KCM config dialog.
    // Verified from AppletConfiguration.qml (installed Plasma 6):
    //   Apply/OK: saveConfig() writes cfg_* -> Plasmoid.configuration, fires valueChanged per key
    //   Cancel:   calls closing() -> configDialog.close() with NO write to Plasmoid.configuration
    // So this handler only fires for actual committed saves, not cancels.
    Connections {
        target: Plasmoid.configuration
        function onValueChanged(key, value) {
            if (root._syncing) return;
            if (root._metaKeys.indexOf(key) !== -1) return;
            var profile = root._findProfile(root._activeProfileId);
            if (!profile) return;
            profile.data[key] = value;
            _activeConfig[key] = value;
            root._flush();
        }
    }

    Component.onCompleted: _init()

    // --- Private implementation ---

    function _init() {
        var raw = Plasmoid.configuration.profileList;
        if (!raw || raw === "" || !Plasmoid.configuration.migrationDone) {
            _migrate();
        } else {
            _loadFromRaw(raw);
        }
    }

    function _migrate() {
        // Snapshot every current value from Plasmoid.configuration.
        // Existing user config becomes the "Default" profile unchanged.
        var snap = {};
        var defs = _defaults;
        for (var key in defs) {
            var val = Plasmoid.configuration[key];
            snap[key] = (val !== undefined) ? val : defs[key];
        }
        var id = _uuid();
        var profile = { id: id, name: "Default", createdAt: Date.now(), data: snap };
        _profiles = [profile];
        _syncing = true;
        Plasmoid.configuration.profileListVersion = 1;
        Plasmoid.configuration.migrationDone = true;
        _flush();
        _activateProfileInternal(id);
        _syncing = false;
        _rebuildSummaries();
    }

    function _loadFromRaw(raw) {
        try {
            var parsed = JSON.parse(raw);
            if (!parsed || !Array.isArray(parsed.profiles) || parsed.profiles.length === 0) {
                _migrate();
                return;
            }
            _profiles = parsed.profiles;
        } catch (e) {
            console.warn("KVitals ProfileManager: corrupted profileList, resetting:", e);
            _migrate();
            return;
        }
        var savedId = Plasmoid.configuration.activeProfileId;
        var found = _findProfile(savedId);
        var targetId = found ? savedId : _profiles[0].id;
        _syncing = true;
        _activateProfileInternal(targetId);
        _syncing = false;
        _rebuildSummaries();
    }

    function _flush() {
        Plasmoid.configuration.profileList = JSON.stringify({ version: 1, profiles: _profiles });
    }

    function _activateProfileInternal(id) {
        var profile = _findProfile(id);
        if (!profile) return;
        var data = profile.data;
        var defs = _defaults;
        // Write profile values into Plasmoid.configuration flat keys so KCM
        // pages read the correct profile values when the config dialog opens.
        // Also populate _activeConfig for live MetricConfig reactive bindings.
        for (var key in defs) {
            var val = (data[key] !== undefined) ? data[key] : defs[key];
            Plasmoid.configuration[key] = val;
            _activeConfig[key] = val;
        }
        Plasmoid.configuration.activeProfileId = id;
        _activeProfileId = id;
        _activeProfileName = profile.name;
    }

    function _rebuildSummaries() {
        var result = [];
        for (var i = 0; i < _profiles.length; i++) {
            result.push({
                id: _profiles[i].id,
                name: _profiles[i].name,
                createdAt: _profiles[i].createdAt
            });
        }
        _profileSummaries = result;
    }

    function _findProfile(id) {
        for (var i = 0; i < _profiles.length; i++) {
            if (_profiles[i].id === id) return _profiles[i];
        }
        return null;
    }

    function _uuid() {
        var d = new Date().getTime();
        return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function(c) {
            var r = (d + Math.random() * 16) % 16 | 0;
            d = Math.floor(d / 16);
            return (c === "x" ? r : (r & 0x3 | 0x8)).toString(16);
        });
    }

    // --- Public CRUD ---

    function activateProfile(id) {
        if (id === _activeProfileId) return;
        _syncing = true;
        _activateProfileInternal(id);
        _flush();
        _syncing = false;
        _rebuildSummaries();
    }

    function createProfile(name) {
        var id = _uuid();
        var data = {};
        for (var key in _defaults) {
            data[key] = _defaults[key];
        }
        _profiles.push({ id: id, name: name, createdAt: Date.now(), data: data });
        _flush();
        _rebuildSummaries();
        return id;
    }

    function duplicateProfile(sourceId, newName) {
        var source = _findProfile(sourceId);
        if (!source) return "";
        var id = _uuid();
        var data = JSON.parse(JSON.stringify(source.data));
        _profiles.push({ id: id, name: newName, createdAt: Date.now(), data: data });
        _flush();
        _rebuildSummaries();
        return id;
    }

    function renameProfile(id, newName) {
        var profile = _findProfile(id);
        if (!profile) return;
        profile.name = newName;
        if (id === _activeProfileId) _activeProfileName = newName;
        _flush();
        _rebuildSummaries();
    }

    function deleteProfile(id) {
        if (_profiles.length <= 1) return;
        var idx = -1;
        for (var i = 0; i < _profiles.length; i++) {
            if (_profiles[i].id === id) { idx = i; break; }
        }
        if (idx === -1) return;
        _profiles.splice(idx, 1);
        if (id === _activeProfileId) {
            _syncing = true;
            _activateProfileInternal(_profiles[0].id);
            _syncing = false;
        }
        _flush();
        _rebuildSummaries();
    }
}
