# Architecture

KVitals is a KDE Plasma 6 widget (plasmoid) built around a data-driven metric pipeline. Sensor components feed raw values into a central store, which produces a flat list of typed metric objects. The views consume that list without knowing anything about sensor internals.

## Data flow

![KVitals Data Flow](dataflow-dark.svg#only-dark){ width="100%" }
![KVitals Data Flow](dataflow-light.svg#only-light){ width="100%" }

## Hardware discovery (`contents/ui/models/HardwareDiscovery.qml`)

KVitals separates hardware discovery from sensor interpretation:

- **Hardware discovery**: What devices and sensor nodes exist on this system.
- **Sensor interpretation**: What a sensor reading means, how it is polled, filtered, and formatted.

`HardwareDiscovery.qml` maintains exactly **one** `SensorTreeModel` and `KDescendantsProxyModel` per active QML context (one in the runtime widget, one while the configuration dialog is open). It listens to topology changes (`rowsInserted`, `rowsRemoved`, `modelReset`), debounces updates (350ms), and exposes a minimal generic query API:

- `count`: Total number of registered sensors.
- `revision`: Reactive counter incremented when hardware topology changes.
- `allSensorIds`: Array of all discovered sensor ID strings.
- `discoveredGpus`, `discoveredDisks`, `discoveredFans`, `discoveredCores`, `discoveredNetworkIfaces`: Pre-indexed typed device arrays populated in a single pass.
- `query(pattern)`: Returns array of matching `{ id, name }` objects (memoized in $O(1)$).
- `queryIds(pattern)`: Returns array of matching sensor ID strings (memoized in $O(1)$).
- `sensorExists(id)`: Fast $O(1)$ hash map check.
- `rescan()`: Public hook to trigger an immediate topology refresh.

## Sensor modules (`contents/ui/sensors/`)

Each metric category has its own QML component. Components receive the shared `HardwareDiscovery` instance, query their relevant sensor IDs, and own all value polling, calculations, and domain heuristics.

| Module | Discovery query | Key exposed properties |
|---|---|---|
| `CpuSensors.qml` | Static + `PATTERNS.CPU_CORE` (`discovery.discoveredCores`) | `cpuValue`, `cpuNumericValue`, `cpuFreqValue`, `cpuLoad1Value`, `coreDataList` |
| `MemorySensors.qml` | Static (`memory/physical/used`, `total`) | `ramValue`, `ramPercentValue`, `ramPercentage` |
| `SwapSensors.qml` | Static (`memory/swap/used`, `total`) | `swapPercentValue`, `swapUsedValue`, `swapFreeValue` |
| `TempSensors.qml` | `PATTERNS.TEMP_LMSENSORS` + ISA Super I/O / SPD5118 filtering | `tempValue`, `cpuTempValue`, `ramTempValue`, `ramTempExists` |
| `GpuSensors.qml` | `discovery.discoveredGpus` | `gpuDataList`, `discoveredGpus` |
| `BatterySensors.qml` | `PATTERNS.BATTERY` + probe/qdbus fallback | `batValue`, `batNumericValue`, `powerValue`, `batHealthValue` |
| `NetworkSensors.qml` | `discovery.discoveredNetworkIfaces` + Wi-Fi signal detection | `netDownValue`, `netUpValue`, `netTotalDownValue`, `netTotalUpValue`, `netSignalValue`, `netIpValue` |
| `DiskSensors.qml` | `discovery.discoveredDisks` + Solid hotplug filter | `diskReadValue`, `diskWriteValue`, `diskDataList` |
| `FanSensors.qml` | `discovery.discoveredFans` | `fanDataList`, `hasFanData` |
| `UptimeSensors.qml` | Static (`os/system/uptime`) | `uptimeValue` |

`Utils.qml` is a singleton providing formatting helpers (`formatBytes`, `formatData`, `formatRate`, `resolveColor`) used by sensor components.

### Performance properties

- Exactly one `SensorTreeModel` active at runtime across the entire widget.
- No subprocesses during normal execution.
- Reads from the same ksystemstats backend as the official KDE System Monitor.
- Disabling a sensor group stops all its subscriptions immediately.

## Models layer (`contents/ui/models/`)

This layer sits between sensors and views and is where metric aggregation lives.

### `MetricDefinitions.js`

A `.pragma library` file (shared singleton) holding:

- `GROUPS`: Metadata per category (id, default label, icon, default sub-metrics).
- `PATTERNS`: Canonical discovery regex patterns (`GPU`, `DISK_READ`, `DISK_TEMP`, `FAN`, `NETWORK_IFACE`, `TEMP_LMSENSORS`, `BATTERY`).
- `DEFINITIONS`: One entry per metric keyed by `"group.subKey"`. Each entry declares the sensor path, chart settings, threshold type/key, and direction prefix. `MetricStore._createMetric` merges these definitions with runtime overrides from the sensor layer.

### `MetricConfig.qml`

A `QtObject` that wraps every `Plasmoid.configuration` value and provides typed accessors used by both sensor components and `MetricStore`. Nothing outside this file reads `Plasmoid.configuration` directly. It owns:

- Group enable flags and `isGroupEnabled(group)`
- Sub-metric selection per group and `isSubMetricEnabled(group, subKey)`
- Visibility target per group (`"compact"`, `"widget"`, `"both"`) and `isMetricVisible(group, subKey, view)`
- Labels, icons, and threshold values with fallback defaults
- `orderedKeys`: The final display order, filled from the user's `metricOrder` setting with any missing groups appended from `MetricDefinitions.ALL_GROUP_KEYS`.

### `MetricStore.qml`

The central aggregator. On every sensor change it recomputes `metrics`, a `readonly` property holding a flat array of metric objects conforming to the Metric Contract.

`MetricStore` also manages `chartHistory`, a ring buffer (up to 60 samples) per `chartKey`, written by `chartTimer` at `updateInterval` ms.

## Metric Contract

`MetricStore` serves as the normalization boundary between sensor modules and generic views:

```
Sensor QML Modules
    ↓
normalized metric
    ↓
MetricStore
    ↓
generic presentation (ViewHelpers / CompactView / FullView)
```

KVitals supports arbitrary metric sources as long as sensor modules normalize their data into the Metric Contract. Sensor components convert backend-specific structures (D-Bus objects, sysfs strings, boolean flags, or structured records) into numeric values or display strings before passing them to `MetricStore`:

```
D-Bus object / sysfs string / boolean state / structured backend value
    ↓
sensor-specific interpretation (polling, calculations, formatting)
    ↓
number or display string
    ↓
MetricStore (_createMetric normalization)
```

### Supported Metric Categories

Every metric emitted by `MetricStore` falls into one of two categories:

#### 1. Quantitative Metric
Represents a scalar numeric measurement (percentages, rates, temperatures, frequencies, capacity, RPM, power).

- `value`: Finite numeric scalar (`typeof value === "number" && isFinite(value)`). Set to `NaN` when temporarily loading or unavailable.
- `displayValue`: Formatted string (e.g. `" 42%"`, `"55°C"`, `"16.4/32.0G"`).
- `status`: `"ready"`, `"loading"`, or `"unavailable"`.
- `hasChart`: `true` if `chartKey` is configured.
- `chartKey`: Buffer identifier in `chartHistory`.
- `chartMax`: Upper bound for chart scaling (`0` for auto-scale).
- Thresholds: Warning and critical thresholds evaluate only against finite numeric values.

MetricStore accepts finite numeric scalars, including negative values. Whether negative values are meaningful depends on the metric's domain semantics (such as battery charge/discharge rates, energy flow, or temperature deltas); sensor modules and metric definitions determine the appropriate interpretation.

#### 2. Display-Only Metric
Represents discrete text data without scalar telemetry (IP addresses, uptime strings).

- `value`: `NaN` (explicit sentinel).
- `displayValue`: Formatted string (e.g. `"192.168.1.10"`, `"2d 4h 12m"`).
- `status`: `"ready"`, `"loading"`, or `"unavailable"`.
- `hasChart`: `false` (`chartKey: ""`).
- Thresholds: Not evaluated; retains base text color.
- Chart history: Never enters `chartHistory`.

### Normalization Rules

`MetricStore._createMetric` enforces these normalization guarantees:

1. **Finite number**: Preserved as the quantitative `value` (including negative numbers).
2. **NaN**: Preserved as the non-quantitative or unavailable sentinel.
3. **Infinity / -Infinity**: Normalized to `NaN`.
4. **null / undefined**: Normalized to `NaN` (prevents coercion to 0).
5. **boolean**: Normalized to `NaN` (prevents coercion to 0 or 1).
6. **objects / arrays**: Normalized to `NaN`.
7. **numeric strings**: Strings are never coerced into quantitative numbers; they are rejected to `NaN`.
8. **displayValue**: Always normalized to a `string`.

### Developer Examples

#### Example 1: Quantitative Metric (Swap Usage)

1. **MetricDefinitions.js**:
```javascript
"swap.usage": {
    id: "swap.usage",
    group: "ram",
    subKey: "swap",
    sensorId: "memory/swap/used",
    label: "Swap Usage",
    chartKey: "swap",
    chartMax: 100,
    thresholdType: "normal",
    thresholdKey: "ram"
}
```

2. **Sensor module (`MemorySensors.qml`)**:
```qml
Sensors.Sensor {
    id: swapUsedSensor
    sensorId: "memory/swap/used"
    updateRateLimit: root.updateInterval
}
Sensors.Sensor {
    id: swapTotalSensor
    sensorId: "memory/swap/total"
    updateRateLimit: root.updateInterval
}

readonly property real swapPercentage: {
    if (swapUsedSensor.status !== Sensors.Sensor.Ready || swapTotalSensor.status !== Sensors.Sensor.Ready)
        return NaN;
    if (swapTotalSensor.value <= 0) return NaN;
    return (swapUsedSensor.value / swapTotalSensor.value) * 100;
}

readonly property string swapValue: {
    if (isNaN(swapPercentage)) return "...";
    return Math.round(swapPercentage) + "%";
}
```

3. **MetricStore integration (`MetricStore.qml`)**:
```qml
list.push(_createMetric("swap.usage", {
    value: s.memory.swapPercentage,
    displayValue: s.memory.swapValue,
    status: !isNaN(s.memory.swapPercentage) ? "ready" : "loading"
}));
```

4. **Normalized metric object in `MetricStore.metrics`**:
```javascript
{
    id: "swap.usage",
    defId: "swap.usage",
    group: "ram",
    subKey: "swap",
    label: "RAM Swap Usage",
    groupLabel: "RAM",
    subLabel: "",
    prefix: "",
    icon: "nvidia-ram-symbolic",
    secondaryIcon: "",
    value: 24.5,
    displayValue: "25%",
    popupDisplay: "25%",
    rawString: "25%",
    color: "#ffffff",
    status: "ready",
    chartKey: "swap",
    chartMax: 100,
    hasChart: true,
    visibleInCompact: true,
    visibleInPopup: true
}
```

#### Example 2: Display-Only Metric (Local IP)

1. **MetricDefinitions.js**:
```javascript
"net.ip": {
    id: "net.ip",
    group: "net",
    subKey: "ip",
    sensorPattern: "network/{id}/ipv4withPrefixLength",
    label: "Local IP",
    chartKey: "",
    chartMax: 0,
    thresholdType: "none"
}
```

2. **Sensor module (`NetworkSensors.qml`)**:
```qml
readonly property string netIpValue: {
    if (netIpSensor.status !== Sensors.Sensor.Ready) return "...";
    var v = netIpSensor.value || "";
    var slash = v.indexOf("/");
    return slash >= 0 ? v.substring(0, slash) : v;
}
```

3. **MetricStore integration (`MetricStore.qml`)**:
```qml
list.push(_createMetric("net.ip", {
    displayValue: s.network.netIpValue,
    status: "ready"
}));
```

4. **Normalized metric object in `MetricStore.metrics`**:
```javascript
{
    id: "net.ip",
    defId: "net.ip",
    group: "net",
    subKey: "ip",
    label: "NET Local IP",
    groupLabel: "NET",
    subLabel: "",
    prefix: "",
    icon: "network-wireless",
    secondaryIcon: "",
    value: NaN,
    displayValue: "192.168.1.10",
    popupDisplay: "192.168.1.10",
    rawString: "192.168.1.10",
    color: "#ffffff",
    status: "ready",
    chartKey: "",
    chartMax: 0,
    hasChart: false,
    visibleInCompact: false,
    visibleInPopup: true
}
```

### Architectural Roles

- **HardwareDiscovery**: *"What sensors exist?"* (topology and IDs)
- **Sensor modules**: *"What does this sensor mean?"* (polling, calculations, and domain formatting)
- **MetricStore**: *"How do I normalize and expose this metric?"* (contract enforcement, thresholds, chart history)
- **ViewHelpers / Views**: *"How do I present the metric?"* (generic layout and presentation)

### `ViewHelpers.js`

A `.pragma library` file with two functions:

- `buildCompactItems(metricsList, orderedKeys)`: groups and orders metrics into compact panel items. Items are either `{ icon, label, value, color, key }` (single value) or `{ icon, label, segments, color, key }` (multi-value, used for net, disk, multi-fan).
- `buildPopupItems(metricsList, orderedKeys)`: returns one row per visible popup metric: `{ label, value, color, icon, chartKey, chartMax }`. `icon` may be a two-element array when a secondary icon is present.

## Views

### CompactView (panel)

A `RowLayout` with a `Repeater` driven by `buildCompactItems`. Each item renders as:

- Icon (`Kirigami.Icon` with `isMask: true` to match panel text color)
- Label (e.g. `NET ↓:`)
- Value (e.g. `82.2 KB/s`)
- Separator (`|` between groups)

`displayMode` controls icon/label/text visibility. `layoutType` switches between horizontal and vertical delegates.

### FullView (popup)

A `ColumnLayout` with a `Repeater` driven by `buildPopupItems`. Each row shows a label, a bold value, and an optional sparkline chart drawn from `MetricStore.chartHistory`.

### Tooltip

A static `"KVitals"` title only. Metrics are not duplicated into the tooltip.

## Configuration system

```
config/main.xml          <- config schema (keys, types, defaults)
config/config.qml        <- tab registration
ui/configGeneral.qml     <- display mode, layout, font, interval, units
ui/configMetrics.qml     <- enable/disable, visibility, order, grouping, overrides
ui/configIcons.qml       <- per-metric icon picker
ui/configColors.qml      <- font color, warning/critical colors, thresholds
```

All values flow through `MetricConfig.qml`. Nothing in the sensor or view layer reads `Plasmoid.configuration` directly.

## Adding new metrics or hardware categories

The data pipeline separates hardware polling, metric definitions, configuration, and presentation. How you add telemetry depends on whether you are extending an existing hardware category or introducing an entirely new one.

### Workflow A: Adding a sub-metric to an existing group

This is the standard workflow for adding new readings to an existing module (such as adding Swap to Memory, Power to Battery, or VRAM to GPU).

For optional sub-metrics (disabled by default until selected by the user in settings), you do not need to modify `HardwareDiscovery.qml`, `sensors/qmldir`, `main.qml`, `MetricConfig.qml`, or the view components (`CompactView.qml`, `FullView.qml`).

1. **Register in `MetricDefinitions.js` (`contents/ui/models/MetricDefinitions.js`)**:
   Add a definition object under `DEFINITIONS["<group>.<subKey>"]`:
   ```javascript
   "ram.swap": {
       id: "ram.swap",
       group: "ram",
       subKey: "swap",
       sensorId: "memory/swap/used",
       label: "Swap Usage",
       chartKey: "swap",
       chartMax: 100,
       thresholdType: "normal",
       thresholdKey: "ram"
   }
   ```

2. **Poll and format in the sensor module (`contents/ui/sensors/<Group>Sensors.qml`)**:
   Subscribe to the required sensor path (via `Sensors.Sensor` or `Sensors.SensorDataModel`) and expose reactive value properties (a numeric scalar and/or formatted string):
   ```qml
   readonly property real swapPercentage: ...
   readonly property string swapValue: ...
   ```

3. **Aggregate in `MetricStore.qml` (`contents/ui/models/MetricStore.qml`)**:
   In the `metrics` property getter, push the normalized metric into the list using `_createMetric`:
   ```qml
   list.push(_createMetric("ram.swap", {
       value: s.memory.swapPercentage,
       displayValue: s.memory.swapValue,
       status: !isNaN(s.memory.swapPercentage) ? "ready" : "loading"
   }));
   ```
   `_createMetric` automatically verifies the Metric Contract, checks visibility via `MetricConfig.isMetricVisible()`, resolves threshold colors, and handles sparkline history buffering.

4. **Add UI toggle in `configMetrics.qml` (`contents/ui/configMetrics.qml`)**:
   Add the sub-metric entry to `metricMeta[group].subs`:
   ```javascript
   { key: "swap", label: i18n("Swap") }
   ```
   The configuration page dynamically creates the toggle checkbox and serializes the choice to `cfg_<group>SubMetrics`.

5. **(Optional) Enable by default for new installations**:
   If the new sub-metric should be enabled out of the box on fresh installations:
   - Add the key to `GROUPS[group].defaultSubMetrics` in `contents/ui/models/MetricDefinitions.js` (which serves as the source of truth for `MetricConfig.qml` and `configMetrics.qml`).
   - Update the static `<default>` value for `<group>SubMetrics` in `contents/config/main.xml` (required by KDE's KConfig schema).

Views remain sensor-agnostic. `ViewHelpers.js` groups and routes the metric to `CompactView` and `FullView` automatically.

---

### Workflow B: Adding a new hardware category / sensor module

Adding an entirely new category (such as NPU or Liquid Cooler) requires creating a dedicated sensor module and registering it across the architecture layers.

`HardwareDiscovery.qml` is generic and maintains a single `SensorTreeModel` query cache for the entire widget. You do not need to modify `HardwareDiscovery.qml` unless you need a new generic topology query method.

1. **Sensor layer (`contents/ui/sensors/`)**:
   - Create `contents/ui/sensors/NewSensors.qml`. Accept the shared `discovery` property, query required sensors, and expose clean numeric and string properties.
   - Register the new component in `contents/ui/sensors/qmldir`:
     ```
     NewSensors 1.0 NewSensors.qml
     ```
   - In `contents/ui/main.qml`, instantiate `NewSensors` inside the `sensorLoader.sourceComponent` Item and expose an alias:
     ```qml
     property alias newGroup: _newGroup
     NewSensors {
         id: _newGroup
         discovery: _discovery
         updateInterval: metricConfig.updateInterval
     }
     ```

2. **Catalog and models layer (`contents/ui/models/`)**:
   - In `MetricDefinitions.js`:
     - Add group metadata to `GROUPS` (id, defaultLabel, defaultIcon, defaultSubMetrics).
     - Add group ID to `ALL_GROUP_KEYS`.
     - If the hardware relies on dynamic discovery patterns, add regex to `PATTERNS`.
     - Add metric definitions to `DEFINITIONS`.
   - In `contents/config/main.xml`:
     - Add entries for `<group>Enabled`, `<group>SubMetrics`, `<group>Visibility`, `<group>Label`, `<group>Icon`, and optional thresholds.
   - In `MetricConfig.qml`:
     - Expose typed configuration properties: `readonly property bool newGroupEnabled: Plasmoid.configuration.newGroupEnabled`, etc.
     - Add cases to `isGroupEnabled()`, `getGroupVisibility()`, `isSubMetricEnabled()`, `getGroupLabel()`, and `getGroupIcon()`.
   - In `MetricStore.qml`:
     - Add a block in `metrics` pushing `_createMetric("<group>.<subKey>", { ... })` objects.

3. **Configuration UI layer (`contents/ui/`)**:
   - In `configMetrics.qml`:
     - Add `cfg_<group>*` properties.
     - Add group ID to `allKeys`.
     - Add category definition to `metricMeta`.
     - Add switch cases to `iconFor()`, `subMetrics()`, `isEnabled()`, `setEnabled()`, `visibilityFor()`, `setVisibility()`, and `toggleSubMetric()`.
   - In `configIcons.qml`:
     - Add `cfg_<group>Icon` property, an `IconDialog`, a row in `FormLayout`, and a reset entry in the reset button handler.
   - In `configColors.qml` (if quantitative thresholds apply):
     - Add threshold properties, sliders in the grid, and reset entries.

4. **Views layer (`contents/ui/CompactView.qml`, `contents/ui/FullView.qml`)**:
   - No view modifications required. `ViewHelpers.js` processes `MetricStore.metrics` and formats the compact panel items and popup rows automatically.

## Project structure

```
kvitals/
├── metadata.json
├── install.sh
├── install-remote.sh
├── CHANGELOG.md
├── ROADMAP.md
├── docs/
│   ├── architecture.md
│   ├── configuration.md
│   ├── installation.md
│   ├── contributing.md
│   ├── troubleshooting.md
│   └── temp-sensor-logic.md
└── contents/
    ├── config/
    │   ├── config.qml
    │   └── main.xml
    └── ui/
        ├── main.qml               <- widget root, wires sensors to MetricStore
        ├── CompactView.qml
        ├── FullView.qml
        ├── configGeneral.qml
        ├── configMetrics.qml
        ├── configIcons.qml
        ├── configColors.qml
        ├── models/
        │   ├── MetricDefinitions.js  <- shared metric catalog
        │   ├── MetricConfig.qml      <- Plasmoid.configuration adapter
        │   ├── MetricStore.qml       <- flat metrics list + chart history
        │   └── ViewHelpers.js        <- grouping/ordering for each view
        └── sensors/
            ├── qmldir
            ├── CpuSensors.qml
            ├── MemorySensors.qml
            ├── TempSensors.qml
            ├── GpuSensors.qml
            ├── BatterySensors.qml
            ├── NetworkSensors.qml
            ├── DiskSensors.qml
            ├── FanSensors.qml
            ├── UptimeSensors.qml
            └── Utils.qml
```
