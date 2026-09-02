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
        var pattern = MetricDefinitions.PATTERNS ? MetricDefinitions.PATTERNS.BATTERY : /^power\/((?!all)[^/]+)\/chargePercentage$/;
        var ids = discovery.queryIds(pattern);
        if (ids.length > 0) {
            var match = ids[0].match(pattern);
            if (match && match[1]) {
                discoveredBatId = match[1];
                return;
            }
        }
        if (discovery.discoveredBatteries && discovery.discoveredBatteries.length > 0) {
            discoveredBatId = discovery.discoveredBatteries[0];
            return;
        }
        discoveredBatId = "";
    }

    Connections {
        target: discovery
        function onRevisionChanged() { root.refreshDiscovered(); }
    }

    onDiscoveryChanged: refreshDiscovered()
    Component.onCompleted: refreshDiscovered()

    readonly property string _resolvedBase: {
        var _rev = discovery ? discovery.revision : 0;
        if (batteryDevice && batteryDevice !== "auto") {
            var dev = batteryDevice.trim();
            dev = dev.replace(/^power\//, "").replace(/\/.*$/, "");
            if (discovery && discovery.sensorExists) {
                if (discovery.sensorExists("power/" + dev + "/chargePercentage"))
                    return dev;
                if (discovery.sensorExists("power/battery_" + dev + "/chargePercentage"))
                    return "battery_" + dev;
                var stripped = dev.replace(/^battery_/, "");
                if (discovery.sensorExists("power/" + stripped + "/chargePercentage"))
                    return stripped;
                return "";
            }
            return "";
        }
        return discoveredBatId;
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
        if (!_resolvedBase || _resolvedBase.length === 0) return false;
        if (batChargeSensor.status === Sensors.Sensor.Ready && !isNaN(batNumericValue)) return true;
        if (discoveredBatId && discoveredBatId.length > 0) return true;
        if (batteryDevice && batteryDevice !== "auto") return true;
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
