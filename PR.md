## Description

Refactor metrics into a hierarchical structure with configurable sub-metrics, smart temperature sensor detection (chipset, CPU, DDR5 RAM), per-metric visibility control (All/Popup/Compact), and a cleanup pass on the install/package scripts.

### Features

- **Hierarchical metrics**: replace flat boolean flags (`showCpu`, `showCpuFreq`, `showRam`, `showFan`, ...) with a consistent `*Enabled` / `*SubMetrics` schema for CPU, RAM, GPU, Battery, Network, Disk, Fan, Uptime. Compact panel, popup and tooltip all build their segments from the enabled sub-metrics instead of hardcoded field lists.
- **Chipset temperature auto-detection**: scan `lmsensors/(.+)/temp\d+` sensors, prefer ISA/LPC bus adapters (Super I/O chips like `nct6799`), exclude `coretemp` (Intel CPU sensor, exposed on ISA too) and PCI-bus sensors (`k10temp`, `amdgpu`, ...). Falls back to `cpu/all/averageTemperature` when no chipset sensor is found, hardware-agnostic (no vendor/chip allowlist).
- **Dedicated CPU temperature**: always reads `cpu/all/averageTemperature` independently of chipset detection, so "CPU Temperature" and "System Temperature" can no longer collapse to the same reading.
- **DDR5 RAM temperature**: auto-discovers the SPD5118 module via `SensorTreeModel`; the sub-metric checkbox greys out (but stays togglable) when the sensor isn't present on the running hardware.
- **Per-metric visibility**: each metric gets a ComboBox (All / Popup / Compact) controlling where it's rendered, independent of whether it's enabled.
- **Sparkline history**: added `ramTemp` and `diskTemp` to the chart history alongside the existing metrics.
- **Config UI overhaul**: `configMetrics.qml` rewritten around the hierarchical schema, replacing the old `configGeneral.qml` layout.

### Fixes

- **CPU Temperature sub-metric showing System Temperature**: the sub-metric was reading `temp.tempValue` (chipset sensor) instead of `temp.cpuTempValue` (`cpu/all/averageTemperature`) in the compact panel, the popup, and the tooltip alike. Chipset detection also hardened to explicitly exclude PCI-bus CPU/GPU probes so they can never be mistaken for a chipset sensor.

### Chores

- Replaced emoji status markers (`✅`/`❌`/`⚡`/`📦`) with plain ASCII tags (`[OK]`/`[ERR]`/`[STATUS]`) in `install.sh`, `install-remote.sh`, and `package.sh` for consistent, classic CLI-style output.

### Files changed

| File | Description |
|------|-------------|
| `contents/config/main.xml` | Config schema: hierarchical metrics + sub-metrics + visibility entries |
| `contents/ui/configGeneral.qml` | Removed (layout integrated into configMetrics) |
| `contents/ui/configMetrics.qml` | Config UI: hierarchical sub-metric toggles + visibility per metric |
| `contents/ui/main.qml` | Widget orchestrator: sub-metric segments, visibility gates, CPU temp routing |
| `contents/ui/sensors/TempSensors.qml` | Sensor tree scan for chipset/CPU/DDR5 + bus-based heuristic |
| `docs/temp-sensor-logic.md` | Architecture docs for sensor detection strategy |
| `install.sh`, `install-remote.sh`, `package.sh` | ASCII status tags instead of emoji |

## Testing

- [x] Tested on Plasma 6
- [x] Distro: Fedora 42
- [x] HW: ASUS TUF GAMING B650-E WiFi, Ryzen 9 9900X, RTX 5070 Ti
- [x] Widget installs cleanly with `install.sh`
- [x] Widget displays correctly in the panel
