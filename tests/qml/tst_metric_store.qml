import QtQuick
import QtTest
import "../../contents/ui/models" as Models

TestCase {
    id: testCase
    name: "MetricStoreComponent"

    QtObject {
        id: configuration

        property int updateInterval: 60000
        property var pinnedList: ["cpu/usage"]
        property string cpuLabel: "CPU"
        property string ramLabel: "RAM"
        property string swapLabel: "SWAP"
        property string tempLabel: "System"
        property string netLabel: "NET"
        property string diskLabel: "DSK"
        property string fanLabel: "FAN"
        property string batLabel: "BAT"
        property string gpuLabels: "{}"
        property string diskLabels: "{}"
        property string fanLabels: "{}"
        property string gpuSelection: ""
        property string networkInterface: "auto"
        property string batteryDevice: "auto"
        property bool enableThresholdColors: false
        property color warningColor: "#e5a50a"
        property color criticalColor: "#da4453"

        function resolveIcon(name) { return name || ""; }
        function getGroupIcon(group) { return group + "-symbolic"; }
        function getGroupLabel(group) { return group.toUpperCase(); }
        function isPinned(instanceId) { return pinnedList.indexOf(instanceId) >= 0; }
        function getWarningThreshold(key) { return key === "cpu" ? 70 : 60; }
        function getCriticalThreshold(key) { return key === "cpu" ? 90 : 85; }
    }

    QtObject {
        id: sensorSet

        property QtObject cpu: QtObject {
            property real cpuNumericValue: 42
            property string cpuValue: "42%"
            property string cpuFreqValue: ""
            property string cpuLoad1Value: ""
            property string cpuLoad5Value: ""
            property string cpuLoad15Value: ""
            property var coreDataList: []
        }
        property var memory: null
        property var swap: null
        property var temp: null
        property var gpu: null
        property var battery: null
        property var network: null
        property var disk: null
        property var fan: null
        property var uptime: null
    }

    Models.MetricStore {
        id: metricStore
        config: configuration
        sensors: sensorSet
        sensorsReady: true
        baseTextColor: "#ffffff"
    }

    function init() {
        configuration.enableThresholdColors = false;
        sensorSet.cpu.cpuNumericValue = 42;
        sensorSet.cpu.cpuValue = "42%";
        metricStore.sensorsReady = true;
        metricStore._rebuildMetrics();
    }

    function test_buildsMetricFromMockedSensor() {
        compare(metricStore.metrics.length, 1);
        compare(metricStore.metrics[0].id, "cpu/usage");
        compare(metricStore.metrics[0].displayValue, "42%");
        compare(metricStore.metrics[0].status, "ready");
        verify(metricStore.metrics[0].isPinned);
    }

    function test_reactsToThresholdConfiguration() {
        configuration.enableThresholdColors = true;
        sensorSet.cpu.cpuNumericValue = 91;
        sensorSet.cpu.cpuValue = "91%";
        metricStore._rebuildMetrics();
        compare(metricStore.metrics[0].color.toString(), configuration.criticalColor.toString());
    }

    function test_clearsMetricsWhenSensorsAreNotReady() {
        metricStore.sensorsReady = false;
        metricStore._rebuildMetrics();
        compare(metricStore.metrics.length, 0);
    }
}
