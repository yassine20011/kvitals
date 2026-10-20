import test from "node:test";
import assert from "node:assert/strict";
import { loadQmlLibrary, readProjectFile } from "./helpers.js";
import { metric, profile, SYSFS, TEMP_SENSORS } from "./fixtures.js";

const ViewHelpers = loadQmlLibrary("contents/ui/models/ViewHelpers.js");
const Definitions = loadQmlLibrary("contents/ui/models/MetricDefinitions.js");
const DiskSensors = loadQmlLibrary("contents/ui/models/DiskSensorLogic.js");
const Profiles = loadQmlLibrary("contents/ui/models/ProfileLogic.js");
const Config = loadQmlLibrary("contents/ui/models/ConfigLogic.js");

test("regression: network segments keep the family and directional icons", () => {
    const metrics = [
        metric({ id: "net/down", group: "net", subKey: "down", label: "NET", groupLabel: "NET", groupIcon: "network-symbolic", icon: "network-download-symbolic", displayValue: "1 KB/s" }),
        metric({ id: "net/up", group: "net", subKey: "up", label: "NET", groupLabel: "NET", groupIcon: "network-symbolic", icon: "network-upload-symbolic", displayValue: "2 KB/s" })
    ];
    const item = ViewHelpers.buildCompactItems(metrics, metrics.map(entry => entry.id), true)[0];

    assert.equal(item.icon, "network-symbolic");
    assert.deepEqual(Array.from(item.segments, segment => segment.icon), ["network-download-symbolic", "network-upload-symbolic"]);
});

test("regression: disk temperature is compacted without a redundant label or icon", () => {
    const metrics = [
        metric({ id: "disk:nvme0n1/read", group: "disk", deviceId: "nvme0n1", subKey: "read", label: "DSK 1", groupLabel: "DSK 1", groupIcon: "storage-symbolic", displayValue: "10 MB/s" }),
        metric({ id: "disk:nvme0n1/temp", group: "disk", deviceId: "nvme0n1", subKey: "temp", label: "DSK 1", groupLabel: "DSK 1", groupIcon: "storage-symbolic", icon: "temperature-symbolic", displayValue: "52°C" })
    ];
    const item = ViewHelpers.buildCompactItems(metrics, metrics.map(entry => entry.id), true)[0];
    const temperature = item.segments.find(segment => segment.key === "temp");

    assert.equal(temperature.value, "52°C");
    assert.equal(temperature.icon, "");
    assert.equal(temperature.label, "");
});

test("regression: NVMe namespaces on one controller share its sensor", () => {
    const namespace2 = SYSFS.nvme0.replace("nvme0n1:", "nvme0n2:");
    const map = DiskSensors.parseSysfsOutput([SYSFS.nvme0, namespace2].join("\n"), [TEMP_SENSORS.nvme0]);
    assert.equal(map.nvme0n1, TEMP_SENSORS.nvme0);
    assert.equal(map.nvme0n2, TEMP_SENSORS.nvme0);
});

test("regression: battery IDs may begin with 'all' and malformed paths do not match", () => {
    assert.equal(Definitions.PATTERNS.BATTERY.test("power/alloy-pack/chargePercentage"), true);
    assert.equal(Definitions.PATTERNS.BATTERY.test("power/all/chargePercentage"), true);
    assert.equal(Definitions.PATTERNS.BATTERY.test("power/BAT0/voltage"), false);
    assert.equal(Definitions.PATTERNS.BATTERY.test("power//chargePercentage"), false);
});

test("regression: damaged profile JSON is rejected before state replacement", () => {
    for (const raw of ["invalid{json", "{}", '{"profiles":[]}', '{"profiles":[{"id":"x"}]}']) {
        let parsed = null;
        try { parsed = JSON.parse(raw); } catch {}
        assert.equal(Profiles.validateProfiles(parsed && parsed.profiles), false);
    }
});

test("regression: custom profile named Default remains deletable", () => {
    const profiles = [profile(), profile({ id: "custom", isDefault: false })];
    assert.equal(Profiles.canDeleteProfile(profiles, "profile-1"), false);
    assert.equal(Profiles.canDeleteProfile(profiles, "custom"), true);
});

test("regression: default metric order includes swap and uptime", () => {
    const order = Config.parseCsv(Config.DEFAULT_METRIC_ORDER);
    assert.equal(order.includes("swap"), true);
    assert.equal(order.includes("uptime"), true);
    assert.deepEqual(new Set(order), new Set(Definitions.ALL_GROUP_KEYS));
});

test("regression: RAM temperature remains available in the panel palette", () => {
    const panelOrder = readProjectFile("contents/ui/configPanelOrder.qml");
    assert.match(panelOrder, /id:\s*["']ram\/temp["']/);
    assert.match(panelOrder, /RAM Temperature/);
});
