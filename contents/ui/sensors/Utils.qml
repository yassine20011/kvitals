pragma Singleton
import QtQuick
import org.kde.ksysguard.sensors as Sensors

QtObject {
    function formatBytes(bytes) {
        if (typeof bytes !== "number" || isNaN(bytes))
            return "...";
        var gb = bytes / (1024 * 1024 * 1024);
        return gb.toFixed(1);
    }

    // unit: "bytes" (default, KB/MB) or "bits" (Kb/Mb)
    // Suffix convention: uppercase B = bytes, lowercase b = bits
    function formatRate(bytesPerSec, unit) {
        if (typeof bytesPerSec !== "number" || isNaN(bytesPerSec))
            return "...";
        if (unit === "bits") {
            var bps = bytesPerSec * 8;
            if (bps >= 1000000)
                return (bps / 1000000).toFixed(1) + "Mb";
            return Math.max(0, bps / 1000).toFixed(1) + "Kb";
        }
        var kbps = bytesPerSec / 1024;
        if (kbps >= 1024)
            return (kbps / 1024).toFixed(1) + "MB";
        return Math.max(0, kbps).toFixed(1) + "KB";
    }

    // celsiusValue: raw °C number from sensor; unit: "C" or "F"
    function formatTemp(celsiusValue, unit) {
        if (typeof celsiusValue !== "number" || isNaN(celsiusValue))
            return "";
        if (unit === "F")
            return Math.round(celsiusValue * 9 / 5 + 32) + "°F";
        return Math.round(celsiusValue) + "°C";
    }

    function sensorValueOrNaN(sensor) {
        if (!sensor || sensor.status !== Sensors.Sensor.Ready)
            return NaN;
        if (typeof sensor.value !== "number" || isNaN(sensor.value))
            return NaN;
        return sensor.value;
    }

    function firstReadyNumber(sensors, requirePositive) {
        for (var i = 0; i < sensors.length; i++) {
            var value = sensorValueOrNaN(sensors[i]);
            if (isNaN(value))
                continue;
            if (requirePositive && value <= 0)
                continue;
            return value;
        }
        return NaN;
    }

    function maxReadyNumber(sensors, requirePositive) {
        var maxValue = NaN;
        for (var i = 0; i < sensors.length; i++) {
            var value = sensorValueOrNaN(sensors[i]);
            if (isNaN(value))
                continue;
            if (requirePositive && value <= 0)
                continue;
            if (isNaN(maxValue) || value > maxValue)
                maxValue = value;
        }
        return maxValue;
    }

    function firstReadyVramPair(pairs) {
        for (var i = 0; i < pairs.length; i++) {
            var used = sensorValueOrNaN(pairs[i].used);
            var total = sensorValueOrNaN(pairs[i].total);
            if (isNaN(used) || isNaN(total))
                continue;
            if (total <= 0 || used < 0)
                continue;
            return { used: used, total: total };
        }
        return null;
    }

    function resolveColor(numericValue, warningThreshold, criticalThreshold,
                          warningColor, criticalColor, baseColor, inverted) {
        if (isNaN(numericValue))
            return baseColor;
        if (inverted) {
            if (numericValue <= criticalThreshold) return criticalColor;
            if (numericValue <= warningThreshold)  return warningColor;
        } else {
            if (numericValue >= criticalThreshold) return criticalColor;
            if (numericValue >= warningThreshold)  return warningColor;
        }
        return baseColor;
    }
}
