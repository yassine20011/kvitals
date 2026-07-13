# Troubleshooting

## Temperature Shows "--"

**Cause:** The widget couldn't find a temperature source on your system.

**Fix:** Check which thermal sources are available:

```bash
# Check thermal zones
cat /sys/class/thermal/thermal_zone*/type 2>/dev/null

# Check hwmon
for d in /sys/class/hwmon/hwmon*/; do
    echo "$(cat "$d/name" 2>/dev/null): $d"
done

# Check lm-sensors
sensors 2>/dev/null | head -20
```

!!! tip "AMD Systems"
    If you're on AMD, make sure `k10temp` or `zenpower` kernel module is loaded:
    ```bash
    sudo modprobe k10temp
    ```
    To load it automatically on boot, add `k10temp` to `/etc/modules-load.d/k10temp.conf`.

## RAM Shows Empty (versions ≤ 1.4.0)

**Cause:** On versions before 1.4.1, RAM was read by parsing the `free` command, which translates its output headers (e.g. `Mem:`) based on your system locale. Non-English locales caused the parser to match nothing.

**Fix:** Update to KVitals 1.4.1+, which reads directly from `/proc/meminfo` (always English, locale-independent).



## Battery/Power Shows Nothing

**Cause:** No battery detected (e.g., desktop systems without a battery or UPS).

**Behavior in KVitals (v2.2.0+):** The widget uses KDE's native `SensorTreeModel` to dynamically scan your system's hardware tree for any connected battery (including `BAT0`, `BAT1`, `BATT`, `CMB0`, `macsmc-battery`, etc.). If nothing shows up, it means the KDE `ksystemstats` daemon cannot find a battery API on your machine.

!!! note
    This is expected behavior on desktop systems. Disable battery and power metrics in **Settings → Metrics** tab to hide the empty entries.

## Network Speed Shows 0

**Cause:** Wrong network interface selected.

**Fix:**

1. Open **Settings → Metrics** and ensure the network interface is set to `auto`.
2. If you want to monitor a specific connection, select it from the dropdown list.

!!! tip
    If you use multiple connections (WiFi + Ethernet), set the interface manually to the one you want to monitor.

## GPU Shows Only Usage (or Missing VRAM/Temp)

**Cause:** GPU sensor availability depends on your driver/backend. Some systems expose only usage, while VRAM or temperature sensors are missing or report no data.

**Behavior in KVitals:** The widget now shows only the GPU fields that are available on your system (no placeholder `...` / `--` for unsupported GPU sub-metrics).

**Fix/Debug:** List GPU sensor IDs reported by Plasma KSystemStats:

```bash
qdbus --literal org.kde.ksystemstats1 /org/kde/ksystemstats1 org.kde.ksystemstats1.allSensors \
  | rg -o '"gpu/[^"]+"' | tr -d '"' | sort -u
```

Then test a specific sensor value:

```bash
qdbus --literal org.kde.ksystemstats1 /org/kde/ksystemstats1 org.kde.ksystemstats1.sensorData gpu/all/usage
```

!!! tip
    On multi-GPU systems, per-GPU sensors such as `gpu/gpu1/*` may exist even when aggregate sensors are partial.

## Metric Shows in Popup But Not Panel

**Cause:** The metric is enabled, but its **Show in compact panel** checkbox is disabled in the Metrics settings.

**Fix:**

1. Open **Settings → Metrics**.
2. Find the metric in the order list.
3. Enable **Show in compact panel** under that metric.

!!! note
    Compact grouping also depends on compact visibility. For example, **Merge CPU & Temp** only shows temperature next to CPU when both metrics are enabled and selected for the compact panel.

## Widget Shows "KVitals" or "..."

**Cause:** The KSysGuard daemon hasn't returned sensor data yet.

**Fix:** Wait a few seconds for the data to populate. If it still doesn't, try restarting the `plasma-ksystemstats` service:
```bash
systemctl --user restart plasma-ksystemstats.service
```

## Icons Not Visible on Panel

**Cause:** Icons are rendered with `isMask: true` (monochrome). If your panel background is the same color as the text color, icons may be invisible.

!!! tip
    Try switching to a different Plasma theme, or adjust the panel opacity. You can also switch to **Text** display mode if icons aren't working well with your theme.

## Settings Dialog Shows Warnings in Journal

!!! note "Harmless Warnings"
    You may see `cfg_*Default` warnings in the journal. These are harmless Plasma 6 KCM warnings about default property injection and **do not affect functionality**.

## Widget Not Appearing After Install

**Fix:**

1. Restart plasmashell:
   ```bash
   kquitapp6 plasmashell && kstart plasmashell &
   ```
2. If still missing, check the install path:
   ```bash
   ls ~/.local/share/plasma/plasmoids/org.kde.plasma.kvitals/
   ```

!!! warning
    If the directory doesn't exist, the install failed. Re-run `bash install.sh` from the project directory.

## Desktop Not Loading on Reboot (Widget on Desktop)

**Affects:** Versions prior to 2.10.1, when KVitals is placed on the **desktop** (not the panel).

**Symptom:** After a reboot, the KDE Plasma desktop fails to appear or enters a `plasmashell` crash loop. The system is still running but the desktop environment does not display. Logs show a `SIGSEGV` in `KirigamiPlasmaStyle::PlasmaTheme::syncColors()`.

**Root cause:** When `ShellCorona::load()` attaches a widget to the desktop window at boot, it performs a deep recursive `QQuickItemPrivate::refWindow()` walk over the entire QML object tree. On versions before 2.10.1, all seven sensor modules (`CpuSensors`, `MemorySensors`, `TempSensors`, `GpuSensors`, `BatterySensors`, `NetworkSensors`, `FanSensors`) were direct children of `PlasmoidItem`, each owning `SensorTreeModel`, `KDescendantsProxyModel`, and multiple `Sensor` objects. This deep tree was enough to trigger a use-after-free race condition in Kirigami's theme initialization on certain hardware or distro combinations.

**Fix:** Update to KVitals **2.10.1 or later**. Sensor loading is now deferred to the next event loop iteration after window attachment completes, so `refWindow()` always runs on a minimal QML tree. Safe `QtObject` null-stubs cover all sensor property bindings during the brief startup window.

**Workaround (if you cannot update):** Move the widget from the desktop to the panel, or remove it entirely and reinstall after the desktop has fully loaded:

```bash
# Force-restart plasmashell to recover the desktop
kquitapp6 plasmashell && kstart plasmashell &
```

!!! tip
    If the desktop loads but the widget is missing after using the workaround, right-click the desktop → **Add Widgets** to re-add KVitals.

## Custom Font Not Applying

**Cause:** The font name might not match exactly.

**Fix:**

1. Check available fonts: `fc-list | grep -i "font-name"`
2. In settings, use the exact family name from the dropdown
3. Font size `0` means "use system default" — set a specific value if needed

!!! tip
    The font dropdown is searchable — start typing the font name to filter the list. You can also type a custom font name directly.
