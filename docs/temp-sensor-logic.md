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
   - `spd5118` → DDR5 RAM (separate sensor)
   - `-isa-` in adapter name AND not `coretemp` → Super I/O chipset candidate
   - Everything else (PCI bus: k10temp, amdgpu, nvme, etc.) → deliberately ignored
5. Read `Qt::DisplayRole` (lm-sensors label, e.g. `SYSTIN`, `CPUTIN`, `AUXTIN0`)
6. When multiple ISA channels exist, exclude candidates whose label matches
   `/^(cputin|auxtin|peci|smbusmaster)/i` — these are CPU-adjacent or auxiliary
   sensors, not chipset board temperature
7. Pick the first remaining candidate as `_systemSensorId`

#### Why ISA bus?

Super I/O chips (Nuvoton nct6799, ITE it87*, Winbond w83627*, Fintek f71869\*)
— the real chipset/motherboard temperature sensors — are always on the
LPC/ISA bus, so their lm-sensors adapter name contains `-isa-`.

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

## Three Independent Sensors

| Display              | QML Property        | Sensor ID                                           | Source          |
| -------------------- | ------------------- | --------------------------------------------------- | --------------- |
| System Temperature   | `temp.tempValue`    | chipset auto-detect or `cpu/all/averageTemperature` | `sysSensor`     |
| CPU Temperature      | `temp.cpuTempValue` | `cpu/all/averageTemperature`                        | `cpuTempSensor` |
| DDR5 RAM Temperature | `temp.ramTempValue` | `lmsensors/spd5118-*/temp1`                         | `ramSensor`     |

- `sysIsFallback = true` when System Temperature falls back to CPU
- The "No chipset temp sensor detected" label in settings is controlled by
  `Plasmoid.configuration._tempFallbackActive`
- Changes to the sensor tree (e.g., hot-plugging a hwmon module) trigger
  `refreshDiscovered()` via `onRowsInserted`/`onRowsRemoved`/`onModelReset`
  signals from `KDescendantsProxyModel`
