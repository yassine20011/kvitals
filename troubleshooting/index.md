# Troubleshooting

## Temperature Shows "--"

**Cause:** The widget couldn't find a temperature source on your system.

**Fix:** Check which thermal sources are available:

```
# Check thermal zones
cat /sys/class/thermal/thermal_zone*/type 2>/dev/null

# Check hwmon
for d in /sys/class/hwmon/hwmon*/; do
    echo "$(cat "$d/name" 2>/dev/null): $d"
done

# Check lm-sensors
sensors 2>/dev/null | head -20
```

AMD Systems

If you're on AMD, make sure `k10temp` or `zenpower` kernel module is loaded:

```
sudo modprobe k10temp
```

To load it automatically on boot, add `k10temp` to `/etc/modules-load.d/k10temp.conf`.

## RAM Shows Empty (versions ≤ 1.4.0)

**Cause:** On versions before 1.4.1, RAM was read by parsing the `free` command, which translates its output headers (e.g. `Mem:`) based on your system locale. Non-English locales caused the parser to match nothing.

**Fix:** Update to KVitals 1.4.1+, which reads directly from `/proc/meminfo` (always English, locale-independent).

Workaround for older versions

If you can't update immediately, set the locale for the script by adding `export LC_ALL=C` before running it.

## Battery/Power Shows Nothing

**Cause:** No battery detected (desktop systems without a battery).

Note

This is expected behavior on desktop systems. Disable battery and power metrics in **Settings → Metrics** tab to hide the empty entries.

## Network Speed Shows 0

**Cause:** Wrong network interface selected.

**Fix:**

1. Check your active interface: `ip route | grep default`
1. Open **Settings → Metrics** and set the correct interface, or set to `auto`

Tip

If you use multiple connections (WiFi + Ethernet), set the interface manually to the one you want to monitor.

## Widget Shows "KVitals" or "..."

**Cause:** The stats script hasn't returned data yet or failed to execute.

**Fix:**

1. Test the script directly:

   ```
   bash ~/.local/share/plasma/plasmoids/org.kde.plasma.kvitals/contents/scripts/sys-stats.sh
   ```

1. Check for script errors:

   ```
   journalctl -b --no-pager | grep "sys-state parse error"
   ```

Warning

If the script outputs nothing or errors, check that `awk` is installed on your system.

## Icons Not Visible on Panel

**Cause:** Icons are rendered with `isMask: true` (monochrome). If your panel background is the same color as the text color, icons may be invisible.

Tip

Try switching to a different Plasma theme, or adjust the panel opacity. You can also switch to **Text** display mode if icons aren't working well with your theme.

## Settings Dialog Shows Warnings in Journal

Harmless Warnings

You may see `cfg_*Default` warnings in the journal. These are harmless Plasma 6 KCM warnings about default property injection and **do not affect functionality**.

## Widget Not Appearing After Install

**Fix:**

1. Restart plasmashell:

   ```
   kquitapp6 plasmashell && kstart plasmashell &
   ```

1. If still missing, check the install path:

   ```
   ls ~/.local/share/plasma/plasmoids/org.kde.plasma.kvitals/
   ```

Warning

If the directory doesn't exist, the install failed. Re-run `bash install.sh` from the project directory.

## Custom Font Not Applying

**Cause:** The font name might not match exactly.

**Fix:**

1. Check available fonts: `fc-list | grep -i "font-name"`
1. In settings, use the exact family name from the dropdown
1. Font size `0` means "use system default" — set a specific value if needed

Tip

The font dropdown is searchable — start typing the font name to filter the list. You can also type a custom font name directly.
