import QtQuick
import org.kde.ksysguard.sensors as Sensors

Item {
    id: root

    property int updateInterval: 2000

    readonly property string ramValue: {
        if (ramUsedSensor.status !== Sensors.Sensor.Ready || ramTotalSensor.status !== Sensors.Sensor.Ready)
            return "...";
        return Utils.formatBytes(ramUsedSensor.value) + "/" + Utils.formatBytes(ramTotalSensor.value) + "G";
    }

    Sensors.Sensor {
        id: ramUsedSensor
        sensorId: "memory/physical/used"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: ramTotalSensor
        sensorId: "memory/physical/total"
        updateRateLimit: root.updateInterval
    }
}
