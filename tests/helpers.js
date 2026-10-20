import { readFileSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { createContext, runInContext } from "node:vm";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));

export function loadQmlLibrary(relPath) {
    const fullPath = resolve(__dirname, "..", relPath);
    let code = readFileSync(fullPath, "utf8");
    code = code.replace(/^\s*\.pragma\s+library\s*/m, "");
    const sandbox = {
        i18n: (s, ...args) => {
            let res = s;
            for (let i = 0; i < args.length; i++) {
                res = res.replace("%" + (i + 1), args[i]);
            }
            return res;
        }
    };
    createContext(sandbox);
    runInContext(code, sandbox, { filename: fullPath });
    return sandbox;
}

export function readProjectFile(relPath) {
    return readFileSync(resolve(__dirname, "..", relPath), "utf8");
}
