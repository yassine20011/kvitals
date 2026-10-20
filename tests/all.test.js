import { readdirSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const testRoot = dirname(fileURLToPath(import.meta.url));
const files = [resolve(testRoot, "test_regressions.js")];
files.push(...readdirSync(resolve(testRoot, "unit"))
    .filter(name => name.startsWith("test_") && name.endsWith(".js"))
    .sort()
    .map(name => resolve(testRoot, "unit", name)));

for (const file of files) await import(pathToFileURL(file));
