import QtQuick
import QtTest
import "../../contents/ui/models/ConfigLogic.js" as ConfigLogic

TestCase {
    name: "ConfigLogicQmlRuntime"

    function test_csvOperations_data() {
        return [
            { tag: "toggle existing", operation: "toggle", input: "cpu,ram,temp", value: "ram", expected: "cpu,temp" },
            { tag: "toggle missing", operation: "toggle", input: "cpu,ram", value: "temp", expected: "cpu,ram,temp" },
            { tag: "pin is idempotent", operation: "pin", input: "cpu", value: "cpu", expected: "cpu" },
            { tag: "unpin", operation: "unpin", input: "cpu,ram", value: "cpu", expected: "ram" }
        ];
    }

    function test_csvOperations(data) {
        if (data.operation === "toggle") {
            compare(ConfigLogic.toggleCsvMembership(data.input, data.value, "cpu"), data.expected);
        } else {
            compare(ConfigLogic.setCsvMembership(data.input, data.value, data.operation === "pin", "cpu"), data.expected);
        }
    }

    function test_normalizeOrder() {
        var allowed = ["cpu", "ram", "temp", "net"];
        compare(ConfigLogic.normalizeOrder("net,cpu,unknown,cpu", allowed, "cpu,ram,temp,net").join(","),
                "net,cpu,ram,temp");
    }

    function test_selectionRoundTrip() {
        var devices = ["gpu0", "gpu1", "gpu2"];
        compare(ConfigLogic.updateSelection("", "gpu1", false, devices), "gpu0,gpu2");
        compare(ConfigLogic.updateSelection("gpu0,gpu2", "gpu1", true, devices), "gpu0,gpu2,gpu1");
        verify(ConfigLogic.isSelectionEnabled("", "gpu1"));
        verify(!ConfigLogic.isSelectionEnabled("gpu0", "gpu1"));
    }

    function test_invalidJsonIsSafe() {
        compare(JSON.stringify(ConfigLogic.parseJsonMap("not-json")), "{}");
        compare(JSON.stringify(ConfigLogic.parseJsonMap("[]")), "{}");
        compare(JSON.stringify(ConfigLogic.parseJsonMap('{"gpu0":"Discrete"}')), '{"gpu0":"Discrete"}');
    }
}
