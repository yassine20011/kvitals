# KVitals

A lightweight KDE Plasma 6 panel widget that displays live system vitals directly in your top bar.

```
CPU: 26%  |  RAM: 8.8/39.0G  |  TEMP: 96°C  |  🔋BAT: 78%  |  PWR: +20W  |  NET: ↓82.2K ↑58.9K
```

## Screenshots

![Panel View Text only](screenshots/text_only.png)
![Panel View Icons only](screenshots/icons_only.png)
![Panel View Icons + Text](screenshots/icons_text.png)
![General Settings](screenshots/general_settings.png)
![Metrics Settings](screenshots/metrics_settings.png)
![Icons Settings](screenshots/icons_settings.png)

## Features

- **Live monitoring** — CPU usage, RAM, CPU temperature, battery status, power draw, network speed
- **Display modes** — Text, Icons, or Icons + Text for the panel view
- **Custom icons** — Pick any icon from your installed theme for each metric
- **Font customization** — Choose any system font and size
- **Configurable** — Toggle each metric, adjust refresh rate, organized in 3 settings tabs
- **Minimal footprint** — Native KDE KSysGuard sensors + QML, no heavy dependencies or excessive subprocesses
- **Click to expand** — Detailed popup view with all stats

## Requirements

- KDE Plasma 6.0+

## Installation

### KDE Store (Recommended)

Install directly from the KDE Store:

👉 **[Get KVitals on the KDE Store](https://www.pling.com/p/2347917/)**

Or from within KDE Plasma:
1. Right-click on the panel → **Add Widgets...**
2. Click **Get New Widgets...** → **Download New Plasma Widgets...**
3. Search for **"KVitals"**
4. Click **Install**

---

### Quick Install (curl)

```bash
curl -fsSL https://raw.githubusercontent.com/yassine20011/kvitals/master/install-remote.sh | bash
```

### Quick Install (wget)

```bash
wget -qO- https://raw.githubusercontent.com/yassine20011/kvitals/master/install-remote.sh | bash
```

### Manual Install

```bash
git clone https://github.com/yassine20011/kvitals.git
cd kvitals
bash install.sh
```

Then restart Plasma and add the widget:

```bash
plasmashell --replace &
```

1. Right-click on the panel → **Add Widgets...**
2. Search for **KVitals**
3. Drag it onto your panel

## Configuration

Right-click the widget → **Configure KVitals...** to access settings in three tabs:

- **General** — Display mode, icon size, font, update interval
- **Metrics** — Toggle CPU, RAM, Temperature, Battery, Power, Network
- **Icons** — Customize icons for each metric from your theme

See the [full configuration reference](docs/configuration.md) for details.

## Uninstall

```bash
rm -rf ~/.local/share/plasma/plasmoids/org.kde.plasma.kvitals
```

Then restart Plasma: `plasmashell --replace &`

## Project Structure

```
kvitals/
├── metadata.json                   # Plasmoid metadata
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
        ├── main.qml                # Widget UI
        ├── configGeneral.qml       # General settings tab
        ├── configMetrics.qml       # Metrics settings tab
        └── configIcons.qml         # Icons settings tab
```

## Documentation

- [Installation](docs/installation.md)
- [Configuration](docs/configuration.md)
- [Architecture](docs/architecture.md)
- [Contributing](docs/contributing.md)
- [Troubleshooting](docs/troubleshooting.md)

## License

By contributing, you agree that your contributions will be licensed under the [GPL-3.0 License](LICENSE).