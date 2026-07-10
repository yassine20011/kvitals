# CPU Power Draw (RAPL)

## Overview

KVitals now includes CPU power consumption monitoring using Intel Running Average Power Limit (RAPL). This feature displays real-time CPU power draw in watts directly in the widget.

## How It Works

The feature reads energy data from the Intel RAPL interface (`/sys/class/powercap/intel-rapl:0/energy_uj`) and calculates power consumption by measuring the energy delta over time:

```
Power (W) = ΔEnergy (µJ) / ΔTime (µs)
```

This provides an accurate measurement of CPU power draw that includes all processor cores on the same power domain.

## System Requirements

- **Intel CPU** with RAPL support (most Intel processors from Sandy Bridge onwards)
- **AMD CPU** with the Zenergy DKMS module installed
- RAPL interface exposed at `/sys/class/powercap/intel-rapl:0/energy_uj`
- Sufficient read permissions to the RAPL energy file

## Permissions Setup

By default, the RAPL interface file is only readable by root. You need to grant read permission to regular users.

### Setup (One-time, Automatic)

Run the provided setup script to make the RAPL file readable and auto-restore permissions at boot:

```bash
cd kvitals
sudo bash setup-rapl-udev.sh
```

This will:
1. Make the RAPL file readable immediately
2. Create a systemd service to auto-restore permissions at every boot
3. Enable the service

**After setup:**
- Restart Plasma: `kquitapp6 plasmashell && kstart plasmashell &`
- The widget will work without any password prompts
- Permissions will automatically persist across reboots

### Manual Setup (if preferred)

Make the file readable once:

```bash
sudo chmod 644 /sys/class/powercap/intel-rapl:0/energy_uj
```

For automatic restoration at boot, create `/etc/systemd/system/rapl-chmod.service`:

```ini
[Unit]
Description=Make RAPL file readable for KVitals
Before=display-manager.service
DefaultDependencies=no

[Service]
Type=oneshot
ExecStart=/bin/chmod 644 /sys/class/powercap/intel-rapl:0/energy_uj

[Install]
WantedBy=multi-user.target
```

Then enable it:

```bash
sudo systemctl daemon-reload
sudo systemctl enable rapl-chmod.service
```

## Display Locations

When CPU Power is enabled, the power draw appears combined with CPU usage:

```
CPU: 45% (12.34W)
```

Shows both the usage percentage and power draw in watts.

## Configuration

### Enabling/Disabling

CPU power monitoring is **disabled by default**. To enable it:

1. First, run the setup script to configure RAPL permissions (see **Permissions Setup** above)
2. Right-click the widget and select "Configure"
3. Under CPU, check the "Show power draw" option
4. Apply the changes

The feature will start working immediately once RAPL permissions are configured.

### Update Interval

The power data is sampled at the same interval as other metrics (configurable, default 2000ms).

## Troubleshooting

### Power draw not appearing

1. **Check RAPL support**: Verify your CPU supports RAPL
   ```bash
   test -f /sys/class/powercap/intel-rapl:0/energy_uj && echo "RAPL supported" || echo "RAPL not available"
   ```

2. **Check current permissions**: See if the file is readable
   ```bash
   cat /sys/class/powercap/intel-rapl:0/energy_uj
   ```
   - If readable, the feature should work
   - If "Permission denied", run the setup script: `sudo bash setup-rapl-udev.sh`

3. **Verify settings**: Make sure "Show power draw" is checked under CPU configuration

### High initial power readings

The first few measurements after startup may be inaccurate. This stabilizes within 2-3 update cycles (4-6 seconds with default settings).

## Performance Impact

The CPU power monitoring has minimal overhead:
- Single file read per update cycle (default every 2000ms)
- Simple arithmetic calculation
- No runtime password prompts (permissions configured at setup time)

## See Also

- [Intel Running Average Power Limit (RAPL) Documentation](https://github.com/torvalds/linux/blob/master/drivers/powercap/intel_rapl.c)
- [Linux Power Management](https://www.kernel.org/doc/html/latest/power/index.html)
