import test from "node:test";
import assert from "node:assert/strict";
import { loadQmlLibrary } from "../helpers.js";
import { SYSFS, TEMP_SENSORS } from "../fixtures.js";

const DiskSensorLogic = loadQmlLibrary("contents/ui/models/DiskSensorLogic.js");

test("maps NVMe and SATA devices to their real temperature sensors", () => {
    const input = [SYSFS.nvme0, SYSFS.nvme2, SYSFS.sata0, SYSFS.sata2].join("\n");
    const result = DiskSensorLogic.parseSysfsOutput(input, Object.values(TEMP_SENSORS));

    assert.deepEqual({ ...result }, {
        nvme0n1: TEMP_SENSORS.nvme0,
        nvme2n1: TEMP_SENSORS.nvme2,
        sda: TEMP_SENSORS.sata0,
        sdb: TEMP_SENSORS.sata2
    });
});

test("does not invent mappings for malformed, USB, or unavailable devices", () => {
    const input = ["malformed", SYSFS.sata2, "sdc:usb:/sys/devices/usb1"].join("\n");
    const result = DiskSensorLogic.parseSysfsOutput(input, [TEMP_SENSORS.sata2]);

    assert.equal(result.sda, undefined);
    assert.equal(result.sdc, undefined);
    assert.equal(result.sdb, TEMP_SENSORS.sata2);
    assert.deepEqual({ ...DiskSensorLogic.parseSysfsOutput("", []) }, {});
});

test("falls back to the first matching adapter sensor when temp1 is absent", () => {
    const alternate = "lmsensors/nvme-pci-0100/temp2";
    const result = DiskSensorLogic.parseSysfsOutput(SYSFS.nvme0, [alternate]);
    assert.equal(result.nvme0n1, alternate);
});

test("direct KSystemStats temperature takes priority over sysfs", () => {
    const map = { sda: TEMP_SENSORS.sata0 };
    const direct = new Set(["disk/sda/temperature"]);

    assert.equal(DiskSensorLogic.resolveTemperatureSensor("sda", map, id => direct.has(id)), "disk/sda/temperature");
    assert.equal(DiskSensorLogic.resolveTemperatureSensor("sdb", map, () => false), "");
    assert.equal(DiskSensorLogic.resolveTemperatureSensor("", map, () => true), "");
});
