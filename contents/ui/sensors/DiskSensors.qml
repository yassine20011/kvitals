import QtQuick
import org.kde.ksysguard.sensors as Sensors
import org.kde.kitemmodels as KItemModels

Item {
    id: root

    property int updateInterval: 2000
    property bool enabled: true

    readonly property string diskReadValue:  Utils.formatRate(diskReadSensor.status  === Sensors.Sensor.Ready ? diskReadSensor.value  : NaN)
    readonly property string diskWriteValue: Utils.formatRate(diskWriteSensor.status === Sensors.Sensor.Ready ? diskWriteSensor.value : NaN)

    // Highest temperature found across all discovered drive temp sensors (°C)
    readonly property real   diskTempNumber: _diskTempNum
    readonly property string diskTempValue:  isNaN(_diskTempNum) ? "" : Math.round(_diskTempNum) + "°C"

    property real _diskTempNum: NaN

    // I/O sensors 
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

    // Matches lmsensors chips that are NVMe (nvme-pci-*) or SATA drivetemp
    // (drivetemp-scsi-*) and picks temp1 (Composite) or temp2 (secondary sensor)

    Sensors.SensorTreeModel { id: sensorTree }

    KItemModels.KDescendantsProxyModel {
        id: flatSensors
        model: sensorTree
    }

    property var _tempSensorIds: []

    function _refreshTempSensors() {
        var found = [];
        for (var row = 0; row < flatSensors.rowCount(); row++) {
            var idx = flatSensors.index(row, 0);
            var sid = flatSensors.data(idx, Sensors.SensorTreeModel.SensorId);
            if (!sid) continue;
            if (/^lmsensors\/(nvme-pci-[^/]+|drivetemp-scsi-[^/]+)\/temp[12]$/.test(sid))
                found.push(sid);
        }
        if (JSON.stringify(found) !== JSON.stringify(_tempSensorIds))
            _tempSensorIds = found;
    }

    Connections {
        target: flatSensors
        function onRowsInserted() { root._refreshTempSensors(); }
        function onRowsRemoved()  { root._refreshTempSensors(); }
        function onModelReset()   { root._refreshTempSensors(); }
    }

    Component.onCompleted: _refreshTempSensors()

    // Poll discovered temp sensors
    Sensors.SensorDataModel {
        id: tempData
        sensors: root._tempSensorIds
        updateRateLimit: root.updateInterval
        enabled: root._tempSensorIds.length > 0
        onDataChanged: root._aggregateTemp()
        onReadyChanged: { if (ready) root._aggregateTemp(); }
    }

    function _aggregateTemp() {
        var max = NaN;
        for (var i = 0; i < _tempSensorIds.length; i++) {
            var col = tempData.column(_tempSensorIds[i]);
            if (col < 0) continue;
            var val = tempData.data(tempData.index(0, col), Sensors.SensorDataModel.Value);
            if (typeof val !== "number" || isNaN(val) || val <= 0) continue;
            if (isNaN(max) || val > max) max = val;
        }
        _diskTempNum = max;
    }
}
