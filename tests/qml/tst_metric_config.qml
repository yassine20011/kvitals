import QtQuick
import QtTest
import "../../contents/ui/models" as Models

TestCase {
    id: testCase
    name: "MetricConfigComponent"

    QtObject {
        id: configuration

        property string pinnedMetrics: "cpu,ram,temp"
        property string metricOrder: "net,cpu"
        property string gpuSelection: ""
        property string gpuLabels: "{}"
        property string diskLabels: "{}"
        property string fanLabels: "{}"
        property string cpuLabel: "Processor"
        property int cpuWarningThreshold: 72
        property int cpuCriticalThreshold: 91
    }

    Models.MetricConfig {
        id: metricConfig
        target: configuration
    }

    function init() {
        configuration.pinnedMetrics = "cpu,ram,temp";
        configuration.metricOrder = "net,cpu";
        configuration.gpuSelection = "";
        configuration.gpuLabels = "{}";
    }

    function test_readsConfigurationBindings() {
        compare(metricConfig.pinnedList.join(","), "cpu,ram,temp");
        verify(metricConfig.isPinned("ram"));
        compare(metricConfig.getGroupLabel("cpu"), "Processor");
        compare(metricConfig.getWarningThreshold("cpu"), 72);
        compare(metricConfig.getCriticalThreshold("cpu"), 91);
    }

    function test_updatesPinsThroughProductionComponent() {
        metricConfig.togglePin("ram");
        compare(configuration.pinnedMetrics, "cpu,temp");

        metricConfig.setPinned("disk", true);
        compare(configuration.pinnedMetrics, "cpu,temp,disk");

        metricConfig.movePinnedMetric(2, 0);
        compare(configuration.pinnedMetrics, "disk,cpu,temp");
    }

    function test_updatesHardwareConfiguration() {
        metricConfig.setGpuSelected("gpu1", false, ["gpu0", "gpu1"]);
        compare(configuration.gpuSelection, "gpu0");

        metricConfig.saveGpuLabel("gpu0", "Integrated");
        compare(JSON.parse(configuration.gpuLabels).gpu0, "Integrated");
    }

    function test_normalizesAndMovesMetricOrder() {
        compare(metricConfig.orderedKeys.slice(0, 2).join(","), "net,cpu");
        verify(metricConfig.orderedKeys.indexOf("ram") >= 0);

        metricConfig.moveMetric(0, 2);
        compare(configuration.metricOrder.split(",").slice(0, 3).join(","), "cpu,ram,net");
    }
}
