import QtQuick
import org.kde.ksysguard.sensors as Sensors
import "../models/MetricDefinitions.js" as MetricDefinitions

Item {
    id: root

    property var discovery: null
    property int updateInterval: 2000
    property string batteryDevice: "auto"

    property string discoveredBatId: ""

    function refreshDiscovered() {
        if (batteryDevice && batteryDevice !== "auto") return;
        if (!discovery) return;
        var pattern = MetricDefinitions.PATTERNS ? MetricDefinitions.PATTERNS.BATTERY : /^power\/((?:battery_)[a-zA-Z0-9_-]+|BAT\d+|BATT\d*)\/chargePercentage$/;
        var ids = discovery.queryIds(pattern);
        if (ids.length > 0) {
            var match = ids[0].match(pattern);
            if (match && match[1]) {
                discoveredBatId = match[1];
            }
        }
    }

    Connections {
        target: discovery
        function onRevisionChanged() { root.refreshDiscovered(); }
    }

    onDiscoveryChanged: refreshDiscovered()
    Component.onCompleted: refreshDiscovered()

    readonly property string _resolvedBase: {
        if (batteryDevice && batteryDevice !== "auto") {
            if (batteryDevice.startsWith("battery_") || batteryDevice.startsWith("power/"))
                return batteryDevice;
            return "battery_" + batteryDevice;
        }
        return discoveredBatId || "battery_BAT0";
    }

    readonly property string batChargeSensorId: _resolvedBase ? ("power/" + _resolvedBase + "/chargePercentage") : ""
    readonly property string batRateSensorId:   _resolvedBase ? ("power/" + _resolvedBase + "/chargeRate") : ""
    readonly property string batHealthSensorId: _resolvedBase ? ("power/" + _resolvedBase + "/health") : ""

    readonly property real   batNumericValue:  (batChargeSensor.status === Sensors.Sensor.Ready && batChargeSensor.value != null) ? Number(batChargeSensor.value) : NaN
    readonly property string batValue:         isNaN(batNumericValue) ? "" : Math.round(batNumericValue) + "%"

    readonly property real   batRateNumericValue: (batRateSensor.status === Sensors.Sensor.Ready && batRateSensor.value != null) ? Number(batRateSensor.value) : NaN
    readonly property string powerValue: {
        if (isNaN(batRateNumericValue)) return "";
        var watts = Math.abs(batRateNumericValue);
        if (watts < 0.01) return "0.0W";
        return (batRateNumericValue > 0 ? "+" : "-") + watts.toFixed(1) + "W";
    }

    readonly property real   batHealthNumericValue: (batHealthSensor.status === Sensors.Sensor.Ready && batHealthSensor.value != null) ? Number(batHealthSensor.value) : NaN
    readonly property string batHealthValue: isNaN(batHealthNumericValue) ? "" : Math.round(batHealthNumericValue) + "%"

    readonly property bool hasBattery: {
        if (batteryDevice && batteryDevice !== "auto") return true;
        if (discoveredBatId && discoveredBatId.length > 0) return true;
        if (batChargeSensor.status === Sensors.Sensor.Ready && !isNaN(batNumericValue)) return true;
        return false;
    }

    Sensors.Sensor {
        id: batChargeSensor
        sensorId: root.batChargeSensorId
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: batRateSensor
        sensorId: root.batRateSensorId
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: batHealthSensor
        sensorId: root.batHealthSensorId
        updateRateLimit: root.updateInterval
    }
}
