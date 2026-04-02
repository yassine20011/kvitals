import QtQuick
import org.kde.ksysguard.sensors as Sensors
import org.kde.plasma.plasma5support as Plasma5Support

Item {
    id: root

    property int updateInterval: 2000
    property string batteryDevice: "auto"

    readonly property real batNumericValue: {
        if (batChargeSensor.status !== Sensors.Sensor.Ready)
            return NaN;
        return batChargeSensor.value;
    }

    readonly property string batValue: {
        if (isNaN(batNumericValue)) return "";
        return Math.round(batNumericValue) + "%";
    }

    readonly property string powerValue: {
        if (batRateSensor.status !== Sensors.Sensor.Ready) return "";
        var watts = Math.abs(batRateSensor.value);
        if (watts < 0.01) return "0.0W";
        var sign = batRateSensor.value > 0 ? "+" : "-";
        return sign + watts.toFixed(1) + "W";
    }

    // --- Dynamic battery sensor discovery ---

    property string discoveredBatId: ""

    property string batChargeSensorId: {
        var base = (batteryDevice && batteryDevice !== "auto") ? batteryDevice : discoveredBatId;
        return base ? ("power/" + base + "/chargePercentage") : "";
    }

    property string batRateSensorId: {
        var base = (batteryDevice && batteryDevice !== "auto") ? batteryDevice : discoveredBatId;
        return base ? ("power/" + base + "/chargeRate") : "";
    }

    property var batteryCandidates: [
        "battery_BAT0",
        "battery_BAT1",
        "battery_BAT2",
        "battery_BATT",
        "battery_BATT0"
    ]
    property var stage1Probes: []

    Component.onCompleted: {
        if (batteryDevice && batteryDevice !== "auto")
            return;

        for (var i = 0; i < batteryCandidates.length; i++) {
            var pre = "power/" + batteryCandidates[i] + "/chargePercentage";
            var code = 'import org.kde.ksysguard.sensors as Sensors; Sensors.Sensor { sensorId: "' + pre + '"; updateRateLimit: 0 }';
            try {
                var probe = Qt.createQmlObject(code, root, "probe_" + i);
                stage1Probes.push({ candidate: batteryCandidates[i], probe: probe });
            } catch(e) {
            }
        }
    }

    Timer {
        id: stage1Timer
        interval: 500
        repeat: true
        running: (!batteryDevice || batteryDevice === "auto") && !discoveredBatId
        property int attempts: 0
        onTriggered: {
            attempts++;
            for (var i = 0; i < stage1Probes.length; i++) {
                if (stage1Probes[i].probe && stage1Probes[i].probe.status === Sensors.Sensor.Ready) {
                    persistDetectedBattery(stage1Probes[i].candidate);
                    running = false;
                    cleanupProbes();
                    return;
                }
            }
            if (attempts >= 6) { // 3 seconds timeout
                running = false;
                cleanupProbes();
                // Stage 2: qdbus fallback
                tryNextQdbus();
            }
        }
    }

    function cleanupProbes() {
        for (var i = 0; i < stage1Probes.length; i++) {
            if (stage1Probes[i].probe)
                stage1Probes[i].probe.destroy();
        }
        stage1Probes = [];
    }

    function persistDetectedBattery(deviceId) {
        discoveredBatId = deviceId;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration)
            Plasmoid.configuration.batteryDevice = deviceId;
    }

    function extractBatteryIds(stdout) {
        if (!stdout)
            return [];
        var matches = stdout.match(/power\/[^\/"\s]+\/chargePercentage/g);
        if (!matches)
            return [];

        var ids = [];
        for (var i = 0; i < matches.length; i++) {
            var parts = matches[i].split("/");
            if (parts.length < 3)
                continue;
            if (ids.indexOf(parts[1]) === -1)
                ids.push(parts[1]);
        }
        return ids;
    }

    // Stage 2: qdbus fallback
    property var qdbusVariants: ["qdbus", "qdbus6", "qdbus-qt6", "qdbus-qt5"]
    property int qdbusIndex: 0

    Plasma5Support.DataSource {
        id: qdbusDetector
        engine: "executable"
        property bool active: false

        onNewData: function(sourceName, data) {
            if (!active) return;
            active = false;
            disconnectSource(sourceName);

            if (data["exit code"] === 0) {
                var ids = extractBatteryIds(data["stdout"] ? data["stdout"].toString() : "");
                if (ids.length === 1) {
                    persistDetectedBattery(ids[0]);
                    return;
                }
                if (ids.length > 1) {
                    console.warn("BatterySensors: multiple batteries found:", JSON.stringify(ids), "— using first:", ids[0]);
                    persistDetectedBattery(ids[0]);
                    return;
                }
            }
            tryNextQdbus();
        }

        function run(variant) {
            var cmd = variant + " --literal org.kde.ksystemstats1" +
                      " /org/kde/ksystemstats1" +
                      " org.kde.ksystemstats1.allSensors";
            active = true;
            connectSource(cmd);
        }
    }

    function tryNextQdbus() {
        if (qdbusIndex >= qdbusVariants.length) {
            console.warn("BatterySensors: all detection methods exhausted; set batteryDevice manually in widget config");
            return;
        }
        var variant = qdbusVariants[qdbusIndex];
        qdbusIndex++;
        qdbusDetector.run(variant);
    }

    Sensors.Sensor {
        id: batChargeSensor
        sensorId: root.batChargeSensorId
        updateRateLimit: root.updateInterval > 5000 ? root.updateInterval : 5000
    }

    Sensors.Sensor {
        id: batRateSensor
        sensorId: root.batRateSensorId
        updateRateLimit: root.updateInterval > 5000 ? root.updateInterval : 5000
    }
}
