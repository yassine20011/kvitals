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

    // Frequency in MHz from KSysGuard (unit type 302 = MHz); displays as GHz above 1000 MHz
    readonly property string cpuFreqValue: {
        if (freqSensor.status !== Sensors.Sensor.Ready || freqSensor.value == null)
            return "...";
        var mhz = freqSensor.value;
        if (mhz >= 1000)
            return (mhz / 1000).toFixed(2) + " GHz";
        return Math.round(mhz) + " MHz";
    }

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
}
