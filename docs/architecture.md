# Architecture

KVitals is a KDE Plasma 6 widget (plasmoid) with a direct architecture connecting native **KSysGuard sensors** directly to a **QML UI**.

## Data Flow

![KVitals Data Flow](dataflow.svg)

## Data Collection (KSysGuard Sensors)

KVitals relies completely on standard KDE technologies. Instead of continuously executing shell scripts or external processes, the widget connects securely to the KDE `ksystemstats` D-Bus daemon via `org.kde.ksysguard.sensors`.

By instantiating native `Sensors.Sensor` objects in QML, KVitals subscribes to system statistics without any CPU overhead or file descriptor leaks. 

### Data Sources

All metrics are fetched natively:

- **CPU**: `cpu/all/usage`
- **RAM**: `memory/physical/used` and `memory/physical/total`
- **Temperature**: `cpu/all/averageTemperature` (with fallback logic handled directly by `ksystemstats`)
- **Battery**: `power/battery_BAT0/chargePercentage` and `chargeRate` (with `BAT1` fallback built-in)
- **Network**: `network/<interface>/download` and `upload`

### Performance Benefits

1. **Zero Subprocesses**: No `bash`, `awk`, or `cat` commands are spawned.
2. **Stable File Descriptors**: No CLI pipes need to be kept open, eliminating Plasma 6 Wayland FD-exhaustion crashes.
3. **Low Latency**: The widget reads the exact same backend API as the official KDE System Monitor.

## QML UI (main.qml)

The widget has three visual representations:

### Compact Representation (Panel)

A `RowLayout` with a `Repeater` that renders each enabled metric as:
- **Icon** (optional, via `Kirigami.Icon` with `isMask: true`)
- **Label** (optional, e.g., "CPU:")
- **Value** (always shown, e.g., "26%")
- **Separator** (`|` between metrics)

Visibility of icons/labels is controlled by the `displayMode` property.

!!! tip
    Icons use `isMask: true` to render as monochrome, matching the panel's text color regardless of the icon theme.

### Full Representation (Popup)

A `ColumnLayout` with a `Repeater` showing a detailed row per metric with label and bold value, displayed when clicking the widget.

### Tooltip

Multi-line text showing all enabled metrics, displayed on hover.

## Configuration System

```
config/main.xml          ← Config schema (entry names, types, defaults)
config/config.qml        ← Tab registration (General, Metrics, Icons)
ui/configGeneral.qml     ← General tab (display mode, font, interval)
ui/configMetrics.qml     ← Metrics tab (show/hide toggles, network interface)
ui/configIcons.qml       ← Icons tab (per-metric icon picker)
```

All config values are accessed in `main.qml` via `Plasmoid.configuration.<key>`.

!!! tip "Adding New Config"
    When adding a new config entry, you only need to: add it to `main.xml`, create a UI control in the appropriate config tab, and bind it in `main.qml`. No build step needed.

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
    ├── ui/
        ├── main.qml                # Widget UI
        ├── configGeneral.qml       # General settings tab
        ├── configMetrics.qml       # Metrics settings tab
        └── configIcons.qml         # Icons settings tab
```
