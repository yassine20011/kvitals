import QtQuick
import org.kde.ksysguard.sensors as Sensors

Item {
    id: root

    property int updateInterval: 2000

    readonly property real tempNumericValue: {
        if (tempSensor.status !== Sensors.Sensor.Ready)
            return NaN;
        return tempSensor.value;
    }

    readonly property string tempValue: {
        if (isNaN(tempNumericValue)) return "--";
        return Math.round(tempNumericValue) + "°C";
    }

    Sensors.Sensor {
        id: tempSensor
        sensorId: "cpu/all/averageTemperature"
        updateRateLimit: root.updateInterval
    }
}
