# Changelog

All notable changes to KVitals will be documented in this file.

## [2.4.0] - 2026-04-01

### Added
- **Custom Font Color**: Override the widget font color to match your panel theme (#20). Configurable via the new **Colors** settings tab.
- **Threshold-Based Coloring**: Metric values dynamically change color when they exceed configurable warning/critical thresholds (#12). Supported metrics:
  - CPU usage (default: warning 70%, critical 90%)
  - CPU temperature (default: warning 60°C, critical 85°C)
  - RAM usage (default: warning 70%, critical 90%)
  - GPU usage (default: warning 70%, critical 90%)
  - GPU temperature (default: warning 60°C, critical 85°C)
  - Battery level (inverted: warning below 30%, critical below 15%)
- **Colors Config Tab**: New settings page with color pickers for font/warning/critical colors and per-metric threshold sliders.
- Sensor modules now expose raw numeric values (`cpuNumericValue`, `tempNumericValue`, `ramPercentage`, `batNumericValue`) for threshold comparison.
- `Utils.resolveColor()` function for flexible threshold-triggered color resolution.

### Fixed
- Fixed the Colors tab color picker turning white after selecting a color; it now uses a stable native platform color dialog and preserves the selected swatch correctly.

### Notes
- Network and Power metrics are excluded from threshold coloring (no meaningful universal threshold).
- Both features are **opt-in** — disabled by default. Existing users are unaffected.

## [2.3.0] - 2026-03-13

### Changed
- **Sensor Module Architecture**: Extracted all sensor logic from `main.qml` into dedicated QML components under `contents/ui/sensors/`:
  - `CpuSensors.qml` — CPU usage monitoring
  - `MemorySensors.qml` — RAM usage monitoring
  - `TempSensors.qml` — CPU temperature monitoring
  - `GpuSensors.qml` — GPU usage, VRAM, and temperature monitoring
  - `BatterySensors.qml` — Battery and power monitoring with auto-detection
  - `NetworkSensors.qml` — Network download/upload speed monitoring
  - `Utils.qml` — Shared formatting helpers (byte formatting, rate formatting)
- **View Separation**: Extracted compact and full representations into `CompactView.qml` and `FullView.qml`.
- **Reduced `main.qml`**: From ~700 lines to ~140 lines — now acts purely as an orchestrator.

### Notes
- No user-facing or configuration changes. The widget behaves identically to v2.2.1.
- This refactor improves maintainability and makes it easier to add new sensor types in the future.

## [2.2.1] - 2026-03-07

### Fixed
- **Battery Detection Hotfix**: Replaced `SensorTreeModel` with a crash-free **Two-Stage Hybrid Detection** system (#14):
  - **Stage 1 (Silent Probe)**: Silently probes common battery paths (`BAT0`, `BAT1`, `BATT`, etc.) for instant detection without running any subprocesses.
  - **Stage 2 (Fallback)**: If no standard battery is found, falls back to a single `qdbus` query to list all sensors, completely avoiding `PlasmaCore.DataSource` file descriptor leaks. Includes a manual config fallback if `qdbus` is unavailable.

## [2.2.0] - 2026-03-05

### Added
- **Custom Metric Order**: Added a new configuration option to arrange metrics (CPU, RAM, GPU, etc.) individually in whatever order you prefer (#7).
- **Dynamic Battery Detection**: Replaced hardcoded `BAT0`/`BAT1` sensors with dynamic `SensorTreeModel` discovery. The widget will now automatically find any battery your system has (BAT0, BATT, CMB0, macsmc-battery, etc.) (#14).

## [2.1.1] - 2026-03-03

### Fixed
- Fixed a "Detected anchors on an item that is managed by a layout" QML warning spanning the journal log caused by a `MouseArea` anchoring inside a `RowLayout` (#13).

## [2.1.0] - 2026-03-01

### Added
- **GPU Metrics Support**: Added VRAM usage and GPU temperature monitoring to the widget.
- GPU data is retrieved natively using KDE KSysGuard sensors (`org.kde.ksysguard.sensors`).

## [2.0.0] - 2026-02-27

### Changed
- **Major Architecture Overhaul**: Replaced the previous `sys-stats.sh` backend with native KDE KSysGuard sensors (`org.kde.ksysguard.sensors`).
- Completely eliminates "file descriptor leak" crashes (Issue #8) and improves overall performance by relying directly on the `ksystemstats` D-Bus daemon instead of constantly spawning bash processes.
- Automatic fallback for battery monitoring (BAT0 and BAT1) logic implemented directly in QML.

## [1.4.1] - 2026-02-24

### Fixed
- RAM usage showing empty on non-English locales — `free` translates its `Mem:` header based on locale, causing the parser to match nothing
- Switched RAM data source from `free -b` to `/proc/meminfo` (locale-independent, faster, more accurate)

## [1.4.0] - 2026-02-22

### Added
- **Display mode setting** — choose between Text, Icons, or Icons + Text for the panel
- **Custom icon picker** — select icons from your installed theme for each metric (via KDE's native icon picker)
- **Icon size slider** — adjust icon size (8–24px) when using icon mode
- **Font customization** — choose any system font and font size for the panel text
- **Settings tabs** — split configuration into General, Metrics, and Icons tabs
- **Reset to defaults** button on the Icons tab
- **CHANGELOG.md** — version history
- **Documentation** — MkDocs site with installation, configuration, architecture, contributing, and troubleshooting guides

## [1.3.0] - 2026-02-16

### Added
- Power consumption tracking (via `/sys/class/power_supply/`) — contributed by [@Pijuli](https://github.com/Pijuli)

### Fixed
- ShellCheck warnings from power consumption PR (SC2034, SC2155)

## [1.2.1] - 2026-02-16

### Fixed
- AMD CPU temperature detection — added `k10temp`, `zenpower`, `zenergy`, `amdgpu` to thermal_zone and hwmon detection
- lm-sensors fallback now matches AMD `Tccd1` label
- Reordered temperature fallback tiers to prioritize CPU-specific sources over generic thermal zones

## [1.2.0] - 2026-02-13

### Added
- Auto-detect network interface via `ip route` with manual override in settings
- Network interface selector in widget configuration

### Fixed
- ShellCheck warnings (SC2010, SC2155)

## [1.1.0] - 2026-02-12

### Changed
- Modularized `sys-stats.sh` into functions
- Enhanced CPU temperature detection with 4-tier fallback (thermal_zone → hwmon → lm-sensors → generic)

## [1.0.0] - 2026-02-12

### Added
- Initial release
- CPU usage (delta-based from `/proc/stat`)
- RAM usage (from `/proc/meminfo`)
- CPU temperature (multi-source detection)
- Battery status with emoji indicators
- Network speed (delta-based from `/proc/net/dev`)
- Configurable update interval
- Toggle visibility per metric
