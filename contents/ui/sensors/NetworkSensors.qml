import QtQuick
import org.kde.ksysguard.sensors as Sensors
import org.kde.kitemmodels as KItemModels

Item {
    id: root
    property bool _dbg: { console.warn("[KVitals] NetworkSensors: constructing..."); return true; }

    property int updateInterval: 2000
    property string networkInterface: "auto"
    property string networkUnit: "bytes"

    // Resolved paths
    // Traffic sensors aggregate across all interfaces — "all" is valid here.
    readonly property string netIfacePath: {
        if (networkInterface !== "" && networkInterface !== "auto")
            return networkInterface;
        return "all";
    }

    // The IP sensor requires a concrete interface.
    // In auto mode this is _activeIface, kept fresh by _resolveActiveIface().
    readonly property string netIpIfacePath: {
        if (networkInterface !== "" && networkInterface !== "auto")
            return networkInterface;
        return _activeIface;
    }

    // Interface discovery — SensorTreeModel (metadata only, no polling)
    property string _activeIface: ""
    property var _discoveredIfaces: []

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
            var match = sid.match(/^network\/([^/]+)\/download$/);
            if (!match) continue;
            var iface = match[1];
            if (iface === "all" || iface === "lo") continue;
            if (found.indexOf(iface) < 0) found.push(iface);
        }
        console.debug("[KVitals] NetworkSensors: discovered ifaces = " + JSON.stringify(found));
        if (JSON.stringify(found) !== JSON.stringify(_discoveredIfaces))
            _discoveredIfaces = found;
    }

    property bool _discoveryDirty: false

    Timer {
        id: discoveryTimer
        interval: 500
        repeat: false
        running: _discoveryDirty
        onTriggered: { _discoveryDirty = false; root._refreshInterfaces(); }
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

    // Active interface selection — poll all discovered IPs, pick first with value
    // Sensor IDs for every discovered interface's IP — updated when the
    // discovered list changes.
    readonly property var _ipSensorIds: {
        return _discoveredIfaces.map(function(iface) {
            return "network/" + iface + "/ipv4withPrefixLength";
        });
    }

    // Poll IPs of all discovered interfaces at the same rate as traffic sensors.
    // Only active in auto mode — when a specific interface is chosen there is
    // nothing to resolve.
    Sensors.SensorDataModel {
        id: ipDiscoveryModel
        sensors: root._ipSensorIds
        updateRateLimit: root.updateInterval
        enabled: root._ipSensorIds.length > 0
                 && (root.networkInterface === "auto" || root.networkInterface === "")

        onDataChanged: root._resolveActiveIface()
        onReadyChanged: { if (ready) root._resolveActiveIface(); }
    }

    // Walk discovered interfaces in order; promote the first one that currently
    // holds a valid IP address.  Called on every sensor update, so the active
    // interface is always current — handles Wi-Fi ↔ Ethernet switches and
    // address loss transparently.
    function _resolveActiveIface() {
        for (var i = 0; i < _discoveredIfaces.length; i++) {
            var iface = _discoveredIfaces[i];
            var col = ipDiscoveryModel.column("network/" + iface + "/ipv4withPrefixLength");
            if (col < 0) continue;
            var val = ipDiscoveryModel.data(ipDiscoveryModel.index(0, col),
                                            Sensors.SensorDataModel.Value);
            if (val && typeof val === "string" && val.length > 0) {
                if (_activeIface !== iface) {
                    console.warn("[KVitals] NetworkSensors: active IP iface → " + iface + " (" + val + ")");
                    _activeIface = iface;
                }
                return;
            }
        }
        // No interface has an address — clear so the metric hides cleanly.
        if (_activeIface !== "") {
            console.warn("[KVitals] NetworkSensors: no active IP iface, clearing.");
            _activeIface = "";
        }
    }

    // Traffic sensors
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

    // IP address sensor

    readonly property string netIpValue: {
        if (netIpIfacePath === "") return "";
        if (netIpSensor.status !== Sensors.Sensor.Ready) return "...";
        // Strip CIDR suffix: "192.168.1.10/24" → "192.168.1.10"
        var v = netIpSensor.value || "";
        var slash = v.indexOf("/");
        return slash >= 0 ? v.substring(0, slash) : v;
    }

    Sensors.Sensor {
        id: netIpSensor
        sensorId: root.netIpIfacePath !== ""
                  ? "network/" + root.netIpIfacePath + "/ipv4withPrefixLength"
                  : ""
        updateRateLimit: root.updateInterval
    }
}
