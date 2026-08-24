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
        return Math.round(cpuNumericValue).toString().padStart(3) + "%";
    }

    // Frequency in MHz from KSysGuard (unit type 302 = MHz); displays as GHz above 1000 MHz
    readonly property string cpuFreqValue: {
        if (freqSensor.status !== Sensors.Sensor.Ready || freqSensor.value == null)
            return "...";
        var mhz = freqSensor.value;
        if (mhz >= 1000)
            return (mhz / 1000).toFixed(2) + " GHz";
        return Math.round(mhz) + " MHz";
    }

    readonly property real cpuLoad1Raw: (load1Sensor.status === Sensors.Sensor.Ready && load1Sensor.value != null) ? Number(load1Sensor.value) : NaN
    readonly property real cpuLoad5Raw: (load5Sensor.status === Sensors.Sensor.Ready && load5Sensor.value != null) ? Number(load5Sensor.value) : NaN
    readonly property real cpuLoad15Raw: (load15Sensor.status === Sensors.Sensor.Ready && load15Sensor.value != null) ? Number(load15Sensor.value) : NaN

    readonly property string cpuLoad1Value: isNaN(cpuLoad1Raw) ? "..." : cpuLoad1Raw.toFixed(2)
    readonly property string cpuLoad5Value: isNaN(cpuLoad5Raw) ? "..." : cpuLoad5Raw.toFixed(2)
    readonly property string cpuLoad15Value: isNaN(cpuLoad15Raw) ? "..." : cpuLoad15Raw.toFixed(2)

    Sensors.Sensor {
        id: cpuSensor
        sensorId: "cpu/all/usage"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: freqSensor
        sensorId: "cpu/all/averageFrequency"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: load1Sensor
        sensorId: "cpu/loadaverages/loadaverage1"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: load5Sensor
        sensorId: "cpu/loadaverages/loadaverage5"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: load15Sensor
        sensorId: "cpu/loadaverages/loadaverage15"
        updateRateLimit: root.updateInterval
    }
}
