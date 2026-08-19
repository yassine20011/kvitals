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
- `query(pattern)`: Returns array of matching `{ id, name }` objects.
- `queryIds(pattern)`: Returns array of matching sensor ID strings.
- `sensorExists(id)`: Fast boolean check.

`HardwareDiscovery` contains zero GPU, disk, fan, network, temperature, or battery specific logic.

## Sensor modules (`contents/ui/sensors/`)

Each metric category has its own QML component. Components receive the shared `HardwareDiscovery` instance, query their relevant sensor IDs, and own all value polling, calculations, and domain heuristics.

| Module | Discovery query | Key exposed properties |
|---|---|---|
| `CpuSensors.qml` | Static (`cpu/all/usage`, `averageFrequency`) | `cpuValue`, `cpuNumericValue`, `cpuFreqValue` |
| `MemorySensors.qml` | Static (`memory/physical/used`, `total`) | `ramValue`, `ramPercentValue`, `ramPercentage` |
| `TempSensors.qml` | `PATTERNS.TEMP_LMSENSORS` + ISA Super I/O / SPD5118 filtering | `tempValue`, `cpuTempValue`, `ramTempValue`, `ramTempExists` |
| `GpuSensors.qml` | `PATTERNS.GPU` (`gpu/gpu\d+/usage`) | `gpuDataList`, `discoveredGpus` |
| `BatterySensors.qml` | `PATTERNS.BATTERY` + probe/qdbus fallback | `batValue`, `batNumericValue`, `powerValue` |
| `NetworkSensors.qml` | `PATTERNS.NETWORK_IFACE` (`network/[^/]+/download`) | `netDownValue`, `netUpValue`, `netIpValue` |
| `DiskSensors.qml` | `PATTERNS.DISK_READ` & `PATTERNS.DISK_TEMP` + Solid hotplug filter | `diskReadValue`, `diskWriteValue`, `diskDataList` |
| `FanSensors.qml` | `PATTERNS.FAN` + alphabetical sort and max RPM check | `fanDataList`, `hasFanData`, `multiFan` |
| `UptimeSensors.qml` | Static (`os/system/uptime`) | `uptimeValue` |

`Utils.qml` is a singleton providing formatting helpers (`formatBytes`, `formatRate`, `resolveColor`) used by most sensor components.

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
- `orderedKeys` — the final display order, filled from the user's `metricOrder` setting with any missing groups appended from `MetricDefinitions.ALL_GROUP_KEYS`

### `MetricStore.qml`

The central aggregator. On every sensor change it recomputes `metrics`, a `readonly` property holding a flat array of metric objects. Each object has a fixed shape:

```
{
  id, defId, group, subKey, deviceId, deviceName,
  label, groupLabel, subLabel, prefix,
  icon, secondaryIcon,
  value,        // numeric (NaN when unavailable)
  displayValue, // formatted string
  popupDisplay, rawString,
  color, status,
  chartKey, chartMax, hasChart,
  visibleInCompact, visibleInPopup
}
```

`MetricStore` also manages `chartHistory` — a ring buffer (up to 60 samples) per `chartKey`, written by `chartTimer` at `updateInterval` ms.

### `ViewHelpers.js`

A `.pragma library` file with two functions:

- `buildCompactItems(metricsList, orderedKeys)` — groups and orders metrics into compact panel items. Items are either `{ icon, label, value, color, key }` (single value) or `{ icon, label, segments, color, key }` (multi-value, used for net, disk, multi-fan).
- `buildPopupItems(metricsList, orderedKeys)` — returns one row per visible popup metric: `{ label, value, color, icon, chartKey, chartMax }`. `icon` may be a two-element array when a secondary icon is present.

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

## Adding a new sensor

1. Create `contents/ui/sensors/NewSensor.qml` exposing formatted value properties.
2. Register it in `sensors/qmldir`.
3. Add an entry (or entries) to `MetricDefinitions.DEFINITIONS` and `GROUPS`.
4. Add config entries to `config/main.xml` and expose them in `MetricConfig.qml`.
5. Instantiate the sensor in `main.qml` and pass it to `MetricStore` via `sensors`.
6. Add a metric push block in `MetricStore.metrics` for the new group.
7. Add toggle checkboxes in `configMetrics.qml`.

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
