import QtQuick
import org.kde.ksysguard.sensors as Sensors

Item {
    id: root

    property int updateInterval: 2000

    readonly property real cpuNumericValue: {
        if (cpuSensor.status !== Sensors.Sensor.Ready)
            return NaN;
        return cpuSensor.value;
    }

    readonly property string cpuValue: {
        if (isNaN(cpuNumericValue))
            return "...";
        return Math.round(cpuNumericValue) + "%";
    }

    Sensors.Sensor {
        id: cpuSensor
        sensorId: "cpu/all/usage"
        updateRateLimit: root.updateInterval
    }
}
