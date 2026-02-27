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

**Cause:** No battery detected (desktop systems without a battery).

!!! note
    This is expected behavior on desktop systems. Disable battery and power metrics in **Settings → Metrics** tab to hide the empty entries.

## Network Speed Shows 0

**Cause:** Wrong network interface selected.

**Fix:**

1. Open **Settings → Metrics** and ensure the network interface is set to `auto`.
2. If you want to monitor a specific connection, select it from the dropdown list.

!!! tip
    If you use multiple connections (WiFi + Ethernet), set the interface manually to the one you want to monitor.

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

## Custom Font Not Applying

**Cause:** The font name might not match exactly.

**Fix:**

1. Check available fonts: `fc-list | grep -i "font-name"`
2. In settings, use the exact family name from the dropdown
3. Font size `0` means "use system default" — set a specific value if needed

!!! tip
    The font dropdown is searchable — start typing the font name to filter the list. You can also type a custom font name directly.
