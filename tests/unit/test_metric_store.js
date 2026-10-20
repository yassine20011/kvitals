import test from "node:test";
import assert from "node:assert/strict";
import { loadQmlLibrary } from "../helpers.js";
import { COLORS } from "../fixtures.js";

const MetricLogic = loadQmlLibrary("contents/ui/models/MetricLogic.js");

test("metric values accept only finite numbers", () => {
    assert.equal(MetricLogic.normalizeValue(42), 42);
    for (const invalid of [NaN, Infinity, -Infinity, "42", null, undefined]) {
        assert.equal(Number.isNaN(MetricLogic.normalizeValue(invalid)), true);
    }
});

test("metric strings normalize primitives without losing a supplied fallback", () => {
    assert.equal(MetricLogic.normalizeString("ready", "fallback"), "ready");
    assert.equal(MetricLogic.normalizeString(123, "fallback"), "123");
    assert.equal(MetricLogic.normalizeString(null, "fallback"), "fallback");
    assert.equal(MetricLogic.normalizeString(undefined, ""), "");
});

test("normal thresholds use inclusive warning and critical boundaries", () => {
    const color = value => MetricLogic.resolveThresholdColor(
        value, 70, 90, COLORS.warning, COLORS.critical, COLORS.base, false
    );
    assert.equal(color(69.9), COLORS.base);
    assert.equal(color(70), COLORS.warning);
    assert.equal(color(89.9), COLORS.warning);
    assert.equal(color(90), COLORS.critical);
    assert.equal(color(NaN), COLORS.base);
});

test("inverted thresholds color low battery values", () => {
    const color = value => MetricLogic.resolveThresholdColor(
        value, 30, 15, COLORS.warning, COLORS.critical, COLORS.base, true
    );
    assert.equal(color(31), COLORS.base);
    assert.equal(color(30), COLORS.warning);
    assert.equal(color(15), COLORS.critical);
});
