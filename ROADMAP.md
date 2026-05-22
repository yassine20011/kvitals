# KVitals Roadmap

This roadmap outlines planned features and improvements. It is not a strict commitment—priorities may shift based on community feedback and contributions.

Have a suggestion? Open an issue or start a discussion on GitHub.

---

## Currently Supported Metrics

- CPU Usage
- CPU Temperature
- CPU Frequency
- RAM Usage
- GPU (Usage, VRAM, Temperature) — with multi-GPU and custom labels
- Battery & Power Consumption
- Network Speed (Download/Upload)
- Disk I/O (Read/Write rates)
- Disk Temperature (highest across all NVMe/SATA drives)

---

## Currently Supported UX Features

- Custom metric order (drag to reorder)
- Per-metric compact panel visibility toggle
- Metric grouping (merge CPU+Temp, Battery+Power, split GPU)
- Threshold-based coloring (warning/critical per metric)
- Custom font color
- Display modes: Text, Icons, Icons+Text
- Horizontal / Vertical layout
- **Unit Preferences** (°C/°F, Bytes/Bits)

---

## Planned

### New Metrics

#### KSystemStats Sensors

These sensors are exposed by `ksystemstats` and are planned for future releases:

- **Disk Usage** — Used/free space per partition via `disk/all/usedPercent` or per-disk breakdown
- **CPU Load Averages** — 1, 5, and 15-minute averages via `cpu/loadaverages/*`
- **Swap Usage** — Used/total swap memory via `memory/swap/*`
- **GPU Frequency & Power** — Core frequency and power draw via `gpu/<device>/coreFrequency` and `gpu/<device>/power`
- **Battery Health** — Degradation percentage via `power/<device>/health`
- **System Uptime** — Via `os/system/uptime`

#### External Sensors (lmsensors)

These require `lmsensors` to be installed and configured:

- **Fan Speed** — CPU fan RPM (where available)

### UX & Configuration

- **Per-metric custom label** — Let users rename metric labels (e.g. "CPU" → "Processor")
- **Tooltip customization** — Choose which metrics appear in the hover tooltip
- **Click action** — Configure what happens when clicking the widget (e.g. open System Monitor)

---

## Under Consideration

These are ideas being evaluated — no commitment yet:

- **Per-core view** — Individual core usage/temperature in the popup
- **Pressure metrics (PSI)** — CPU/IO/Memory pressure via Linux PSI interface
- **Wayland multi-screen** — Better handling across multiple monitors
- **Tray icon mode** — Minimal system tray alternative to panel widget

---

## Not Planned

- Graphs or charts in the compact panel (out of scope for a panel widget)
