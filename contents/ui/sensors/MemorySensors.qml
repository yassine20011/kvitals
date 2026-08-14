import QtQuick
import org.kde.ksysguard.sensors as Sensors

Item {
    id: root
    property bool _dbg: { console.warn("[KVitals] MemorySensors: constructing..."); return true; }

    property int updateInterval: 2000

    readonly property real ramPercentage: {
        if (ramUsedSensor.status !== Sensors.Sensor.Ready || ramTotalSensor.status !== Sensors.Sensor.Ready)
            return NaN;
        if (ramTotalSensor.value <= 0) return NaN;
        return (ramUsedSensor.value / ramTotalSensor.value) * 100;
    }

    readonly property string ramValue: {
        if (isNaN(ramPercentage))
            return "...";
        return Utils.formatBytes(ramUsedSensor.value) + "/" + Utils.formatBytes(ramTotalSensor.value) + "G";
    }

    readonly property string ramPercentValue: isNaN(ramPercentage) ? "..." : Math.round(ramPercentage).toString().padStart(3) + "%"

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

    Component.onCompleted: {
        console.warn("[KVitals] MemorySensors: ready.");
    }
}
