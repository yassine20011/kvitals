import QtQuick
import org.kde.ksysguard.sensors as Sensors

Item {
    id: root

    property int updateInterval: 2000

    readonly property string tempValue: {
        if (tempSensor.status !== Sensors.Sensor.Ready) return "--";
        return Math.round(tempSensor.value) + "°C";
    }

    Sensors.Sensor {
        id: tempSensor
        sensorId: "cpu/all/averageTemperature"
        updateRateLimit: root.updateInterval
    }
}
