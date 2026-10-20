import test from "node:test";
import assert from "node:assert/strict";
import { loadQmlLibrary, readProjectFile } from "../helpers.js";

const MetricDefs = loadQmlLibrary("contents/ui/models/MetricDefinitions.js");

test("buildInstanceId constructs correct instance identifier", () => {
    assert.equal(MetricDefs.buildInstanceId("cpu", "", "usage"), "cpu/usage");
    assert.equal(MetricDefs.buildInstanceId("cpu", null, "usage"), "cpu/usage");
    assert.equal(MetricDefs.buildInstanceId("disk", "nvme0n1", "read"), "disk:nvme0n1/read");
    assert.equal(MetricDefs.buildInstanceId("gpu", "gpu0", "temp"), "gpu:gpu0/temp");
});

test("isBundledIcon identifies bundled vs system icons", () => {
    assert.equal(MetricDefs.isBundledIcon("cpu-symbolic"), true);
    assert.equal(MetricDefs.isBundledIcon("battery-symbolic"), true);
    assert.equal(MetricDefs.isBundledIcon("voltage-symbolic"), true);
    assert.equal(MetricDefs.isBundledIcon("nonexistent-icon"), false);
    assert.equal(MetricDefs.isBundledIcon(""), false);
    assert.equal(MetricDefs.isBundledIcon(null), false);
});

test("PATTERNS matches hardware sensor IDs correctly", () => {
    const P = MetricDefs.PATTERNS;

    assert.ok(P.CPU_CORE.test("cpu/cpu0/usage"));
    assert.ok(P.CPU_CORE.test("cpu/cpu15/usage"));
    assert.ok(!P.CPU_CORE.test("cpu/all/usage"));

    assert.ok(P.GPU.test("gpu/gpu0/usage"));
    assert.ok(P.GPU.test("gpu/gpu1/usage"));
    assert.ok(!P.GPU.test("gpu/all/usage"));

    assert.ok(P.NETWORK_IFACE.test("network/wlan0/download"));
    assert.ok(P.NETWORK_IFACE.test("network/eth0/download"));
    assert.ok(!P.NETWORK_IFACE.test("network/download"));
    assert.ok(!P.NETWORK_IFACE.test("cpu/all/download"));

    assert.ok(P.FAN.test("lmsensors/it8688-isa-0a30/fan1"));
    assert.ok(P.FAN.test("cpu/all/fan1"));
    assert.ok(P.FAN.test("gpu/gpu0/fan1"));

    assert.ok(P.TEMP_LMSENSORS.test("lmsensors/k10temp-pci-00c3/temp1"));
    assert.ok(!P.TEMP_LMSENSORS.test("cpu/all/temperature"));
});

test("DEFINITIONS contains valid metric structures", () => {
    const defs = MetricDefs.DEFINITIONS;
    const groups = MetricDefs.GROUPS;
    const validThresholdTypes = ["normal", "inverted", "none"];

    for (const [key, def] of Object.entries(defs)) {
        assert.equal(def.id, key);
        assert.ok(def.group, `Group required for ${key}`);
        assert.ok(groups[def.group], `Group ${def.group} must exist in GROUPS`);
        assert.ok(def.subKey, `subKey required for ${key}`);
        assert.ok(def.label, `Label required for ${key}`);
        assert.ok(validThresholdTypes.includes(def.thresholdType), `Invalid thresholdType for ${key}`);
    }
});

test("every static MetricStore definition reference exists", () => {
    const store = readProjectFile("contents/ui/models/MetricStore.qml");
    const referenced = [...store.matchAll(/_createMetric\(["']([^"']+)["']/g)].map(match => match[1]);
    assert.ok(referenced.length > 0);
    for (const definitionId of referenced) {
        assert.ok(MetricDefs.DEFINITIONS[definitionId], `MetricStore references undefined metric '${definitionId}'`);
    }
});
