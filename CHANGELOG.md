# Changelog

All notable changes to KVitals will be documented in this file.

## [2.10.0] - 2026-06-27

### Added

- **Fan Speed Monitoring** (`Metrics` settings): A new standalone "Fan" metric that dynamically discovers and reports fan speeds (including GPU and CPU fans) directly from the system (#47).
  - Automatically identifies fans through `SensorTreeModel`.
  - Supports RPM and Percentage display units (configurable in `General` settings).
  - Fully integrates with compact panel, full popup, and tooltip views.
  - Safely handles fans that do not report a maximum RPM by omitting them from percentage-based aggregations to prevent misleading data.
- **Display Mode 'None'** (`General` settings): A new display mode that completely hides the metric labels and icons, showing only the raw values to save space (#47).
- **Config UI Redesign** (`Metrics` settings): The metrics configuration page has been overhauled for better UX, with inline contextual settings (e.g. CPU, GPU, Network options expand directly under their respective metrics) and debounced sensor discovery to eliminate UI freezes on load (#48).

## [2.9.0] - 2026-06-19

### Added

- **Per-GPU Sub-metric Visibility** (`Metrics` settings — GPU Selection): Each GPU entry now has independent **Usage**, **VRAM**, and **Temperature** toggles, letting you show only the metrics you care about without disabling the GPU entirely (#44).
  - Toggling a sub-metric off immediately stops polling those sensors — no unnecessary kernel data fetched.
  - A **minimum-one** guard prevents all three sub-metrics from being deselected at once (the last checked box is disabled), keeping at least one value visible per GPU.
  - Sub-metric checkboxes are automatically disabled when the parent GPU is deselected, matching visual state to functional reality.
  - Storage format uses a compact pipe-separated string (`gpu0:usage,vram|gpu1:usage,temp`). GPUs using all defaults are omitted, keeping the config short. Empty string (default) = all three enabled for every GPU — fully backwards-compatible with existing configs.

## [2.8.1] - 2026-05-23

### Fixed

- **Installation via KDE Store leaving stale widget state** (`install-remote.sh`): Users who first installed via the KDE Store (or an older `install-remote.sh`) and then upgraded manually could end up with a mismatched `kpackage/generic/` registration. This caused settings like **Show in compact panel** to silently not apply, because KDE resolves widget configuration from the kpackage path, not the plasmoids path. The remote install script now mirrors the local `install.sh` behaviour exactly: it removes any previous entry under `~/.local/share/kpackage/generic/<id>` (including stale symlinks), creates the install directory under `~/.local/share/plasma/plasmoids/`, and creates a fresh symlink at the kpackage path pointing to it.

## [2.8.0] - 2026-05-22

### Added

- **Disk I/O & Temperature** (`Metrics` settings — Disk I/O & Temp): New metric showing real-time disk read/write rates and the highest drive temperature across all NVMe and SATA drives. Displayed as `DSK: ↓2.1MB ↑76KB · 42°C` in the compact panel (#36).
  - Drive temperatures are discovered dynamically via `SensorTreeModel` + `lmsensors` (supports `nvme-pci-*` and `drivetemp-scsi-*` chips) — zero polling overhead when the metric is disabled.
  - Dedicated **Disk Temp** threshold sliders added to the Colors settings page (default: warning 45°C, critical 60°C).
- **Unit Preferences** (`General` settings — Unit Preferences section): Choose display units globally across all metrics (#37).
  - **Temperature**: Celsius (°C, default) or Fahrenheit (°F). Applies to CPU temp, GPU temp, and Disk temp everywhere — panel, popup, and tooltip.
  - **Network / Disk I/O**: Bytes (KB/MB, default) or Bits (Kb/Mb). Applies to Network and Disk I/O rates. Suffix convention follows industry standard: uppercase `B` = bytes, lowercase `b` = bits.
  - Threshold slider labels in the Colors settings page update live to reflect the chosen temperature unit (stored values remain in °C for correct sensor comparison).

## [2.7.0] - 2026-05-15

### Added

- **Multi-GPU Support** (`Metrics` settings — GPU Selection): On systems with more than one GPU, each GPU is now listed individually as a separate metric in both the compact panel and the full popup view (#22). Works automatically — no configuration needed on single-GPU machines.
  - Each GPU is detected dynamically via `SensorTreeModel` metadata; no persistent subscriptions run during discovery.
  - The GPU Selection section in settings shows all discovered GPUs with independent enable/disable checkboxes.
- **GPU Custom Labels** (`Metrics` settings — GPU Selection): On multi-GPU systems, each GPU entry in the panel shows a customizable label. Type a name in the **Label** field (e.g. `iGPU`, `dGPU`) to override the default `GPU 1` / `GPU 2` identifiers. Leave it empty to keep the default numbering.
- **Hybrid GPU power hint**: When two or more GPUs are detected, a contextual note appears in the GPU Selection section explaining that unchecking the discrete GPU prevents KVitals from polling it, allowing it to suspend when idle.

### Fixed

- **Unintended dGPU Wakeup** on hybrid GPU laptops (Intel/AMD + NVIDIA setups using `supergfxctl` / `asusctl`): The previous implementation used permanent `Sensors.Sensor` subscriptions for up to 6 hardcoded GPU slots. These subscriptions polled every GPU continuously, preventing the dGPU from entering its suspended/power-save state even when it was idle (#26).
  - **New architecture**: Discovery uses `SensorTreeModel` + `KDescendantsProxyModel` (pure metadata query, no value subscriptions). Data polling uses a single `SensorDataModel` constrained strictly to the GPUs the user has selected.
  - **Result**: Deselecting a GPU in settings stops all polling for that GPU immediately. On hybrid setups, unchecking the dGPU allows it to fully suspend.
  - **Note**: If the dGPU remains active even after unchecking it in KVitals, the cause is likely unrelated — some Xwayland applications keep the GPU awake independently of any sensor polling. This is a system/compositor-level behavior outside the scope of KVitals.

## [2.6.0] - 2026-05-10

### Added

- **Compact Panel Visibility** (`Metrics` settings): Each metric now has an independent "Show in compact panel" toggle, allowing metrics to appear in the full popup view but stay hidden from the panel bar (#29, thanks @keiishu). Disabling a metric preserves its compact visibility state for when it is re-enabled.
- **CPU Frequency** (`Metrics` settings): Display the average CPU frequency in the widget. Auto-formats as GHz (≥ 1000 MHz) or MHz (#33).
  - **Merge into CPU** (compact view): Appends frequency as a second segment next to CPU usage (`CPU: 34% · 3.20 GHz`). Compatible with Merge CPU & Temp — all three values appear as segments.
  - **Full view sub-item**: When enabled, CPU Frequency appears as a dedicated row directly under CPU Usage in the popup.
- **Bold Font** (`General` settings): Toggle bold styling for all metric value labels across compact and full views (#30). Defaults to off.

### Fixed

- Inconsistent font weight across metrics in vertical layout: RAM and Network values (rendered via `SegmentsRow`) were always bold while CPU/GPU were not. All value labels now follow the new Bold Font setting uniformly.

## [2.5.0] - 2026-04-30

### Added

- **Layout Type** (`General` settings): Choose between **Horizontal** (default, unchanged) and **Vertical** layout for the compact panel view. In vertical mode, the metric value is displayed on top with the label/icon dimmed below — ideal for tall panels or icon-only display (#11).
- **Metric Grouping** (`Metrics` settings — Grouping section):
  - **Merge CPU & Temp**: Combines CPU temperature as a second value next to CPU usage (`CPU: 45% · 62°C`), using the same segment display as GPU. The CPU Temperature entry is hidden from the metric order list while merged.
  - **Merge Battery & Power**: Combines power consumption as a second value next to battery level (`BAT: 87% · 12.4W`). Power Consumption entry is hidden from the metric order list while merged.
  - **Split GPU Metrics**: Optionally break GPU usage, VRAM and temperature into separate panel entries instead of the default grouped display (default: grouped).

### Changed

- Metric order list now hides absorbed metrics when grouping is active (e.g. "CPU Temperature" disappears when "Merge CPU & Temp" is enabled), keeping the list clean and non-redundant.
- `CompactView` refactored to use a `Loader`-based delegate system, enabling runtime layout switching without widget reload.

### Fixed

- `Unable to assign [undefined] to QColor` runtime error when CPU+Temp or Battery+Power merge was enabled — missing top-level `color` field on segmented metric objects.
- Defensive `|| baseTextColor` fallback added to all value label color bindings in `CompactView`.

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
