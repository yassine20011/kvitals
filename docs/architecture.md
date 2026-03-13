# Architecture

KVitals is a KDE Plasma 6 widget (plasmoid) with a modular architecture connecting native **KSysGuard sensors** to a **QML UI** through dedicated sensor components.

## Data Flow

![KVitals Data Flow](dataflow.svg)

## Sensor Modules (`contents/ui/sensors/`)

Each system metric has its own QML component under `sensors/`. These components encapsulate all sensor subscriptions, data parsing, and value formatting for their metric.

| Module | Sensors | Exposed Properties |
|---|---|---|
| `CpuSensors.qml` | `cpu/all/usage` | `cpuValue` |
| `MemorySensors.qml` | `memory/physical/used`, `total` | `ramValue` |
| `TempSensors.qml` | `cpu/all/averageTemperature` | `tempValue` |
| `GpuSensors.qml` | `gpu/all/usage`, `totalVram`, `usedVram`, `temperature` | `gpuValue`, `gpuRamValue`, `gpuTempValue`, `gpuDisplayValue`, `hasGpuData` |
| `BatterySensors.qml` | `power/<device>/chargePercentage`, `chargeRate` | `batValue`, `powerValue` |
| `NetworkSensors.qml` | `network/<iface>/download`, `upload` | `netDownValue`, `netUpValue` |

A shared `Utils.qml` singleton provides formatting helpers (`formatBytes`, `formatRate`) and sensor-reading utilities (`sensorValueOrNaN`, `firstReadyNumber`, `maxReadyNumber`, `firstReadyVramPair`).

### Performance Benefits

1. **Zero Subprocesses**: No `bash`, `awk`, or `cat` commands are spawned.
2. **Stable File Descriptors**: No CLI pipes need to be kept open, eliminating Plasma 6 Wayland FD-exhaustion crashes.
3. **Low Latency**: The widget reads the exact same backend API as the official KDE System Monitor.

## Orchestrator (`main.qml`)

`main.qml` acts as a lightweight orchestrator (~140 lines):

1. **Reads configuration** from `Plasmoid.configuration`
2. **Instantiates sensor modules** with the configured `updateInterval`
3. **Builds metrics models** using the `orderedKeys` array (derived from the `metricOrder` config)
4. **Passes models** to `CompactView` and `FullView` for rendering

```
main.qml
  ├── CpuSensors { id: cpu }
  ├── MemorySensors { id: memory }
  ├── TempSensors { id: temp }
  ├── GpuSensors { id: gpu }
  ├── BatterySensors { id: battery }
  ├── NetworkSensors { id: network }
  ├── compactRepresentation: CompactView { metricsModel: ... }
  └── fullRepresentation: FullView { metricsModel: ... }
```

## Views

### CompactView (Panel)

A `RowLayout` with a `Repeater` that renders each enabled metric as:
- **Icon** (optional, via `Kirigami.Icon` with `isMask: true`)
- **Label** (optional, e.g., "CPU:")
- **Value** (always shown, e.g., "26%")
- **Separator** (`|` between metrics)

Visibility of icons/labels is controlled by the `displayMode` property.

!!! tip
    Icons use `isMask: true` to render as monochrome, matching the panel's text color regardless of the icon theme.

### FullView (Popup)

A `ColumnLayout` with a `Repeater` showing a detailed row per metric with label and bold value, displayed when clicking the widget.

### Tooltip

Multi-line text showing all enabled metrics, displayed on hover.

## Configuration System

```
config/main.xml          ← Config schema (entry names, types, defaults)
config/config.qml        ← Tab registration (General, Metrics, Icons)
ui/configGeneral.qml     ← General tab (display mode, font, interval)
ui/configMetrics.qml     ← Metrics tab (show/hide toggles, metric order, network interface, battery device)
ui/configIcons.qml       ← Icons tab (per-metric icon picker)
```

All config values are accessed in `main.qml` via `Plasmoid.configuration.<key>`.

!!! tip "Adding a New Sensor"
    1. Create `contents/ui/sensors/NewSensor.qml` exposing formatted value properties
    2. Register it in `sensors/qmldir`
    3. Instantiate it in `main.qml`
    4. Add it to the `orderedKeys` loop in compact/full/tooltip builders
    5. Add a `show*` config entry in `main.xml` and a checkbox in `configMetrics.qml`

## Project Structure

```
kvitals/
├── metadata.json                   # Plasmoid metadata (name, version, id)
├── install.sh                      # Local install script
├── install-remote.sh               # Remote install (curl/wget)
├── CHANGELOG.md                    # Version history
├── docs/                           # Documentation
│   ├── installation.md
│   ├── configuration.md
│   ├── architecture.md
│   ├── contributing.md
│   └── troubleshooting.md
└── contents/
    ├── config/
    │   ├── config.qml              # Tab registration
    │   └── main.xml                # Config schema
    └── ui/
        ├── main.qml                # Widget orchestrator
        ├── CompactView.qml         # Panel representation
        ├── FullView.qml            # Popup representation
        ├── configGeneral.qml       # General settings tab
        ├── configMetrics.qml       # Metrics settings tab
        ├── configIcons.qml         # Icons settings tab
        └── sensors/                # Sensor modules
            ├── qmldir              # QML module definition
            ├── CpuSensors.qml      # CPU usage
            ├── MemorySensors.qml   # RAM usage
            ├── TempSensors.qml     # CPU temperature
            ├── GpuSensors.qml      # GPU usage, VRAM, temp
            ├── BatterySensors.qml  # Battery & power
            ├── NetworkSensors.qml  # Network speed
            └── Utils.qml           # Shared formatting helpers
```
