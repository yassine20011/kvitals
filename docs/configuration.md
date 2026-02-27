# Configuration

Right-click the widget → **Configure KVitals...** to open the settings dialog. Settings are organized into three tabs.

## General Tab

| Setting | Description | Default |
|---------|-------------|---------|
| **Display mode** | How metrics are shown in the panel | Text |
| **Icon size** | Icon dimensions in pixels (only visible when using icons) | 12 px |
| **Font** | Font family for all panel text (searchable dropdown of system fonts, editable) | monospace |
| **Font size** | Text size in pixels. `0` uses the system default | 0 (system default) |
| **Update interval** | How often stats are refreshed | 2.0 seconds |

### Display Modes

| Mode | Description |
|------|-------------|
| **Text** | Labels + values: `CPU: 26%  \|  RAM: 8.8/39.0G` |
| **Icons** | Icons + values only: `🖥 26%  \|  🧠 8.8/39.0G` |
| **Icons + Text** | Icons + labels + values: `🖥 CPU: 26%  \|  🧠 RAM: 8.8/39.0G` |

!!! tip "Saving Panel Space"
    **Icons** mode is the most compact — great for small panels or when you have many metrics enabled.

## Metrics Tab

| Setting | Description | Default |
|---------|-------------|---------|
| **Show CPU usage** | Display CPU utilization percentage | On |
| **Show RAM usage** | Display used/total memory | On |
| **Show CPU temperature** | Display CPU temperature in °C | On |
| **Show battery status** | Display battery percentage | On |
| **Show power consumption** | Display power draw in watts | On |
| **Show network speed** | Display download/upload speeds | On |
| **Network interface** | Select network interface (`auto` or manual) | auto |

### Network Interface

When set to `auto`, the widget natively aggregates the traffic across all active network connections using KDE's `network/all` sensor. This handles VPN routing and switching networks automatically.

You can manually select a specific interface (e.g., `wlan0`, `enp3s0`) from the dropdown if you only want to monitor a single device.

!!! note
    The manual interface list is populated dynamically from `/sys/class/net/`.

## Icons Tab

Each metric has its own icon that can be customized:

| Metric | Default Icon | Icon Name |
|--------|-------------|-----------|
| CPU | 🖥 | `cpu` |
| RAM | 🧠 | `memory` |
| Temperature | 🌡 | `temperature-normal` |
| Battery | 🔋 | `battery-good` |
| Power | ⚡ | `battery-charging-60` |
| Network | 📶 | `network-wireless` |

Click **"Change..."** to open KDE's native icon picker, which lets you browse and search all icons from your installed icon theme (Breeze, Papirus, Tela, etc.).

Click **"Reset to defaults"** to restore all icons to their default values.

!!! note "Monochrome Rendering"
    Icons are rendered with `isMask: true`, meaning they adopt the panel's text color (monochrome). This ensures visibility on both light and dark panels.

!!! tip "Finding Icons"
    The icon picker shows all icons from your installed theme. Use the search bar to find icons by name — try keywords like "chip", "thermometer", "download", or "lightning".
