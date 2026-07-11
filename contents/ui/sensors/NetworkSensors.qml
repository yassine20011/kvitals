import QtQuick
import org.kde.ksysguard.sensors as Sensors

Item {
    id: root
    property bool _dbg: { console.warn("[KVitals] NetworkSensors: constructing..."); return true; }

    property int updateInterval: 2000
    property string networkInterface: "auto"
    property string networkUnit: "bytes"

    readonly property string netIfacePath: {
        if (networkInterface === "" || networkInterface === "auto")
            return "all";
        return networkInterface;
    }

    readonly property string netDownValue: {
        if (netDownSensor.status !== Sensors.Sensor.Ready) return "...";
        return Utils.formatRate(netDownSensor.value, networkUnit);
    }

    readonly property string netUpValue: {
        if (netUpSensor.status !== Sensors.Sensor.Ready) return "...";
        return Utils.formatRate(netUpSensor.value, networkUnit);
    }

    readonly property string netIpValue: {
        if (netIpSensor.status !== Sensors.Sensor.Ready) return "...";
        return netIpSensor.value;
    }

    Sensors.Sensor {
        id: netDownSensor
        sensorId: "network/" + root.netIfacePath + "/download"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: netUpSensor
        sensorId: "network/" + root.netIfacePath + "/upload"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: netIpSensor
        sensorId: "network/" + root.netIfacePath + "/ipv4address"
        updateRateLimit: root.updateInterval
    }

    Component.onCompleted: {
        console.warn("[KVitals] NetworkSensors: ready.");
    }
}
