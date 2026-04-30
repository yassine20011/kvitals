# Configuration

Right-click the widget → **Configure KVitals...** to open the settings dialog. Settings are organized into four tabs.

## General Tab

| Setting             | Description                                                                    | Default            |
|---------------------|--------------------------------------------------------------------------------|--------------------|
| **Display mode**    | How metrics are shown in the panel                                             | Text               |
| **Layout**          | Compact panel layout direction                                                 | Horizontal         |
| **Icon size**       | Icon dimensions in pixels (only visible when using icons)                      | 12 px              |
| **Font**            | Font family for all panel text (searchable dropdown of system fonts, editable) | monospace          |
| **Font size**       | Text size in pixels. `0` uses the system default                               | 0 (system default) |
| **Update interval** | How often stats are refreshed                                                  | 2.0 seconds        |

### Display Modes

| Mode             | Description                                                   |
|------------------|---------------------------------------------------------------|
| **Text**         | Labels + values: `CPU: 26%  \|  RAM: 8.8/39.0G`               |
| **Icons**        | Icons + values only: `🖥 26%  \|  🧠 8.8/39.0G`               |
| **Icons + Text** | Icons + labels + values: `🖥 CPU: 26%  \|  🧠 RAM: 8.8/39.0G` |

!!! tip "Saving Panel Space"
    **Icons** mode is the most compact — great for small panels or when you have many metrics enabled.

### Layout Types

| Layout         | Description                                                  |
|----------------|--------------------------------------------------------------|
| **Horizontal** | Shows each compact metric in a single row, separated by `\|` |
| **Vertical**   | Stacks the value above the icon                              |

## Metrics Tab

| Setting                   | Description                                                                       | Default                              |
|---------------------------|-----------------------------------------------------------------------------------|--------------------------------------|
| **Metric Order**          | Use the up/down buttons to rearrange metrics in the panel                         | CPU, RAM, Temp, GPU, Bat, Power, Net |
| **Metric enable toggles** | Enables or disables each metric                                                   | On                                   |
| **Show in compact panel** | Controls whether each enabled metric appears in the panel representation          | On                                   |
| **Network interface**     | Select network interface (`auto` or manual)                                       | auto                                 |
| **Battery device**        | Leave empty for automatic battery detection, or enter a sensor device id manually | auto                                 |

### Supported Metrics

| Metric                | Compact Label | Description                                         |
|-----------------------|---------------|-----------------------------------------------------|
| **CPU Usage**         | `CPU:`        | CPU utilization percentage                          |
| **RAM Usage**         | `RAM:`        | Used/total memory                                   |
| **CPU Temperature**   | `TEMP:`       | CPU temperature in °C                               |
| **GPU Metrics**       | `GPU:`        | GPU usage, VRAM, and GPU temperature when available |
| **Battery Status**    | `BAT:`        | Battery percentage                                  |
| **Power Consumption** | `PWR:`        | Power draw in watts                                 |
| **Network Speed**     | `NET:`        | Download/upload speeds                              |

### Compact Panel Visibility

Each metric has two visibility controls:

| Control                   | Effect                                                                                                                      |
|---------------------------|-----------------------------------------------------------------------------------------------------------------------------|
| **Metric checkbox**       | Enables the metric globally.                                                                                                |
| **Show in compact panel** | Hides or shows the metric in the panel widget. The metric remains available in the dropdown menu and tooltip while enabled. |

Use this when you still want to track a metric in the tooltip or dropdown but want to hide it from the panel to save
space.

### Grouping

| Setting                   | Description                                                                                               | Default |
|---------------------------|-----------------------------------------------------------------------------------------------------------|---------|
| **Merge CPU & Temp**      | Shows CPU temperature as a second value next to CPU usage in the widget                                   | Off     |
| **Merge Battery & Power** | Shows power consumption as a second value next to battery level in the widget                             | Off     |
| **Split GPU metrics**     | Shows GPU usage, VRAM, and GPU temperature as separate compact panel entries instead of one grouped entry | Off     |

Merged compact rows only absorb the second metric when both metrics are enabled and selected for the compact panel.

### Network Interface

When set to `auto`, the widget natively aggregates the traffic across all active network connections using KDE's
`network/all` sensor. This handles VPN routing and switching networks automatically.

You can manually select a specific interface (e.g., `wlan0`, `enp3s0`) from the dropdown if you only want to monitor a
single device.

!!! note
    The manual interface list is populated dynamically from `/sys/class/net/`.

## Icons Tab

Each metric has its own icon that can be customized:

| Metric      | Default Icon | Icon Name             |
|-------------|--------------|-----------------------|
| CPU         | 🖥           | `cpu`                 |
| RAM         | 🧠           | `memory`              |
| Temperature | 🌡           | `temperature-normal`  |
| GPU         | GPU          | `video-card`          |
| Battery     | 🔋           | `battery-good`        |
| Power       | ⚡            | `battery-charging-60` |
| Network     | 📶           | `network-wireless`    |

Click **"Change..."** to open KDE's native icon picker, which lets you browse and search all icons from your installed
icon theme (Breeze, Papirus, Tela, etc.).

Click **"Reset to defaults"** to restore all icons to their default values.

!!! note "Monochrome Rendering"
    Icons are rendered with `isMask: true`, meaning they adopt the panel's text color (monochrome). This ensures
    visibility on both light and dark panels.

!!! tip "Finding Icons"
    The icon picker shows all icons from your installed theme. Use the search bar to find icons by name — try keywords
    like "chip", "thermometer", "download", or "lightning".

## Colors Tab

| Setting                       | Description                                                  | Default                 |
|-------------------------------|--------------------------------------------------------------|-------------------------|
| **Use custom font color**     | Overrides the widget text color with a custom color          | Off                     |
| **Color**                     | Font color as a picked or typed `#RRGGBB` value              | Plasma theme text color |
| **Enable threshold coloring** | Changes color of supported metric values based on thresholds | Off                     |
| **Warning color**             | Color used when a warning threshold is reached               | `#e5a50a`               |
| **Critical color**            | Color used when a critical threshold is reached              | `#da4453`               |

Threshold coloring supports CPU usage, CPU temperature, RAM usage, GPU usage, GPU temperature, and battery level.

| Metric          | Default warning color | Default critical color |
|-----------------|-----------------------|------------------------|
| CPU usage       | 70%                   | 90%                    |
| CPU temperature | 60°C                  | 85°C                   |
| RAM usage       | 70%                   | 90%                    |
| GPU usage       | 70%                   | 90%                    |
| GPU temperature | 60°C                  | 85°C                   |
| Battery level   | 30%                   | 15%                    |

!!! note "Battery Thresholds"
    Battery thresholds are inverted: warning and critical states trigger when the battery level falls _below_ the
    configured values.
