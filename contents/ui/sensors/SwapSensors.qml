import QtQuick
import org.kde.ksysguard.sensors as Sensors

Item {
    id: root

    property int updateInterval: 2000

    readonly property bool swapAvailable: {
        return swapTotalSensor.status === Sensors.Sensor.Ready && swapTotalSensor.value > 0;
    }

    readonly property real swapPercentage: {
        if (!swapAvailable || swapUsedSensor.status !== Sensors.Sensor.Ready)
            return NaN;
        return (swapUsedSensor.value / swapTotalSensor.value) * 100;
    }

    readonly property real swapUsedRaw: (swapUsedSensor.status === Sensors.Sensor.Ready) ? swapUsedSensor.value : NaN
    readonly property real swapFreeRaw: (swapFreeSensor.status === Sensors.Sensor.Ready) ? swapFreeSensor.value : NaN
    readonly property real swapTotalRaw: (swapTotalSensor.status === Sensors.Sensor.Ready) ? swapTotalSensor.value : NaN

    readonly property string swapPercentValue: isNaN(swapPercentage) ? "..." : Math.round(swapPercentage).toString().padStart(3) + "%"
    readonly property string swapUsedValue: isNaN(swapUsedRaw) ? "..." : Utils.formatBytes(swapUsedRaw) + "G"
    readonly property string swapFreeValue: isNaN(swapFreeRaw) ? "..." : Utils.formatBytes(swapFreeRaw) + "G"
    readonly property string swapTotalValue: isNaN(swapTotalRaw) ? "..." : Utils.formatBytes(swapTotalRaw) + "G"

    Sensors.Sensor {
        id: swapUsedSensor
        sensorId: "memory/swap/used"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: swapFreeSensor
        sensorId: "memory/swap/free"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: swapTotalSensor
        sensorId: "memory/swap/total"
        updateRateLimit: root.updateInterval
    }
}
