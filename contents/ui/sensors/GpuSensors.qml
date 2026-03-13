import QtQuick
import org.kde.ksysguard.sensors as Sensors

Item {
    id: root

    property int updateInterval: 2000

    readonly property real gpuUsageNumber: {
        var aggregateUsage = Utils.firstReadyNumber([gpuUsageAllSensor], false);
        if (!isNaN(aggregateUsage))
            return aggregateUsage;
        return Utils.maxReadyNumber([gpuUsage0Sensor, gpuUsage1Sensor, gpuUsage2Sensor, gpuUsage3Sensor], false);
    }

    readonly property var gpuVramPair: {
        return Utils.firstReadyVramPair([
            { used: gpuVramUsedAllSensor, total: gpuVramTotalAllSensor },
            { used: gpuVramUsedLegacySensor, total: gpuVramTotalLegacySensor },
            { used: gpuVramUsed0Sensor, total: gpuVramTotal0Sensor },
            { used: gpuVramUsed1Sensor, total: gpuVramTotal1Sensor },
            { used: gpuVramUsed2Sensor, total: gpuVramTotal2Sensor },
            { used: gpuVramUsed3Sensor, total: gpuVramTotal3Sensor }
        ]);
    }

    readonly property real gpuTempNumber: {
        var aggregateTemp = Utils.firstReadyNumber([gpuTempAllSensor], true);
        if (!isNaN(aggregateTemp))
            return aggregateTemp;
        return Utils.maxReadyNumber([gpuTemp0Sensor, gpuTemp1Sensor, gpuTemp2Sensor, gpuTemp3Sensor], true);
    }

    readonly property string gpuValue: {
        if (isNaN(gpuUsageNumber))
            return "";
        return Math.round(gpuUsageNumber) + "%";
    }

    readonly property string gpuRamValue: {
        if (!gpuVramPair)
            return "";
        return Utils.formatBytes(gpuVramPair.used) + "/" + Utils.formatBytes(gpuVramPair.total) + "G";
    }

    readonly property string gpuTempValue: {
        if (isNaN(gpuTempNumber))
            return "";
        return Math.round(gpuTempNumber) + "°C";
    }

    readonly property string gpuDisplayValue: {
        var parts = [];
        if (gpuValue)
            parts.push(gpuValue);
        if (gpuRamValue)
            parts.push(gpuRamValue);
        if (gpuTempValue)
            parts.push(gpuTempValue);
        return parts.join(" ");
    }

    readonly property bool hasGpuData: gpuDisplayValue.length > 0
    readonly property bool hasGpuUsageData: gpuValue.length > 0
    readonly property bool hasGpuVramData: gpuRamValue.length > 0
    readonly property bool hasGpuTempData: gpuTempValue.length > 0

    // --- Usage sensors ---

    Sensors.Sensor {
        id: gpuUsageAllSensor
        sensorId: "gpu/all/usage"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuUsage0Sensor
        sensorId: "gpu/gpu0/usage"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuUsage1Sensor
        sensorId: "gpu/gpu1/usage"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuUsage2Sensor
        sensorId: "gpu/gpu2/usage"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuUsage3Sensor
        sensorId: "gpu/gpu3/usage"
        updateRateLimit: root.updateInterval
    }

    // --- VRAM sensors ---

    Sensors.Sensor {
        id: gpuVramUsedAllSensor
        sensorId: "gpu/all/usedVram"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuVramTotalAllSensor
        sensorId: "gpu/all/totalVram"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuVramUsedLegacySensor
        sensorId: "gpu/all/memory/used"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuVramTotalLegacySensor
        sensorId: "gpu/all/memory/total"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuVramUsed0Sensor
        sensorId: "gpu/gpu0/usedVram"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuVramTotal0Sensor
        sensorId: "gpu/gpu0/totalVram"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuVramUsed1Sensor
        sensorId: "gpu/gpu1/usedVram"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuVramTotal1Sensor
        sensorId: "gpu/gpu1/totalVram"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuVramUsed2Sensor
        sensorId: "gpu/gpu2/usedVram"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuVramTotal2Sensor
        sensorId: "gpu/gpu2/totalVram"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuVramUsed3Sensor
        sensorId: "gpu/gpu3/usedVram"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuVramTotal3Sensor
        sensorId: "gpu/gpu3/totalVram"
        updateRateLimit: root.updateInterval
    }

    // --- Temperature sensors ---

    Sensors.Sensor {
        id: gpuTempAllSensor
        sensorId: "gpu/all/temperature"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuTemp0Sensor
        sensorId: "gpu/gpu0/temperature"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuTemp1Sensor
        sensorId: "gpu/gpu1/temperature"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuTemp2Sensor
        sensorId: "gpu/gpu2/temperature"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: gpuTemp3Sensor
        sensorId: "gpu/gpu3/temperature"
        updateRateLimit: root.updateInterval
    }
}
