# Temperature Sensor Detection Logic

## KSystemStats Sensor Tree Structure

KSystemStats organizes sensors in a three-level hierarchy exposed through
`SensorTreeModel` (QML: `import org.kde.ksysguard.sensors as Sensors`):

```
category/object/property
```

Examples:

| Sensor ID                          | Category  | Object           | Property           |
| ---------------------------------- | --------- | ---------------- | ------------------ |
| `cpu/all/averageTemperature`       | cpu       | all              | averageTemperature |
| `cpu/cpu3/temperature`             | cpu       | cpu3             | temperature        |
| `gpu/gpu0/temperature`             | gpu       | gpu0             | temperature        |
| `lmsensors/nct6799-isa-0290/temp1` | lmsensors | nct6799-isa-0290 | temp1              |
| `lmsensors/spd5118-i2c-3-51/temp1` | lmsensors | spd5118-i2c-3-51 | temp1              |
| `lmsensors/nvme-pci-0200/temp1`    | lmsensors | nvme-pci-0200    | temp1              |

Categories: `cpu`, `gpu`, `lmsensors`, `memory`, `disk`, `network`, `os`, etc.

The QML uses `KDescendantsProxyModel` to flatten the tree into a list,
then iterates rows, reading `SensorId` via
`flatSensors.data(idx, Sensors.SensorTreeModel.SensorId)`.

## Chipset Sensor Discovery (`TempSensors.qml`)

### Strategy

1. Iterate all flat sensors
2. Skip `cpu/*` and `gpu/*` paths
3. Match `lmsensors/(.+)/temp\d+`
4. Filter adapter name:
   - `spd5118` / `jc42` → DDR5/DDR4 RAM (separate sensor)
   - `pch_*` → Intel Platform Controller Hub thermal driver (Priority 1)
   - `-isa-` in adapter name AND not `coretemp` → Super I/O chipset candidate (Priority 2)
   - Everything else (PCI bus: k10temp, amdgpu, nvme, etc.) → deliberately ignored
5. Read `Qt::DisplayRole` (lm-sensors label, e.g. `SYSTIN`, `CPUTIN`, `AUXTIN0`)
6. When multiple ISA channels exist, exclude candidates whose label matches
   `/^(cputin|auxtin|peci|smbusmaster)/i` — these are CPU-adjacent or auxiliary
   sensors, not chipset board temperature
7. Prioritize Intel PCH over ISA Super I/O, picking the highest-priority candidate as `_systemSensorId`

#### Why ISA bus and PCH?

Super I/O chips (Nuvoton nct6799, ITE it87*, Winbond w83627*, Fintek f71869*)
— the motherboard temperature sensors — are on the LPC/ISA bus, so their
lm-sensors adapter name contains `-isa-`. Intel chipsets expose their thermal
readings through the dedicated `pch_*` thermal driver.

CPU temperature drivers live on PCI:

- AMD: `k10temp-pci-*`, `zenpower-pci-*`
- Intel: `coretemp-isa-*` (exception — uses ISA bus but is a CPU sensor)

GPU drivers also live on PCI:

- AMD: `amdgpu-pci-*`
- NVIDIA: `nvidia-pci-*`

Drives, WiFi, Ethernet are all on PCI.

#### Excluding Intel coretemp

Intel's `coretemp` driver also registers on the ISA bus (`coretemp-isa-*`),
so we explicitly exclude adapter names starting with `coretemp`.

#### Fallback

No ISA candidates → `sysIsFallback = true`, uses `cpu/all/averageTemperature`.
PCI candidates are never selected as chipset — they'd report CPU/GPU temps
masquerading as "system temperature".

### Fallback

If no chipset sensor found AND the tree has rows, `_systemSensorId` stays
empty and `sysIsFallback = true`. The `sysSensor` falls back to
`cpu/all/averageTemperature`.

### Dedicated CPU Temperature

`cpuTempValue` always reads `cpu/all/averageTemperature` directly,
independent of the chipset discovery. This ensures the "CPU Temperature"
sub-metric correctly shows CPU temp even when the System temperature
switches to a chipset sensor.

## Hardware Temperature Sensors

| Display              | QML Property        | Sensor ID                                           | Source                 |
| -------------------- | ------------------- | --------------------------------------------------- | ---------------------- |
| System Temperature   | `temp.tempValue`    | chipset auto-detect or `cpu/all/averageTemperature` | `sysSensor`            |
| CPU Temperature      | `temp.cpuTempValue` | `cpu/all/averageTemperature`                        | `cpuTempSensor`        |
| DDR5 RAM Temperature | `temp.ramTempValue` | `lmsensors/spd5118-*/temp1`, `jc42`                  | `ramSensor`            |
| Disk Temperatures    | `disk.temp`         | `disk/<deviceId>/temperature` or `lmsensors/*`      | `DiskSensors.qml`      |
| Coolant Temperatures | `temp.coolant`      | `lmsensors/<chip>/tempN` labelled "Coolant…"        | `CoolantSensors.qml`   |

- `sysIsFallback = true` when System Temperature falls back to CPU
- The "No chipset temp sensor detected" label in settings is controlled by
  `Plasmoid.configuration._tempFallbackActive`
- Changes to the sensor tree trigger `refreshDiscovered()` via `discovery.onRevisionChanged`

## Disk Temperature Discovery (`DiskSensors.qml`)

KVitals binds disk temperatures on a per-device basis:

1. **Direct Path (Preferred)**: `disk/<deviceId>/temperature` exposed natively by KSystemStats.
2. **NVMe Controller Fallback**: `lmsensors/nvme-pci-*/temp1` mapped deterministically to physical NVMe controllers. Namespaces (e.g. `nvme0n1`, `nvme0n2`) share the physical controller's sensor.
3. **SATA/SCSI Fallback**: `lmsensors/drivetemp-scsi-*/temp1` provided by the Linux `drivetemp` kernel driver. SCSI host/target topology maps to drive letters (`sda`, `sdb`). Unknown or unmatched drives return no temperature without cross-assignment.

## Coolant Temperature Discovery (`HardwareDiscovery.qml` → `CoolantSensors.qml`)

AIO coolers and pumps expose their liquid temperature through HID hwmon drivers,
which KSystemStats publishes under the `lmsensors` category:

| Kernel driver          | Example sensor ID                      | Label          |
| ---------------------- | -------------------------------------- | -------------- |
| `asus_rog_ryujin`      | `lmsensors/rog_ryujin-hid-3-d/temp1`   | `Coolant temp` |
| `nzxt-kraken3`         | `lmsensors/x53-hid-3-9/temp1`          | `Coolant temp` |
| `nzxt-kraken2`         | `lmsensors/kraken2-hid-3-7/temp1`      | `Coolant`      |
| `gigabyte_waterforce`  | `lmsensors/waterforce-hid-3-5/temp1`   | `Coolant temp` |
| `aquacomputer_d5next`  | `lmsensors/d5next-hid-3-8/temp1`       | `Coolant temp` |

1. **Match**: sensor ID matches `PATTERNS.COOLANT` (`lmsensors/<chip>/tempN`) **and**
   its `Qt::DisplayRole` label matches `/coolant/i`. The adapter name alone is not
   used, so any driver that labels its sensor as coolant is supported.
2. **Stable device ID**: the lm-sensors bus suffix is stripped from the chip name
   (`rog_ryujin-hid-3-d` → `rog_ryujin`). The HID suffix depends on device
   enumeration order and can change across reboots or replugs, which would otherwise
   orphan pinned metrics (`temp:rog_ryujin/coolant`) and custom labels. When several
   identical coolers are present, each keeps its full chip name
   (`rog_ryujin-hid-3-d`, `rog_ryujin-hid-3-e`), so an ID is never handed over to
   another cooler when one is removed. Identical units cannot be told apart more
   stably than that through KSystemStats.
3. **Naming**: `Coolant` for a single sensor, `Coolant 1`, `Coolant 2`, … for several;
   overridden by `coolantLabels` (Settings → Sensors & Hardware → Temperature).
4. **Thresholds**: `coolantTempWarningThreshold` / `coolantTempCriticalThreshold`
   (defaults 40 °C / 50 °C).
