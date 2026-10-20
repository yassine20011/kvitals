import test from "node:test";
import assert from "node:assert/strict";
import { loadQmlLibrary } from "../helpers.js";
import { metric } from "../fixtures.js";

const ViewHelpers = loadQmlLibrary("contents/ui/models/ViewHelpers.js");

test("buildCompactItems handles empty and invalid inputs", () => {
    assert.equal(ViewHelpers.buildCompactItems(null, ["cpu/usage"]).length, 0);
    assert.equal(ViewHelpers.buildCompactItems([], ["cpu/usage"]).length, 0);
    assert.equal(ViewHelpers.buildCompactItems([{ id: "cpu/usage", status: "ready" }], null).length, 0);
    assert.equal(ViewHelpers.buildCompactItems([{ id: "cpu/usage", status: "ready" }], []).length, 0);
    assert.equal(ViewHelpers.buildCompactItems([{ id: "cpu/usage", status: "loading" }], ["cpu/usage"]).length, 0);
});

test("buildCompactItems groups same family metrics when mergeSameFamily is true", () => {
    const metrics = [
        {
            id: "net/down",
            group: "net",
            subKey: "down",
            label: "NET",
            groupLabel: "NET",
            icon: "network-download-symbolic",
            groupIcon: "network-symbolic",
            displayValue: "10 KB/s",
            color: "#ffffff",
            status: "ready"
        },
        {
            id: "net/up",
            group: "net",
            subKey: "up",
            label: "NET",
            groupLabel: "NET",
            icon: "network-upload-symbolic",
            groupIcon: "network-symbolic",
            displayValue: "5 KB/s",
            color: "#ffffff",
            status: "ready"
        },
        {
            id: "cpu/usage",
            group: "cpu",
            subKey: "usage",
            label: "CPU",
            groupLabel: "CPU",
            icon: "cpu-symbolic",
            groupIcon: "cpu-symbolic",
            displayValue: "25%",
            color: "#ffffff",
            status: "ready"
        }
    ];

    const merged = ViewHelpers.buildCompactItems(metrics, ["net/down", "net/up", "cpu/usage"], true);
    assert.equal(merged.length, 2);
    assert.equal(merged[0].key, "net");
    assert.equal(merged[0].segments.length, 2);
    assert.equal(merged[1].key, "cpu");
    assert.equal(merged[1].segments, null);

    const unmerged = ViewHelpers.buildCompactItems(metrics, ["net/down", "net/up", "cpu/usage"], false);
    assert.equal(unmerged.length, 3);
    assert.equal(unmerged[0].segments, null);
    assert.equal(unmerged[1].segments, null);
});

test("buildPopupGroups filters unavailable metrics and aggregates categories", () => {
    assert.equal(ViewHelpers.buildPopupGroups([], []).length, 0);
    assert.equal(ViewHelpers.buildPopupGroups(null, []).length, 0);

    const metrics = [
        {
            id: "cpu/usage",
            group: "cpu",
            subKey: "usage",
            label: "CPU",
            displayValue: "30%",
            color: "#ffffff",
            status: "ready"
        },
        {
            id: "cpu/temp",
            group: "cpu",
            subKey: "temp",
            label: "CPU Temp",
            displayValue: "55°C",
            color: "#ffffff",
            status: "ready"
        },
        {
            id: "ram/percentage",
            group: "ram",
            subKey: "percentage",
            label: "RAM",
            displayValue: "60%",
            color: "#ffffff",
            status: "ready"
        },
        {
            id: "gpu/usage",
            group: "gpu",
            subKey: "usage",
            deviceId: "gpu0",
            label: "GPU",
            displayValue: "15%",
            color: "#ffffff",
            status: "unavailable"
        }
    ];

    const groups = ViewHelpers.buildPopupGroups(metrics, ["cpu", "ram", "temp", "gpu"]);
    const keys = groups.map(g => g.key);

    assert.ok(keys.includes("processor"));
    assert.ok(keys.includes("temperature"));
    assert.ok(keys.includes("memory"));
    assert.ok(!keys.includes("gpu"));

    const proc = groups.find(g => g.key === "processor");
    assert.equal(proc.aggregateValue, "30%");
});

test("syncCompactValues detects structural differences and syncs in-place", () => {
    assert.equal(ViewHelpers.syncCompactValues(null, []), false);
    assert.equal(ViewHelpers.syncCompactValues([], null), false);
    assert.equal(ViewHelpers.syncCompactValues([{ key: "cpu" }], []), false);

    const itemA = {
        key: "cpu",
        label: "CPU:",
        icon: "cpu-symbolic",
        value: "10%",
        color: "#ffffff",
        hideSeparator: false,
        segments: null
    };
    const incomingA = {
        key: "cpu",
        label: "CPU:",
        icon: "cpu-symbolic",
        value: "20%",
        color: "#ff0000",
        hideSeparator: false,
        segments: null
    };

    const targetList = [itemA];
    assert.equal(ViewHelpers.syncCompactValues(targetList, [incomingA]), true);
    assert.equal(targetList[0].value, "20%");
    assert.equal(targetList[0].color, "#ff0000");

    const mismatchSep = { ...incomingA, hideSeparator: true };
    assert.equal(ViewHelpers.syncCompactValues(targetList, [mismatchSep]), false);
});

test("buildPopupGroups covers every popup category and device section", () => {
    const metrics = [
        metric({ id: "temp/system", group: "temp", subKey: "temp", displayValue: "50°C" }),
        metric({ id: "fan:fan1/rpm", group: "fan", subKey: "rpm", displayValue: "900 RPM" }),
        metric({ id: "ram/percentage", group: "ram", subKey: "percentage", displayValue: "40%" }),
        metric({ id: "swap/percent", group: "swap", subKey: "percent", displayValue: "10%" }),
        metric({ id: "cpu/usage", group: "cpu", subKey: "usage", displayValue: "20%" }),
        metric({ id: "cpu/core0", group: "cpu", subKey: "core", displayValue: "10%" }),
        metric({ id: "bat/percentage", group: "bat", subKey: "percentage", displayValue: "80%" }),
        metric({ id: "uptime/uptime", group: "uptime", subKey: "uptime", displayValue: "1h" }),
        metric({ id: "net/down", group: "net", subKey: "down", displayValue: "1 KB/s" }),
        metric({ id: "disk/usage", group: "disk", subKey: "usage", displayValue: "50%" }),
        metric({ id: "disk:nvme0n1/read", group: "disk", subKey: "read", deviceId: "nvme0n1", deviceName: "System", displayValue: "2 MB/s" }),
        metric({ id: "disk:sda/read", group: "disk", subKey: "read", deviceId: "sda", deviceName: "Archive", displayValue: "3 MB/s" }),
        metric({ id: "gpu:gpu0/usage", group: "gpu", subKey: "usage", deviceId: "gpu0", deviceName: "Integrated", displayValue: "15%" }),
        metric({ id: "gpu:gpu1/usage", group: "gpu", subKey: "usage", deviceId: "gpu1", deviceName: "Discrete", displayValue: "25%" })
    ];
    const groups = ViewHelpers.buildPopupGroups(metrics, []);

    assert.deepEqual(Array.from(groups, group => group.key), [
        "temperature", "fan", "memory", "processor", "battery", "system", "network", "storage", "gpu"
    ]);
    assert.deepEqual(Array.from(groups.find(group => group.key === "memory").sections, section => section.sectionLabel), ["RAM", "Swap"]);
    assert.deepEqual(Array.from(groups.find(group => group.key === "processor").sections, section => section.sectionLabel), ["", "Cores"]);
    assert.deepEqual(Array.from(groups.find(group => group.key === "storage").sections, section => section.sectionLabel), ["Overall", "System", "Archive"]);
    assert.deepEqual(Array.from(groups.find(group => group.key === "gpu").sections, section => section.sectionLabel), ["Integrated", "Discrete"]);
});

test("compact segments retain prefix and core labels", () => {
    const metrics = [
        metric({ id: "fan:one/rpm", group: "fan", deviceId: "one", subKey: "rpm", subLabel: "Front", prefix: "F1", displayValue: "800 RPM" }),
        metric({ id: "fan:one/percent", group: "fan", deviceId: "one", subKey: "percent", subLabel: "Front", displayValue: "40%" }),
        metric({ id: "cpu/core0", group: "cpu", subKey: "core", subLabel: "Core 1", displayValue: "10%" }),
        metric({ id: "cpu/core1", group: "cpu", subKey: "core", subLabel: "Core 2", displayValue: "20%" })
    ];
    const items = ViewHelpers.buildCompactItems(metrics, metrics.map(entry => entry.id), true);

    assert.deepEqual(Array.from(items[0].segments, segment => segment.label), ["F1", "Front"]);
    assert.deepEqual(Array.from(items[1].segments, segment => segment.label), ["Core 1", "Core 2"]);
});

test("syncCompactValues rejects segment structure changes", () => {
    const base = [{
        key: "net", label: "NET:", icon: "network-symbolic", hideSeparator: false,
        segments: [{ key: "down", label: "", icon: "download", value: "1", color: "white" }]
    }];
    const changedLength = [{ ...base[0], segments: [...base[0].segments, { key: "up" }] }];
    const changedKey = [{ ...base[0], segments: [{ ...base[0].segments[0], key: "up" }] }];
    assert.equal(ViewHelpers.syncCompactValues(base, changedLength), false);
    assert.equal(ViewHelpers.syncCompactValues(base, changedKey), false);
});

test("syncPopupGroups updates values and rejects structural changes", () => {
    const existing = [{
        key: "processor", groupLabel: "Processor", icon: "cpu-symbolic", aggregateValue: "10%", aggregateColor: "white",
        sections: [{ sectionLabel: "", metrics: [{ id: "cpu/usage", subLabel: "Usage", icon: "cpu-symbolic", displayValue: "10%", color: "white", isPinned: false }] }]
    }];
    const incoming = structuredClone(existing);
    incoming[0].aggregateValue = "20%";
    incoming[0].aggregateColor = "orange";
    incoming[0].sections[0].metrics[0].displayValue = "20%";
    incoming[0].sections[0].metrics[0].isPinned = true;

    assert.equal(ViewHelpers.syncPopupGroups(existing, incoming), true);
    assert.equal(existing[0].aggregateValue, "20%");
    assert.equal(existing[0].sections[0].metrics[0].isPinned, true);

    const wrongIcon = structuredClone(incoming);
    wrongIcon[0].icon = "other";
    assert.equal(ViewHelpers.syncPopupGroups(existing, wrongIcon), false);
    const wrongSection = structuredClone(incoming);
    wrongSection[0].sections[0].sectionLabel = "Changed";
    assert.equal(ViewHelpers.syncPopupGroups(existing, wrongSection), false);
});
