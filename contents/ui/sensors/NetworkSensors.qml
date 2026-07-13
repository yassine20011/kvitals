import QtQuick
import org.kde.ksysguard.sensors as Sensors
import org.kde.kitemmodels as KItemModels

Item {
    id: root
    property bool _dbg: { console.warn("[KVitals] NetworkSensors: constructing..."); return true; }

    property int updateInterval: 2000
    property string networkInterface: "auto"
    property string networkUnit: "bytes"

    // The resolved interface name to use for the IP sensor.
    // Empty string while still discovering (in auto mode).
    readonly property string netIpIfacePath: {
        if (networkInterface !== "" && networkInterface !== "auto")
            return networkInterface;
        return _activeIface;
    }

    // The path used for aggregate traffic sensors (download/upload).
    // "all" is valid for these even in auto mode.
    readonly property string netIfacePath: {
        if (networkInterface !== "" && networkInterface !== "auto")
            return networkInterface;
        return "all";
    }

    // Discovered via SensorTreeModel: first non-loopback interface with a
    // download sensor, used as the IP source when networkInterface is "auto".
    property string _activeIface: ""
    property var _discoveredIfaces: []

    // -------------------------------------------------------------------------
    // Interface discovery via SensorTreeModel (metadata only, no polling)
    // -------------------------------------------------------------------------

    Sensors.SensorTreeModel { id: sensorTree }

    KItemModels.KDescendantsProxyModel {
        id: flatSensors
        model: sensorTree
    }

    function _refreshInterfaces() {
        var found = [];
        for (var row = 0; row < flatSensors.rowCount(); row++) {
            var idx = flatSensors.index(row, 0);
            var sid = flatSensors.data(idx, Sensors.SensorTreeModel.SensorId);
            if (!sid) continue;
            // Match network/<iface>/download — skip "all" and loopback
            var match = sid.match(/^network\/([^/]+)\/download$/);
            if (!match) continue;
            var iface = match[1];
            if (iface === "all" || iface === "lo") continue;
            if (found.indexOf(iface) < 0) found.push(iface);
        }

        console.debug("[KVitals] NetworkSensors: discovered ifaces = " + JSON.stringify(found));
        if (JSON.stringify(found) !== JSON.stringify(_discoveredIfaces)) {
            _discoveredIfaces = found;
            // Pick the first discovered interface as the default for the IP sensor
            if (found.length > 0 && _activeIface === "")
                _activeIface = found[0];
        }
    }

    property bool _discoveryDirty: false

    Timer {
        id: discoveryTimer
        interval: 500
        repeat: false
        running: _discoveryDirty
        onTriggered: {
            _discoveryDirty = false;
            root._refreshInterfaces();
        }
    }

    Connections {
        target: flatSensors
        function onRowsInserted() { root._discoveryDirty = true; }
        function onRowsRemoved()  { root._discoveryDirty = true; }
        function onModelReset()   { root._discoveryDirty = true; }
    }

    Component.onCompleted: {
        console.warn("[KVitals] NetworkSensors: ready.");
        _refreshInterfaces();
    }

    // -------------------------------------------------------------------------
    // Traffic sensors (always use netIfacePath / "all" in auto mode)
    // -------------------------------------------------------------------------

    readonly property string netDownValue: {
        if (netDownSensor.status !== Sensors.Sensor.Ready) return "...";
        return Utils.formatRate(netDownSensor.value, networkUnit);
    }

    readonly property string netUpValue: {
        if (netUpSensor.status !== Sensors.Sensor.Ready) return "...";
        return Utils.formatRate(netUpSensor.value, networkUnit);
    }

    Sensors.Sensor {
        id: netDownSensor
        sensorId: "network/" + root.netIfacePath + "/download"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: netUpSensor
        sensorId: "network/" + root.netIfacePath + "/upload"
        updateRateLimit: root.updateInterval
    }

    // -------------------------------------------------------------------------
    // IP address sensor — only valid on a specific interface, never "all"
    // -------------------------------------------------------------------------

    readonly property string netIpValue: {
        if (netIpIfacePath === "") return "";
        if (netIpSensor.status !== Sensors.Sensor.Ready) return "...";
        // Strip CIDR prefix length (e.g. "192.168.1.10/24" → "192.168.1.10")
        var v = netIpSensor.value || "";
        var slash = v.indexOf("/");
        return slash >= 0 ? v.substring(0, slash) : v;
    }

    Sensors.Sensor {
        id: netIpSensor
        sensorId: root.netIpIfacePath !== "" ? "network/" + root.netIpIfacePath + "/ipv4withPrefixLength" : ""
        updateRateLimit: root.updateInterval
    }
}
