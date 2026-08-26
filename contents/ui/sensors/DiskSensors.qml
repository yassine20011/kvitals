    import QtQuick
    import org.kde.ksysguard.sensors as Sensors
    import org.kde.plasma.plasma5support as P5Support
    import "../models/MetricDefinitions.js" as MetricDefinitions

    Item {
        id: root

        property var discovery: null
        property int updateInterval: 2000
        property bool enabled: true
        property string tempUnit: "C"
        property string networkUnit: "bytes"
        property string diskLabels: ""

        readonly property string diskReadValue:  Utils.formatRate(diskReadSensor.status  === Sensors.Sensor.Ready ? diskReadSensor.value  : NaN, networkUnit)
        readonly property string diskWriteValue: Utils.formatRate(diskWriteSensor.status === Sensors.Sensor.Ready ? diskWriteSensor.value : NaN, networkUnit)

        readonly property real   diskUsedPercentRaw: (diskUsedPercentSensor.status === Sensors.Sensor.Ready && diskUsedPercentSensor.value != null) ? Number(diskUsedPercentSensor.value) : NaN
        readonly property string diskUsedPercentValue: isNaN(diskUsedPercentRaw) ? "" : Math.round(diskUsedPercentRaw) + "%"

        readonly property real   diskUsedRaw: (diskUsedSensor.status === Sensors.Sensor.Ready && diskUsedSensor.value != null) ? Number(diskUsedSensor.value) : NaN
        readonly property real   diskTotalRaw: (diskTotalSensor.status === Sensors.Sensor.Ready && diskTotalSensor.value != null) ? Number(diskTotalSensor.value) : NaN
        readonly property string diskSpaceValue: (!isNaN(diskUsedRaw) && !isNaN(diskTotalRaw) && diskTotalRaw > 0) ? (Utils.formatBytes(diskUsedRaw) + "/" + Utils.formatBytes(diskTotalRaw) + "G") : ""

        readonly property var discoveredDisks: _discovered
        property var _discovered: []

        readonly property var diskDataList: _dataList
        property var _dataList: []

        readonly property bool multiDisk: _discovered.length > 1

        // Defer SensorDataModel subscriptions until ksystemstats' disk plugin has settled.
        property bool _bootReady: false
        Timer {
            interval: 500
            repeat: false
            running: true
            onTriggered: {
                root._bootReady = true;
                root.aggregatePerDisk();
            }
        }
        on_BootReadyChanged: {
            if (_bootReady) {
                aggregatePerDisk();
            }
        }

        // Defer P5Support.DataSource (hotplug) until Solid/UDisks2 is fully ready.
        property bool _hotplugReady: false
        Timer {
            interval: 1000
            repeat: false
            running: true
            onTriggered: root._hotplugReady = true
        }

        // Aggregate I/O sensors (used in compact panel and tooltip)
        Sensors.Sensor {
            id: diskReadSensor
            sensorId: "disk/all/read"
            updateRateLimit: root.updateInterval
            enabled: root.enabled
        }

        Sensors.Sensor {
            id: diskWriteSensor
            sensorId: "disk/all/write"
            updateRateLimit: root.updateInterval
            enabled: root.enabled
        }

        Sensors.Sensor {
            id: diskUsedPercentSensor
            sensorId: "disk/all/usedPercent"
            updateRateLimit: root.updateInterval
            enabled: root.enabled
        }

        Sensors.Sensor {
            id: diskUsedSensor
            sensorId: "disk/all/used"
            updateRateLimit: root.updateInterval
            enabled: root.enabled
        }

        Sensors.Sensor {
            id: diskTotalSensor
            sensorId: "disk/all/total"
            updateRateLimit: root.updateInterval
            enabled: root.enabled
        }

        // --- Per-disk discovery via HardwareDiscovery ---

        function refreshDiscovered() {
            if (!discovery) return;
            var disks = discovery.discoveredDisks || [];
            var found = [];
            for (var i = 0; i < disks.length; i++) {
                var did = disks[i].id;
                if (_unplugged[did]) continue;
                found.push({ id: did, name: "DSK " + (found.length + 1) });
            }
            if (JSON.stringify(found) !== JSON.stringify(_discovered)) {
                _discovered = found;
                aggregatePerDisk();
            }
        }

        // --- Per-disk sensor IDs ---

        readonly property var _activeSensorIds: {
            var ids = [];
            for (var i = 0; i < _discovered.length; i++) {
                ids.push("disk/" + _discovered[i].id + "/read");
                ids.push("disk/" + _discovered[i].id + "/write");
            }
            return ids;
        }

        // Periodic poll timer to ensure idle zero-value sensors update reliably
        Timer {
            id: pollTimer
            interval: root.updateInterval
            repeat: true
            running: root.enabled && root._bootReady
            triggeredOnStart: true
            onTriggered: {
                root.aggregatePerDisk();
            }
        }

        // --- Per-disk SensorDataModel ---

        Sensors.SensorDataModel {
            id: diskData
            // Defer DBus subscriptions by keeping sensors empty until boot guards pass,
            // avoiding KSysGuard C++ bugs where setting enabled=false on boot freezes the model
            sensors: root._bootReady ? root._activeSensorIds : []
            updateRateLimit: root.updateInterval
            enabled: sensors.length > 0
            onDataChanged: root.aggregatePerDisk()
            onReadyChanged: { if (ready) root.aggregatePerDisk(); }
            onRowsInserted: root.aggregatePerDisk()
            onColumnsInserted: root.aggregatePerDisk()
            onModelReset: root.aggregatePerDisk()
            onLayoutChanged: root.aggregatePerDisk()
        }

        function parseDiskLabels(str) {
            if (!str) return {};
            if (typeof str === "object") return str;
            var trimmed = String(str).trim();
            if (trimmed.startsWith("{")) {
                try {
                    return JSON.parse(trimmed);
                } catch (e) {}
            }
            var result = {};
            trimmed.split("|").forEach(function(pair) {
                var sep = pair.indexOf(":");
                if (sep > 0) result[pair.substring(0, sep).trim()] = pair.substring(sep + 1).trim();
            });
            return result;
        }

        function _modelValue(sensorId) {
            var col = diskData.column(sensorId);
            if (col < 0) return NaN;
            var idx = diskData.index(0, col);
            if (!idx.valid) return NaN;
            var val = diskData.data(idx, Sensors.SensorDataModel.Value);
            if (val === undefined || val === null) return NaN;
            var num = Number(val);
            return isNaN(num) ? NaN : num;
        }

        function _tempModelValue(sensorId) {
            var col = tempData.column(sensorId);
            if (col < 0) return NaN;
            var idx = tempData.index(0, col);
            if (!idx.valid) return NaN;
            var val = tempData.data(idx, Sensors.SensorDataModel.Value);
            if (typeof val !== "number" || isNaN(val) || val <= 0) return NaN;
            return val;
        }

        // Sysfs is used only for identity resolution; KSystemStats remains the value source
        readonly property string _sysfsScanCommand: "sh -c 'for b in /sys/class/block/*; do [ -e \"$b/device\" ] || continue; bname=$(basename \"$b\"); bdev=$(readlink -f \"$b/device\"); for h in /sys/class/hwmon/hwmon*; do [ -e \"$h/device\" ] || continue; hdev=$(readlink -f \"$h/device\"); if [ \"$bdev\" = \"$hdev\" ]; then hname=$(cat \"$h/name\" 2>/dev/null); echo \"$bname:$hname:$hdev\"; fi; done; done'"

        property var _sysfsDiskSensorMap: ({})

        function _parseSysfsOutput(rawOutput) {
            if (!rawOutput) return;
            var availableSensors = root._tempSensorIds;
            var map = {};
            var lines = String(rawOutput).split("\n");
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim();
                if (!line) continue;
                var parts = line.split(":");
                if (parts.length < 3) continue;
                var bname = parts[0].trim();
                var hname = parts[1].trim();
                var hdev = parts.slice(2).join(":").trim();

                var adapterPrefix = "";
                if (hname === "nvme") {
                    var pciMatches = hdev.match(/[0-9a-fA-F]{4}:([0-9a-fA-F]{2}):([0-9a-fA-F]{2})\.([0-9a-fA-F])/g);
                    if (pciMatches && pciMatches.length > 0) {
                        var lastPci = pciMatches[pciMatches.length - 1];
                        var m = lastPci.match(/([0-9a-fA-F]{2}):([0-9a-fA-F]{2})\.([0-9a-fA-F])/);
                        if (m) {
                            var pciAddr = m[1] + m[2];
                            adapterPrefix = "lmsensors/nvme-pci-" + pciAddr.toLowerCase();
                        }
                    }
                } else if (hname === "drivetemp") {
                    var scsiMatch = hdev.match(/host(\d+)\/target\d+:\d+:(\d+)\/(\d+):(\d+):(\d+):(\d+)/);
                    if (scsiMatch) {
                        adapterPrefix = "lmsensors/drivetemp-scsi-" + scsiMatch[1] + "-" + scsiMatch[2];
                    } else {
                        var scsiDevMatch = hdev.match(/(\d+):(\d+):(\d+):(\d+)$/);
                        if (scsiDevMatch) {
                            adapterPrefix = "lmsensors/drivetemp-scsi-" + scsiDevMatch[1] + "-" + scsiDevMatch[3];
                        }
                    }
                }

                if (adapterPrefix) {
                    var targetSensor = adapterPrefix + "/temp1";
                    if (availableSensors && availableSensors.length > 0) {
                        if (availableSensors.indexOf(targetSensor) !== -1) {
                            map[bname] = targetSensor;
                        } else {
                            for (var s = 0; s < availableSensors.length; s++) {
                                if (availableSensors[s].indexOf(adapterPrefix) === 0) {
                                    map[bname] = availableSensors[s];
                                    break;
                                }
                            }
                        }
                    } else {
                        map[bname] = targetSensor;
                    }
                }
            }
            _sysfsDiskSensorMap = map;
            root.aggregatePerDisk();
        }

        function _findTempSensorForDisk(diskId) {
            if (!diskId) return "";

            // Direct sensor
            var directId = "disk/" + diskId + "/temperature";
            if (discovery && discovery.sensorExists(directId)) return directId;

            // Sysfs-derived hardware mapping
            if (_sysfsDiskSensorMap[diskId]) return _sysfsDiskSensorMap[diskId];

            return "";
        }

        function aggregatePerDisk() {
            var custom = parseDiskLabels(diskLabels);
            var newList = [];
            for (var i = 0; i < _discovered.length; i++) {
                var d = _discovered[i];
                var rVal = _modelValue("disk/" + d.id + "/read");
                var wVal = _modelValue("disk/" + d.id + "/write");
                var rStr = !isNaN(rVal) ? Utils.formatRate(rVal, networkUnit).trim() : "...";
                var wStr = !isNaN(wVal) ? Utils.formatRate(wVal, networkUnit).trim() : "...";
                var tSensorId = _findTempSensorForDisk(d.id);
                var tVal = tSensorId ? _tempModelValue(tSensorId) : NaN;
                var tStr = !isNaN(tVal) ? Utils.formatTemp(tVal, tempUnit) : "";
                var name = custom[d.id] || d.name;
                newList.push({ id: d.id, name: name, read: rStr, write: wStr, temp: tStr, tempNumber: tVal });
            }
            _dataList = newList;
        }

        function _triggerSysfsScan() {
            if (sysfsLoader.item) {
                sysfsLoader.item.connectSource(root._sysfsScanCommand);
            }
        }

        // ksystemstats' disk plugin does NOT remove sensors or emit rowsRemoved
        // when a USB disk is unplugged — the sensor tree entries persist with 0
        // values indefinitely. The Solid hotplug dataengine emits add/remove
        // events for removable storage (driven by the same UDisks2 DBus signals
        // plasmashell already listens to for the device notifier), so track
        // devices we saw removed and filter them out of discovery. Internal
        // disks never appear in this engine, so they are never filtered.
        property var _unplugged: ({})

        function _udiToDisk(udi) {
            // e.g. /org/freedesktop/UDisks2/block_devices/sdb1 -> "sdb"
            var m = String(udi).match(/\/(sd[a-z]+|nvme\d+n\d+)(?:p?\d+)?$/);
            return m ? m[1] : "";
        }

        Loader {
            id: sysfsLoader
            active: root._hotplugReady
            sourceComponent: P5Support.DataSource {
                engine: "executable"
                connectedSources: []
                onNewData: function(sourceName, data) {
                    if (data && data["stdout"]) {
                        root._parseSysfsOutput(data["stdout"]);
                    }
                    disconnectSource(sourceName);
                }
                Component.onCompleted: {
                    connectSource(root._sysfsScanCommand);
                }
            }
        }

        Loader {
            active: root._hotplugReady
            sourceComponent: P5Support.DataSource {
                engine: "hotplug"
                onSourceAdded: function(source) {
                    var disk = root._udiToDisk(source);
                    if (disk && root._unplugged[disk]) {
                        delete root._unplugged[disk];
                        root.refreshDiscovered();
                        root._triggerSysfsScan();
                    }
                }
                onSourceRemoved: function(source) {
                    var disk = root._udiToDisk(source);
                    if (disk) {
                        root._unplugged[disk] = true;
                        root.refreshDiscovered();
                        root._triggerSysfsScan();
                    }
                }
            }
        }

        // Per-disk temperature sensor discovery

        property var _tempSensorIds: []

        function _refreshTempSensors() {
            if (!discovery) return;
            var pattern = MetricDefinitions.PATTERNS ? MetricDefinitions.PATTERNS.DISK_TEMP : /^(?:disk\/(?:nvme\d+n\d+|sd[a-z]+)\/temperature|lmsensors\/(?:nvme-pci-[^/]+|drivetemp-scsi-[^/]+|scsi-[^/]+|drivetemp-[^/]+)\/temp\d+)$/;
            var found = discovery.queryIds(pattern);
            for (var i = 0; i < _discovered.length; i++) {
                var direct = "disk/" + _discovered[i].id + "/temperature";
                if (discovery.sensorExists(direct) && found.indexOf(direct) === -1) {
                    found.push(direct);
                }
            }
            if (JSON.stringify(found) !== JSON.stringify(_tempSensorIds)) {
                _tempSensorIds = found;
            }
        }

        Connections {
            target: discovery
            function onRevisionChanged() {
                root.refreshDiscovered();
                root._refreshTempSensors();
            }
        }

        onDiscoveryChanged: {
            refreshDiscovered();
            _refreshTempSensors();
        }

        Sensors.SensorDataModel {
            id: tempData
            sensors: root._bootReady ? root._tempSensorIds : []
            updateRateLimit: root.updateInterval
            enabled: sensors.length > 0
            onDataChanged: root.aggregatePerDisk()
            onReadyChanged: { if (ready) root.aggregatePerDisk(); }
            onRowsInserted: root.aggregatePerDisk()
            onColumnsInserted: root.aggregatePerDisk()
            onModelReset: root.aggregatePerDisk()
            onLayoutChanged: root.aggregatePerDisk()
        }

        onDiskLabelsChanged: aggregatePerDisk()
        onNetworkUnitChanged: aggregatePerDisk()
        onTempUnitChanged: aggregatePerDisk()

        Component.onCompleted: {
            refreshDiscovered();
            _refreshTempSensors();
        }
    }
