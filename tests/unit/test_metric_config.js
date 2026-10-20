import test from "node:test";
import assert from "node:assert/strict";
import { loadQmlLibrary } from "../helpers.js";

const Config = loadQmlLibrary("contents/ui/models/ConfigLogic.js");
const Definitions = loadQmlLibrary("contents/ui/models/MetricDefinitions.js");

test("CSV parsing normalizes whitespace and empty fields", () => {
    assert.deepEqual(Array.from(Config.parseCsv(" cpu/usage, ,ram/percentage ,")), ["cpu/usage", "ram/percentage"]);
    assert.deepEqual(Array.from(Config.parseCsv(null)), []);
});

test("pinning operations share one canonical list implementation", () => {
    const defaults = Config.DEFAULT_PINNED_METRICS;
    const withoutCpu = Config.toggleCsvMembership(defaults, "cpu/usage", defaults);
    assert.equal(Config.parseCsv(withoutCpu).includes("cpu/usage"), false);

    const restored = Config.setCsvMembership(withoutCpu, "cpu/usage", true, defaults);
    assert.equal(Config.parseCsv(restored).includes("cpu/usage"), true);
    assert.equal(Config.parseCsv(restored).filter(id => id === "cpu/usage").length, 1);

    assert.equal(Config.moveCsvItem("a,b,c", 0, 2), "b,c,a");
    assert.equal(Config.moveCsvItem("a,b,c", -1, 2), "a,b,c");
});

test("JSON labels support current and legacy storage formats", () => {
    assert.deepEqual({ ...Config.parseJsonMap(JSON.stringify({ gpu0: "Discrete" })) }, { gpu0: "Discrete" });
    assert.deepEqual({ ...Config.parseJsonMap("gpu0:NVIDIA RTX | gpu1:Intel UHD") }, {
        gpu0: "NVIDIA RTX",
        gpu1: "Intel UHD"
    });
    assert.deepEqual({ ...Config.parseJsonMap("{broken") }, {});
    assert.deepEqual({ ...Config.parseJsonMap("[]") }, {});
});

test("GPU selection distinguishes all, none, and explicit devices", () => {
    const devices = ["gpu0", "gpu1"];
    assert.equal(Config.isSelectionEnabled("", "gpu0"), true);
    assert.equal(Config.isSelectionEnabled(Config.DISABLED_SELECTION, "gpu0"), false);

    const oneSelected = Config.updateSelection("", "gpu0", false, devices);
    assert.equal(oneSelected, "gpu1");
    assert.equal(Config.isSelectionEnabled(oneSelected, "gpu1"), true);
    assert.equal(Config.updateSelection(oneSelected, "gpu1", false, devices), Config.DISABLED_SELECTION);
    assert.equal(Config.updateSelection(Config.DISABLED_SELECTION, "gpu0", true, devices), "gpu0");
});

test("metric ordering removes invalid duplicates and appends every supported group", () => {
    const order = Config.normalizeOrder("gpu,cpu,gpu,unknown", Definitions.ALL_GROUP_KEYS, Config.DEFAULT_METRIC_ORDER);
    assert.deepEqual(Array.from(order.slice(0, 2)), ["gpu", "cpu"]);
    assert.equal(new Set(order).size, order.length);
    assert.deepEqual(new Set(order), new Set(Definitions.ALL_GROUP_KEYS));
});
