// ViewHelpers transforms the generic metrics list from MetricStore into
// view-specific presentation items. Neither CompactView nor FullView should
// contain grouping or ordering logic; that belongs here.
.pragma library

// buildCompactItems groups metrics by display order and returns a flat list of
// compact panel items. Each item is one of:
//   { icon, label, value, color, key }            - single-value row
//   { icon, label, segments, color, key }          - multi-value row (net, disk, fans)
//
// Multi-device groups (e.g. two GPUs) get one item per device. Single-device
// groups with multiple sub-metrics get a segments array.
function buildCompactItems(metricsList, orderedKeys) {
    if (!metricsList || metricsList.length === 0) return [];
    var visible = metricsList.filter(function(m) {
        return m.visibleInCompact && m.status === "ready";
    });

    var items = [];
    for (var i = 0; i < orderedKeys.length; i++) {
        var group = orderedKeys[i];
        var groupMetrics = visible.filter(function(m) { return m.group === group; });
        if (groupMetrics.length === 0) continue;

        var deviceIds = [];
        for (var d = 0; d < groupMetrics.length; d++) {
            var dev = groupMetrics[d].deviceId;
            if (dev && deviceIds.indexOf(dev) === -1) deviceIds.push(dev);
        }

        if (deviceIds.length > 1) {
            for (var di = 0; di < deviceIds.length; di++) {
                var devId = deviceIds[di];
                var devMetrics = groupMetrics.filter(function(m) { return m.deviceId === devId; });
                var devLabel = devMetrics[0].groupLabel || devMetrics[0].deviceName || group.toUpperCase();
                var devIcon = devMetrics[0].icon;
                var devColor = devMetrics[0].color;

                var segs = devMetrics.map(function(m) {
                    return { value: m.displayValue, color: m.color, key: m.subKey, label: m.subLabel };
                });

                var singlePfx = segs.length === 1 ? (devMetrics[0].subLabel || devMetrics[0].prefix || "") : "";
                var singleLbl = singlePfx ? (devLabel + " " + singlePfx) : devLabel;

                items.push({
                    icon: devIcon,
                    label: (segs.length > 1 ? devLabel : singleLbl) + ":",
                    segments: segs.length > 1 ? segs : null,
                    value: segs.length === 1 ? segs[0].value : null,
                    color: devColor,
                    key: group + ":" + devId
                });
            }
        } else if (group === "fan" && groupMetrics.length > 1) {
            var fanSegs = groupMetrics.map(function(m) {
                return { value: m.displayValue, color: m.color, key: m.id, label: m.subLabel };
            });
            items.push({
                icon: groupMetrics[0].icon,
                label: groupMetrics[0].groupLabel + ":",
                segments: fanSegs,
                color: groupMetrics[0].color,
                key: "fan"
            });
        } else {
            var gLabel = groupMetrics[0].groupLabel;
            var gIcon = groupMetrics[0].icon;
            var gColor = groupMetrics[0].color;

            if (groupMetrics.length === 1) {
                var singlePfx = groupMetrics[0].subLabel || groupMetrics[0].prefix || "";
                var singleLbl = singlePfx ? (gLabel + " " + singlePfx) : gLabel;
                items.push({
                    icon: gIcon,
                    label: singleLbl + ":",
                    value: groupMetrics[0].displayValue,
                    color: gColor,
                    key: group
                });
            } else {
                var gSegs = groupMetrics.map(function(m) {
                    return { value: m.displayValue, color: m.color, key: m.subKey, label: m.subLabel };
                });
                items.push({
                    icon: gIcon,
                    label: gLabel + ":",
                    segments: gSegs,
                    color: gColor,
                    key: group
                });
            }
        }
    }
    return items;
}

// buildPopupItems returns one row per visible metric in order. Each item is:
//   { label, value, color, icon, chartKey, chartMax }
// icon may be a string or a two-element array when a secondary icon is present.
function buildPopupItems(metricsList, orderedKeys) {
    if (!metricsList || metricsList.length === 0) return [];
    var visible = metricsList.filter(function(m) {
        return m.visibleInPopup && m.status === "ready";
    });

    var items = [];
    for (var i = 0; i < orderedKeys.length; i++) {
        var group = orderedKeys[i];
        var groupMetrics = visible.filter(function(m) { return m.group === group; });
        for (var j = 0; j < groupMetrics.length; j++) {
            var m = groupMetrics[j];
            var icons = [m.icon];
            if (m.secondaryIcon) icons.push(m.secondaryIcon);
            items.push({
                label: m.label,
                value: m.popupDisplay || m.displayValue,
                color: m.color,
                icon: icons.length > 1 ? icons : m.icon,
                chartKey: m.chartKey,
                chartMax: m.chartMax
            });
        }
    }
    return items;
}
