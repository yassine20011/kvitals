import test from "node:test";
import assert from "node:assert/strict";
import { existsSync, readdirSync } from "node:fs";
import { resolve } from "node:path";
import { readProjectFile } from "../helpers.js";

const projectRoot = resolve(import.meta.dirname, "../..");

test("metadata declares a valid Plasma 6 applet", () => {
    const metadata = JSON.parse(readProjectFile("metadata.json"));
    assert.equal(metadata.KPackageStructure, "Plasma/Applet");
    assert.match(metadata["X-Plasma-API-Minimum-Version"], /^6(?:\.|$)/);
    assert.match(metadata.KPlugin.Id, /^[a-z0-9]+(?:\.[a-z0-9]+)+$/);
    assert.match(metadata.KPlugin.Version, /^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$/);
    for (const key of ["Name", "Description", "License", "Version"]) {
        assert.equal(typeof metadata.KPlugin[key], "string");
        assert.notEqual(metadata.KPlugin[key].trim(), "");
    }
});

test("every configured page and sensor module points to an existing QML file", () => {
    const configModel = readProjectFile("contents/config/config.qml");
    const configSources = [...configModel.matchAll(/source:\s*["']([^"']+)["']/g)].map(match => match[1]);
    assert.ok(configSources.length > 0);
    for (const source of configSources) {
        assert.equal(existsSync(resolve(projectRoot, "contents/ui", source)), true, `missing config page: ${source}`);
    }

    const qmldir = readProjectFile("contents/ui/sensors/qmldir");
    const moduleFiles = qmldir.split(/\r?\n/)
        .map(line => line.trim().split(/\s+/).at(-1))
        .filter(name => name && name.endsWith(".qml"));
    for (const source of moduleFiles) {
        assert.equal(existsSync(resolve(projectRoot, "contents/ui/sensors", source)), true, `missing sensor module: ${source}`);
    }
});

test("all bundled icon references resolve to shipped SVG files", () => {
    const definitions = readProjectFile("contents/ui/models/MetricDefinitions.js");
    const referenced = new Set([...definitions.matchAll(/["']([a-z0-9-]+-symbolic)["']/g)].map(match => match[1]));
    const shipped = new Set(readdirSync(resolve(projectRoot, "contents/icons"), { withFileTypes: true })
        .filter(entry => entry.isFile() && entry.name.endsWith(".svg"))
        .map(entry => entry.name.replace(/\.svg$/, "")));

    for (const icon of referenced) {
        assert.equal(shipped.has(icon), true, `missing bundled icon: ${icon}`);
    }
});

test("package script includes all runtime roots", () => {
    const script = readProjectFile("package.sh");
    for (const required of ["metadata.json", "contents", "LICENSE"]) {
        assert.match(script, new RegExp(`\\b${required.replace(".", "\\.")}\\b`));
    }
});
