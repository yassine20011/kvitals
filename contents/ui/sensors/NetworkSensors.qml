import QtQuick
import org.kde.ksysguard.sensors as Sensors
import "../models/MetricDefinitions.js" as MetricDefinitions

Item {
    id: root

    property var discovery: null
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

    // Interface discovery via HardwareDiscovery
    property string _activeIface: ""
    property var _discoveredIfaces: []

    // Defer IP-discovery SensorDataModel until ksystemstats' network plugin has settled.
    property bool _bootReady: false
    Timer {
        interval: 500
        repeat: false
        running: true
        onTriggered: root._bootReady = true
    }

    function _refreshInterfaces() {
        if (!discovery) return;
        var ifaces = (discovery.discoveredNetworkIfaces || []).filter(function(iface) {
            return iface !== "auto";
        });
        if (JSON.stringify(ifaces) !== JSON.stringify(_discoveredIfaces))
            _discoveredIfaces = ifaces;
    }

    Connections {
        target: discovery
        function onRevisionChanged() { root._refreshInterfaces(); }
    }

    onDiscoveryChanged: _refreshInterfaces()

    Component.onCompleted: {
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
        enabled: root._bootReady
                 && root._ipSensorIds.length > 0
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
                    console.debug("[KVitals] NetworkSensors: active IP iface: " + iface + " (" + val + ")");
                    _activeIface = iface;
                }
                return;
            }
        }
        // No interface has an address - clear so the metric hides cleanly
        if (_activeIface !== "") {
            console.debug("[KVitals] NetworkSensors: no active IP iface, clearing.");
            _activeIface = "";
        }
    }

    // Traffic sensors

    // Raw numeric rates (bytes/s) for chart history.
    // Number() coerces the occasional undefined value to NaN.
    readonly property real netDownRaw: netDownSensor.status === Sensors.Sensor.Ready ? Number(netDownSensor.value) : NaN
    readonly property real netUpRaw:   netUpSensor.status   === Sensors.Sensor.Ready ? Number(netUpSensor.value)   : NaN

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

    // Cumulative totals sensors
    readonly property real netTotalDownRaw: (netTotalDownSensor.status === Sensors.Sensor.Ready && netTotalDownSensor.value != null) ? Number(netTotalDownSensor.value) : NaN
    readonly property real netTotalUpRaw:   (netTotalUpSensor.status   === Sensors.Sensor.Ready && netTotalUpSensor.value != null)   ? Number(netTotalUpSensor.value)   : NaN

    readonly property string netTotalDownValue: isNaN(netTotalDownRaw) ? "..." : Utils.formatData(netTotalDownRaw)
    readonly property string netTotalUpValue:   isNaN(netTotalUpRaw)   ? "..." : Utils.formatData(netTotalUpRaw)

    Sensors.Sensor {
        id: netTotalDownSensor
        sensorId: "network/" + root.netIfacePath + "/totalDownload"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: netTotalUpSensor
        sensorId: "network/" + root.netIfacePath + "/totalUpload"
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

    // Wi-Fi signal sensor
    readonly property string netSignalSensorId: {
        if (netIpIfacePath === "") return "";
        if (discovery && !discovery.sensorExists("network/" + netIpIfacePath + "/signal")) return "";
        return "network/" + netIpIfacePath + "/signal";
    }

    readonly property real netSignalRaw: (netSignalSensor.status === Sensors.Sensor.Ready && netSignalSensor.value != null) ? Number(netSignalSensor.value) : NaN
    readonly property string netSignalValue: isNaN(netSignalRaw) ? "" : Math.round(netSignalRaw) + "%"
    readonly property bool hasWifiSignal: netSignalSensorId !== "" && !isNaN(netSignalRaw)

    Sensors.Sensor {
        id: netSignalSensor
        sensorId: root.netSignalSensorId
        updateRateLimit: root.updateInterval
        enabled: root.netSignalSensorId !== ""
    }
}
