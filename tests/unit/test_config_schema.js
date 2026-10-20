import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync, existsSync, readdirSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));

test("main.xml is well-formed KConfigXT schema with valid types and unique entries", () => {
    const xmlPath = resolve(__dirname, "../../contents/config/main.xml");
    assert.ok(existsSync(xmlPath), "main.xml must exist");

    const content = readFileSync(xmlPath, "utf8");

    assert.ok(/<kcfg\b/.test(content), "Must have <kcfg> root element");
    assert.ok(/<\/kcfg>/.test(content), "Must close </kcfg>");

    const entryRegex = /<entry\s+name="([^"]+)"\s+type="([^"]+)"\s*>([\s\S]*?)<\/entry>/g;
    const names = new Set();
    const validTypes = new Set(["Bool", "Int", "UInt", "Double", "String", "StringList", "Color", "Font", "Path"]);

    let match;
    let count = 0;

    while ((match = entryRegex.exec(content)) !== null) {
        count++;
        const name = match[1];
        const type = match[2];
        const body = match[3];

        assert.ok(!names.has(name), `Duplicate entry name found: ${name}`);
        names.add(name);

        assert.ok(validTypes.has(type), `Invalid type '${type}' for entry '${name}'`);

        assert.ok(/<default>[\s\S]*?<\/default>/.test(body), `Entry '${name}' must have a <default> tag`);
    }

    assert.ok(count > 10, `Expected multiple configuration entries, found ${count}`);

    const requiredKeys = [
        "pinnedMetrics",
        "cpuEnabled",
        "ramEnabled",
        "gpuEnabled",
        "netEnabled",
        "diskEnabled",
        "updateInterval",
        "profileList",
        "activeProfileId"
    ];

    for (const key of requiredKeys) {
        assert.ok(names.has(key), `Required configuration key '${key}' missing from main.xml`);
    }
});

test("every configuration property referenced by QML exists in main.xml", () => {
    const projectRoot = resolve(__dirname, "../..");
    const schema = readFileSync(resolve(projectRoot, "contents/config/main.xml"), "utf8");
    const schemaNames = new Set([...schema.matchAll(/<entry\s+name="([^"]+)"/g)].map(match => match[1]));
    const referencedNames = new Set();
    const configurationApiMembers = new Set(["valueChanged"]);

    const visit = directory => {
        for (const entry of readdirSync(directory, { withFileTypes: true })) {
            const path = resolve(directory, entry.name);
            if (entry.isDirectory()) {
                visit(path);
                continue;
            }
            if (!entry.name.endsWith(".qml")) continue;
            const source = readFileSync(path, "utf8");
            for (const match of source.matchAll(/\bcfg_([A-Za-z][A-Za-z0-9_]*)\b/g)) referencedNames.add(match[1]);
            for (const match of source.matchAll(/\bPlasmoid\.configuration\.([A-Za-z][A-Za-z0-9_]*)\b/g)) {
                if (!configurationApiMembers.has(match[1])) referencedNames.add(match[1]);
            }
        }
    };
    visit(resolve(projectRoot, "contents"));

    for (const name of referencedNames) {
        assert.equal(schemaNames.has(name), true, `QML references configuration key '${name}' missing from main.xml`);
    }
});
