.pragma library

var DEFAULT_PINNED_METRICS = "cpu/usage,ram/percentage,temp/system,bat/percentage,net/down,net/up";
var DEFAULT_METRIC_ORDER = "cpu,ram,swap,temp,gpu,bat,net,disk,fan,uptime";
var DISABLED_SELECTION = "none";

function parseCsv(value) {
    if (!value) return [];
    return String(value).split(",").map(function(item) {
        return item.trim();
    }).filter(function(item) {
        return item.length > 0;
    });
}

function parseJsonMap(value) {
    if (!value) return {};
    if (typeof value === "object") return value;

    var trimmed = String(value).trim();
    if (trimmed.charAt(0) === "{") {
        try {
            var parsed = JSON.parse(trimmed);
            return parsed && typeof parsed === "object" && !Array.isArray(parsed) ? parsed : {};
        } catch (e) {
            // Fall through to the legacy key:value|key:value representation.
        }
    }

    var result = {};
    trimmed.split("|").forEach(function(pair) {
        var separator = pair.indexOf(":");
        if (separator > 0) {
            result[pair.substring(0, separator).trim()] = pair.substring(separator + 1).trim();
        }
    });
    return result;
}

function setCsvMembership(serialized, item, shouldInclude, fallbackCsv) {
    if (!item) return serialized || fallbackCsv || "";
    var source = serialized || fallbackCsv || "";
    var items = parseCsv(source);
    var index = items.indexOf(item);
    if (shouldInclude && index < 0) items.push(item);
    if (!shouldInclude && index >= 0) items.splice(index, 1);
    return items.join(",");
}

function toggleCsvMembership(serialized, item, fallbackCsv) {
    var items = parseCsv(serialized || fallbackCsv || "");
    return setCsvMembership(serialized, item, items.indexOf(item) < 0, fallbackCsv);
}

function moveCsvItem(serialized, fromIndex, toIndex, fallbackCsv) {
    var items = parseCsv(serialized || fallbackCsv || "");
    if (fromIndex < 0 || fromIndex >= items.length || toIndex < 0 || toIndex >= items.length) {
        return items.join(",");
    }
    var item = items.splice(fromIndex, 1)[0];
    items.splice(toIndex, 0, item);
    return items.join(",");
}

function normalizeOrder(serialized, allowedKeys, fallbackCsv) {
    var allowed = allowedKeys || [];
    var requested = parseCsv(serialized || fallbackCsv || "");
    var result = [];
    for (var i = 0; i < requested.length; i++) {
        if (allowed.indexOf(requested[i]) >= 0 && result.indexOf(requested[i]) < 0) {
            result.push(requested[i]);
        }
    }
    for (var j = 0; j < allowed.length; j++) {
        if (result.indexOf(allowed[j]) < 0) result.push(allowed[j]);
    }
    return result;
}

function isSelectionEnabled(serialized, item) {
    if (serialized === DISABLED_SELECTION) return false;
    if (!serialized) return true;
    return parseCsv(serialized).indexOf(item) >= 0;
}

function updateSelection(serialized, item, enabled, discoveredItems) {
    var current;
    if (serialized === DISABLED_SELECTION) {
        current = [];
    } else if (!serialized) {
        current = (discoveredItems || []).slice();
    } else {
        current = parseCsv(serialized);
    }

    var index = current.indexOf(item);
    if (enabled && index < 0) current.push(item);
    if (!enabled && index >= 0) current.splice(index, 1);
    return current.length === 0 ? DISABLED_SELECTION : current.join(",");
}
