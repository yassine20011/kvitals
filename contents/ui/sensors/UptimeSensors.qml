import QtQuick
import org.kde.ksysguard.sensors as Sensors

Item {
    id: root
    property bool _dbg: { console.warn("[KVitals] UptimeSensors: constructing..."); return true; }

    property int updateInterval: 2000

    readonly property string uptimeValue: {
        if (uptimeSensor.status !== Sensors.Sensor.Ready) return "...";
        return formatUptime(uptimeSensor.value);
    }

    function formatUptime(seconds) {
        if (isNaN(seconds)) return "...";
        var d = Math.floor(seconds / 86400);
        var h = Math.floor((seconds % 86400) / 3600);
        var m = Math.floor((seconds % 3600) / 60);
        
        var parts = [];
        if (d > 0) parts.push(d + "d");
        if (h > 0 || d > 0) parts.push(h + "h");
        parts.push(m + "m");
        return parts.join(" ");
    }

    Sensors.Sensor {
        id: uptimeSensor
        sensorId: "os/system/uptime"
        updateRateLimit: root.updateInterval
    }

    Component.onCompleted: {
        console.warn("[KVitals] UptimeSensors: ready.");
    }
}
