# KVitals Roadmap

This roadmap outlines planned features and improvements. It is not a strict commitment — priorities may shift based on community feedback and contributions.

Have a suggestion? Open an issue or start a discussion on GitHub.

---

## Currently supported metrics

- CPU usage, frequency, and temperature
- RAM usage (percentage and used/total), RAM temperature (DDR5 via spd5118 driver)
- System/chipset temperature (auto-detected from lmsensors ISA bus)
- GPU usage, VRAM, and temperature — multi-GPU with custom labels
- Battery charge percentage and power draw (watts)
- Network download/upload speed, local IP address
- Disk read/write rates and temperature
- Fan speed (RPM and percentage, per-fan sparklines)
- System uptime

---

## Currently supported UX features

- Custom metric order (drag to reorder)
- Per-metric visibility: panel only, popup only, both, or disabled
- Metric grouping (merge CPU + temperature, battery + power, split GPU)
- Threshold-based coloring (warning/critical, per metric)
- Custom font color
- Display modes: text, icons, icons + text
- Horizontal and vertical layout
- Unit preferences (°C/°F, bytes/bits)
- Sparkline charts in the popup (60-sample history per metric)
- Popup pin mode
- Per-metric custom label (CPU, RAM, NET, DSK, FAN, TEMP)
- Network interface auto-detection and manual override
- Battery device auto-detection and manual override
- Per-fan stable numbering and independent sparklines

---

## Planned

### New metrics

#### KSystemStats sensors

These sensors are exposed by `ksystemstats` and are planned for future releases:

- **Disk usage** — used/free space per partition via `disk/all/usedPercent` or per-disk
- **CPU load averages** — 1, 5, and 15-minute averages via `cpu/loadaverages/*`
- **Swap usage** — used/total swap via `memory/swap/*`
- **GPU frequency and power** — core frequency and power draw via `gpu/<device>/coreFrequency` and `gpu/<device>/power`
- **Battery health** — degradation percentage via `power/<device>/health`

### UX and configuration

- **Tooltip customization** — choose which metrics appear in the hover tooltip
- **Click action** — configure what happens when clicking the widget (e.g. open System Monitor)

---

## Under consideration

These are ideas being evaluated — no commitment yet:

- **Per-core view** — individual core usage/temperature in the popup
- **Pressure metrics (PSI)** — CPU/IO/memory pressure via the Linux PSI interface
- **Wayland multi-screen** — better handling across multiple monitors
- **Tray icon mode** — minimal system tray alternative to the panel widget

---

## Not planned

- Sparklines or charts in the compact panel bar — charts are shown in the popup only
