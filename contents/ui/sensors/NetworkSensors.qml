import QtQuick
import org.kde.ksysguard.sensors as Sensors

Item {
    id: root

    property int updateInterval: 2000
    property string networkInterface: "auto"

    readonly property string netIfacePath: {
        if (networkInterface === "" || networkInterface === "auto")
            return "all";
        return networkInterface;
    }

    readonly property string netDownValue: {
        if (netDownSensor.status !== Sensors.Sensor.Ready) return "...";
        return Utils.formatRate(netDownSensor.value);
    }

    readonly property string netUpValue: {
        if (netUpSensor.status !== Sensors.Sensor.Ready) return "...";
        return Utils.formatRate(netUpSensor.value);
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
}
