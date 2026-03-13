import QtQuick
import org.kde.ksysguard.sensors as Sensors

Item {
    id: root

    property int updateInterval: 2000

    readonly property string cpuValue: {
        if (cpuSensor.status !== Sensors.Sensor.Ready)
            return "...";
        return Math.round(cpuSensor.value) + "%";
    }

    Sensors.Sensor {
        id: cpuSensor
        sensorId: "cpu/all/usage"
        updateRateLimit: root.updateInterval
    }
}
