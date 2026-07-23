# Configuration

Right-click the widget, then select **Configure KVitals...** to open the settings dialog. Settings are organized into four tabs.

## General Tab

| Setting | Description | Default |
|---|---|---|
| **Display mode** | Controls how metrics appear in the panel (Text, Icons, or Icons + Text) | Text |
| **Layout** | Direction of compact panel items (Horizontal or Vertical) | Horizontal |
| **Icon size** | Icon dimensions in pixels | 12 px |
| **Font** | Searchable text input with popup list of installed system fonts | monospace |
| **Font size** | Text size in pixels. Setting `0` uses the system default | 0 |
| **Update interval** | Refresh frequency in seconds | 2.0 s |
| **Label opacity** | Transparency of metric labels in the compact view (0.0 to 1.0) | 0.65 |
| **Separator opacity** | Transparency of `\|` dividers in the compact view (0.0 to 1.0) | 0.40 |

### Display Modes

| Mode | Description |
|---|---|
| **Text** | Labels and values: `CPU: 26% \| RAM: 8.8/39.0G` |
| **Icons** | Icons and values: `🖥 26% \| 🧠 8.8/39.0G` |
| **Icons + Text** | Icons, labels, and values: `🖥 CPU: 26% \| 🧠 RAM: 8.8/39.0G` |

### Layout Types

| Layout | Description |
|---|---|
| **Horizontal** | Places metrics in a single row separated by `\|` |
| **Vertical** | Stacks the value text directly above the icon |

## Metrics Tab

### Visibility Settings

Each metric features a four-way visibility selector:

| Option | Effect |
|---|---|
| **All** | Shows the metric in both the compact panel and the expanded popup view. |
| **Compact** | Displays the metric in the compact panel only. |
| **Popup** | Displays the metric in the expanded popup view only, keeping the panel clean. |
| **None** | Disables sensor monitoring for that metric to save system resources. |

### Supported Metrics

| Metric | Panel Label | Popup Features |
|---|---|---|
| **CPU Usage** | `CPU:` (customizable) | Per-core usage and 60-sample sparkline history |
| **RAM Usage** | `RAM:` (customizable) | Used/total memory and 60-sample sparkline history |
| **CPU Temperature** | `TEMP:` | Dedicated CPU temperature reading and sparkline |
| **System Temperature** | `SYS:` | Motherboard/chipset temperature |
| **GPU Metrics** | `GPU:` / `<name>:` | Usage %, VRAM, temperature, and independent GPU sparklines |
| **Fan Speed** | `FAN:` / `Fan N:` | Fan RPM, estimated %, per-fan labels, and sparklines |
| **Battery Status** | `BAT:` | Battery level %, state, power draw (watts), and sparkline |
| **Network Speed** | `NET:` (customizable) | Download/upload rates, IP address, and network rate sparkline |
| **Disk I/O** | `DSK:` (customizable) | Per-drive read/write speeds, drive temps, and sparklines |
| **System Uptime** | `UP:` | System uptime formatted as `Xd Xh Xm` |

### Metric Grouping and Custom Labels

- **Merge CPU & Temp**: Shows CPU temperature next to CPU usage in a single panel block.
- **Merge Battery & Power**: Displays wattage draw next to battery percentage.
- **Split GPU Metrics**: Separates GPU usage, VRAM, and GPU temperature into individual compact items.
- **Custom Labels**: Custom text fields are available for CPU, RAM, Disk, Network, and Fan entries. Unchecking **Use Custom Labels in Panel** forces standard short labels in the panel while keeping custom names in the popup.

### Network Interface

When set to `auto`, the widget aggregates traffic across all active network connections using KDE's `network/all` sensor. This handles VPN routing and switching networks automatically.

You can manually select a specific interface (e.g., `wlan0`, `enp3s0`) from the drop-down list if you only want to monitor a single network interface.

!!! note
    The manual interface list is populated dynamically from `/sys/class/net/`.

### GPU Selection

When **GPU Metrics** is enabled, a **GPU Selection** section lists every GPU detected on your system. GPUs are discovered dynamically via the KDE sensor tree without requiring polling during discovery.

| Control | Description |
|---|---|
| **Checkbox** | Enable or disable monitoring for each individual GPU |
| **Label field** | Override the display name for a GPU. Leave empty to use the name reported by ksystemstats |

**Label resolution order**: custom label → ksystemstats-provided name (e.g. `GPU 1`) → `GPU N` fallback.

!!! tip "Hybrid GPU Laptops (Intel/AMD + NVIDIA)"
    On hybrid laptops using tools like `supergfxctl` or `asusctl`, KVitals only polls GPUs whose checkboxes are selected. Unchecking the discrete GPU stops all polling for it, allowing it to enter its suspended power-saving state when idle.

### Expanded Popup Panel

Clicking the panel widget opens an expanded view with detailed readings and real-time sparkline charts:

- **Sparkline History**: Renders 60-sample history graphs for active metrics. Usage percentages and temperatures use a fixed 0-100 scale.
- **Pin Button**: Clicking the pin icon in the title bar toggles `Plasmoid.hideOnWindowDeactivate`, keeping the panel open while interacting with other windows.
- **Multi-Disk and Multi-Fan Views**: Displays separate rows, individual read/write speeds, and sparklines for every discovered drive and fan.

## Icons Tab

Icons can be assigned individually using KDE's native icon picker:

| Metric | Default Symbolic Icon | Fallback Source |
|---|---|---|
| CPU | `am-cpu-symbolic` | Bundled SVG |
| RAM | `nvidia-ram-symbolic` | Bundled SVG |
| Temperature | `temperature-normal` | Freedesktop Theme |
| GPU | `gpu-symbolic` | Bundled SVG |
| Disk | `am-disk-utility-symbolic` | Bundled SVG |
| Fan | `am-fan-symbolic` | Bundled SVG |
| Battery | `battery-good` | Freedesktop Theme |
| Power | `battery-charging-60` | Freedesktop Theme |
| Network | `network-wireless` | Freedesktop Theme |
| Uptime | `clock` | Freedesktop Theme |

Click **Reset to defaults** to restore the default icon assignments. If an icon is missing from the installed system theme, KVitals automatically falls back to its bundled SVG icon set.

## Colors Tab

| Setting | Description | Default |
|---|---|---|
| **Use custom font color** | Overrides text, label, and icon colors | Off |
| **Font Color** | Base text color hex code | Plasma theme text |
| **Label Color** | Color for labels like `CPU:`. Unset falls back to Font Color | Font Color |
| **Icon Color** | Color for panel and popup icons. Unset falls back to Label Color | Label Color |
| **Enable threshold coloring** | Colors values based on warning and critical limits | Off |
| **Warning color** | Color when a warning threshold is met | `#e5a50a` |
| **Critical color** | Color when a critical threshold is met | `#da4453` |

Threshold sliders are available for CPU usage, CPU temperature, System temperature, RAM usage, RAM temperature, GPU usage, GPU temperature, and battery level.
