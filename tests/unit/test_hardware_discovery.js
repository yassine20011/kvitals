import test from "node:test";
import assert from "node:assert/strict";
import { loadQmlLibrary } from "../helpers.js";
import { SENSOR_IDS } from "../fixtures.js";

const Definitions = loadQmlLibrary("contents/ui/models/MetricDefinitions.js");
const Inventory = loadQmlLibrary("contents/ui/models/HardwareInventoryLogic.js");

function sampleSensors() {
    return [
        SENSOR_IDS.cpuOverall,
        ...SENSOR_IDS.cpuCores,
        ...SENSOR_IDS.gpus,
        ...SENSOR_IDS.disks,
        SENSOR_IDS.ignoredDisk,
        ...SENSOR_IDS.networks,
        SENSOR_IDS.battery,
        SENSOR_IDS.fan,
        SENSOR_IDS.diskTemperature
    ];
}

test("classifies the complete KSystemStats inventory", () => {
    const result = Inventory.buildInventory(sampleSensors(), Definitions.PATTERNS);

    assert.deepEqual(Array.from(result.gpus, item => item.id), ["gpu0", "gpu1"]);
    assert.deepEqual(Array.from(result.disks, item => item.id), ["nvme0n1", "sda"]);
    assert.deepEqual(Array.from(result.cpuCores, item => item.id), ["cpu0", "cpu2", "cpu10"]);
    assert.deepEqual(Array.from(result.cpuCores, item => item.name), ["Core 1", "Core 3", "Core 11"]);
    assert.deepEqual(Array.from(result.networkIfaces), ["auto", "wlan0"]);
    assert.deepEqual(Array.from(result.batteries), ["BAT0"]);
    assert.deepEqual(Array.from(result.diskTemps), [SENSOR_IDS.diskTemperature]);
    assert.equal(result.fans.length, 1);
    assert.equal(result.idSet[SENSOR_IDS.cpuOverall], true);
});

test("preserves display names and rejects pattern-like tree nodes", () => {
    const result = Inventory.buildInventory([
        { id: "cpu/all/usage", name: "Total CPU" },
        { id: "cpu/(cpu*)/usage", name: "CPU wildcard" },
        { id: "", name: "Missing" },
        null
    ], Definitions.PATTERNS);

    assert.deepEqual(Array.from(result.allIds), ["cpu/all/usage"]);
    assert.deepEqual({ ...result.allSensors[0] }, { id: "cpu/all/usage", name: "Total CPU" });
});
