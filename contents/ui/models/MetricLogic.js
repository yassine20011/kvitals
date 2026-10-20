.pragma library

function normalizeValue(value) {
    return typeof value === "number" && isFinite(value) && !isNaN(value) ? value : NaN;
}

function normalizeString(value, fallback) {
    if (typeof value === "string") return value;
    if (value !== undefined && value !== null) return String(value);
    return fallback || "";
}

function resolveThresholdColor(value, warning, critical, warningColor, criticalColor, baseColor, inverted) {
    if (typeof value !== "number" || !isFinite(value) || isNaN(value)) return baseColor;
    if (inverted) {
        if (value <= critical) return criticalColor;
        if (value <= warning) return warningColor;
        return baseColor;
    }
    if (value >= critical) return criticalColor;
    if (value >= warning) return warningColor;
    return baseColor;
}
