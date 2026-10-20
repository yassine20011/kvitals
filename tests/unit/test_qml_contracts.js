import test from "node:test";
import assert from "node:assert/strict";
import { existsSync, readdirSync, statSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { loadQmlLibrary, readProjectFile } from "../helpers.js";

const testDir = dirname(fileURLToPath(import.meta.url));
const projectRoot = resolve(testDir, "../..");
const Config = loadQmlLibrary("contents/ui/models/ConfigLogic.js");

function filesBelow(relativeRoot, extension) {
    const result = [];
    const visit = directory => {
        for (const entry of readdirSync(directory, { withFileTypes: true })) {
            const fullPath = resolve(directory, entry.name);
            if (entry.isDirectory()) visit(fullPath);
            else if (entry.name.endsWith(extension)) result.push(fullPath);
        }
    };
    visit(resolve(projectRoot, relativeRoot));
    return result;
}

test("every relative QML JavaScript import resolves", () => {
    for (const qmlPath of filesBelow("contents", ".qml")) {
        const source = readProjectFile(qmlPath.slice(projectRoot.length + 1));
        for (const match of source.matchAll(/^\s*import\s+["']([^"']+)["']\s+as\s+\w+/gm)) {
            const importedPath = resolve(dirname(qmlPath), match[1]);
            assert.equal(existsSync(importedPath) && statSync(importedPath).isFile(), true, "missing import " + match[1] + " from " + qmlPath);
        }
    }
});

test("QML adapters are wired to the production logic covered by unit tests", () => {
    const wiring = [
        ["contents/ui/models/MetricConfig.qml", "ConfigLogic", ["parseCsv", "parseJsonMap", "normalizeOrder"]],
        ["contents/ui/configPanelOrder.qml", "ConfigLogic", ["parseCsv", "toggleCsvMembership", "moveCsvItem"]],
        ["contents/ui/models/MetricStore.qml", "MetricLogic", ["normalizeValue", "resolveThresholdColor"]],
        ["contents/ui/models/HardwareDiscovery.qml", "HardwareInventoryLogic", ["buildInventory"]],
        ["contents/ui/models/ProfileManager.qml", "ProfileLogic", ["validateProfiles", "serializeProfiles"]],
        ["contents/ui/sensors/DiskSensors.qml", "DiskSensorLogic", ["parseSysfsOutput", "resolveTemperatureSensor"]],
        ["contents/ui/main.qml", "ShortcutLogic", ["initializeShortcut", "shortcutAfterGlobalChange"]]
    ];

    for (const [path, namespace, functions] of wiring) {
        const source = readProjectFile(path);
        assert.match(source, new RegExp("import\\s+[\"'][^\"']+[\"']\\s+as\\s+" + namespace));
        for (const functionName of functions) assert.match(source, new RegExp(namespace + "\\." + functionName + "\\("));
    }
});

test("central config defaults agree with the KConfig schema", () => {
    const schema = readProjectFile("contents/config/main.xml");
    const defaultFor = name => {
        const match = schema.match(new RegExp("<entry\\s+name=[\"']" + name + "[\"'][^>]*>[\\s\\S]*?<default>([\\s\\S]*?)<\\/default>"));
        return match ? match[1].trim() : undefined;
    };

    assert.equal(Config.DEFAULT_PINNED_METRICS, defaultFor("pinnedMetrics"));
    assert.equal(Config.DEFAULT_METRIC_ORDER, defaultFor("metricOrder"));
});

test("test files do not reimplement extracted production algorithms", () => {
    const forbiddenDefinitions = [
        "parseSysfsOutput",
        "createHardwareInventory",
        "validateProfiles",
        "resolveColor",
        "normalizeValue",
        "simulateInit"
    ];
    for (const testPath of filesBelow("tests", ".js")) {
        if (testPath.endsWith("test_qml_contracts.js")) continue;
        const source = readProjectFile(testPath.slice(projectRoot.length + 1));
        for (const name of forbiddenDefinitions) {
            assert.doesNotMatch(source, new RegExp("function\\s+" + name + "\\s*\\("), testPath + " duplicates " + name);
        }
    }
});
