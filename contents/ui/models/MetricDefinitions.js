.pragma library

// GROUPS describes each metric category: its default label, icon, and which
// sub-metrics are active by default. MetricConfig reads defaultSubMetrics as
// a fallback when the user hasn't saved a custom selection yet.
var GROUPS = {
    cpu: {
        id: "cpu",
        name: "CPU",
        defaultLabel: "CPU",
        defaultIcon: "am-cpu-symbolic",
        defaultSubMetrics: "usage,freq,temp",
        subs: [
            { key: "usage", label: "Usage" },
            { key: "freq",  label: "Frequency" },
            { key: "temp",  label: "Temperature" }
        ]
    },
    ram: {
        id: "ram",
        name: "RAM",
        defaultLabel: "RAM",
        defaultIcon: "nvidia-ram-symbolic",
        defaultSubMetrics: "percentage",
        subs: [
            { key: "percentage", label: "Percentage" },
            { key: "used",       label: "Used / Total" },
            { key: "temp",       label: "Temperature (DDR5)" }
        ]
    },
    swap: {
        id: "swap",
        name: "Swap",
        defaultLabel: "SWAP",
        defaultIcon: "nvidia-ram-symbolic",
        defaultSubMetrics: "percent,used",
        subs: [
            { key: "percent", label: "Usage (%)" },
            { key: "used",    label: "Used" },
            { key: "free",    label: "Free" },
            { key: "total",   label: "Total" }
        ]
    },
    temp: {
        id: "temp",
        name: "Temperature",
        defaultLabel: "System",
        defaultIcon: "temperature-normal",
        defaultSubMetrics: "temp",
        subs: []
    },
    gpu: {
        id: "gpu",
        name: "GPU",
        defaultLabel: "GPU",
        defaultIcon: "gpu-symbolic",
        defaultSubMetrics: "usage,vram,temp",
        subs: [
            { key: "usage", label: "Usage" },
            { key: "vram",  label: "VRAM" },
            { key: "temp",  label: "Temperature" },
            { key: "freq",  label: "Frequency" },
            { key: "power", label: "Power" }
        ]
    },
    bat: {
        id: "bat",
        name: "Battery",
        defaultLabel: "BAT",
        defaultIcon: "battery-good",
        defaultSubMetrics: "percentage,power",
        subs: [
            { key: "percentage", label: "Percentage" },
            { key: "power",      label: "Power consumption" }
        ]
    },
    net: {
        id: "net",
        name: "Network",
        defaultLabel: "NET",
        defaultIcon: "network-wireless",
        defaultSubMetrics: "down,up",
        subs: [
            { key: "down", label: "Download" },
            { key: "up",   label: "Upload" },
            { key: "ip",   label: "IP address" }
        ]
    },
    disk: {
        id: "disk",
        name: "Disk",
        defaultLabel: "DSK",
        defaultIcon: "am-disk-utility-symbolic",
        defaultSubMetrics: "read,write",
        subs: [
            { key: "read",  label: "Read" },
            { key: "write", label: "Write" },
            { key: "temp",  label: "Temperature" }
        ]
    },
    fan: {
        id: "fan",
        name: "Fan",
        defaultLabel: "FAN",
        defaultIcon: "am-fan-symbolic",
        defaultSubMetrics: "speed",
        subs: []
    },
    uptime: {
        id: "uptime",
        name: "System Uptime",
        defaultLabel: "UPTIME",
        defaultIcon: "clock",
        defaultSubMetrics: "uptime",
        subs: []
    }
};

// Canonical display order. MetricConfig uses this list to fill any gaps left
// by a partial metricOrder setting.
var ALL_GROUP_KEYS = ["cpu", "ram", "swap", "temp", "gpu", "bat", "net", "disk", "fan", "uptime"];

// Canonical discovery patterns for dynamic hardware devices
var PATTERNS = {
    GPU: /^gpu\/(gpu\d+)\/usage$/,
    DISK_READ: /^disk\/(nvme\d+n\d+|sd[a-z]+)\/read$/,
    DISK_TEMP: /^lmsensors\/(nvme-pci-[^/]+|drivetemp-scsi-[^/]+)\/temp[12]$/,
    FAN: /^(lmsensors|cpu|gpu)\/.*\/fan\d+$/i,
    NETWORK_IFACE: /^network\/([^/]+)\/download$/,
    TEMP_LMSENSORS: /^lmsensors\/(.+)\/temp\d+$/,
    BATTERY: /^power\/(?!all)([^\/]+)\/chargePercentage$/
};

// DEFINITIONS is the source of truth for every metric.
// MetricStore._createMetric looks up entries by "group.subKey" and merges them
// with runtime overrides supplied by the sensor layer.
//
// Fields:
//   id            - unique key, mirrors the DEFINITIONS key
//   group         - parent group (cpu, ram, gpu, ...)
//   subKey        - sub-metric within the group (usage, freq, temp, ...)
//   sensorId      - fixed ksystemstats path (single-instance metrics only)
//   sensorPattern - path template where {id} is substituted per device
//                   (multi-instance metrics: GPU, battery, network, disk, fan)
//   label         - text shown in the popup row label
//   prefix        - direction symbol shown before the value (↓ / ↑); also
//                   copied to subLabel so compact-view segments show it once
//   chartKey      - key into the chart history buffer; empty means no sparkline
//   chartMax      - fixed upper bound for the sparkline (0 = auto-scale to window)
//   thresholdType - "normal" (warn high), "inverted" (warn low), "none"
//   thresholdKey  - matches a *WarningThreshold / *CriticalThreshold in MetricConfig
//   secondaryIcon - extra icon shown beside the primary one in the popup row
//   iconOverrideKey - if present, MetricConfig[iconOverrideKey] replaces the group icon
var DEFINITIONS = {
    "cpu.usage": {
        id: "cpu.usage",
        group: "cpu",
        subKey: "usage",
        sensorId: "cpu/all/usage",
        label: "Usage",
        chartKey: "cpu",
        chartMax: 100,
        thresholdType: "normal",
        thresholdKey: "cpu"
    },
    "cpu.freq": {
        id: "cpu.freq",
        group: "cpu",
        subKey: "freq",
        sensorId: "cpu/all/averageFrequency",
        label: "Frequency",
        chartKey: "",
        chartMax: 0,
        thresholdType: "none"
    },
    "cpu.temp": {
        id: "cpu.temp",
        group: "cpu",
        subKey: "temp",
        sensorId: "cpu/all/averageTemperature",
        label: "Temperature",
        chartKey: "cpuTemp",
        chartMax: 100,
        thresholdType: "normal",
        thresholdKey: "temp",
        secondaryIcon: "temperature-normal"
    },
    "ram.percentage": {
        id: "ram.percentage",
        group: "ram",
        subKey: "percentage",
        sensorId: "memory/physical/used",
        label: "Usage",
        chartKey: "ram",
        chartMax: 100,
        thresholdType: "normal",
        thresholdKey: "ram"
    },
    // ram.used and ram.percentage both read memory/physical/used; MetricStore
    // formats one as % and the other as used/total GB.
    "ram.used": {
        id: "ram.used",
        group: "ram",
        subKey: "used",
        sensorId: "memory/physical/used",
        label: "Usage",
        chartKey: "",
        chartMax: 0,
        thresholdType: "none"
    },
    // sensorId here is not used at runtime. TempSensors.qml discovers the RAM
    // temp sensor dynamically by scanning lmsensors for any adapter whose name
    // starts with "spd5118" (the DDR5 SO-DIMM temp driver). On machines without
    // that driver (DDR4, desktops, etc.) ramTempExists stays false and MetricStore
    // skips this entry entirely.
    "ram.temp": {
        id: "ram.temp",
        group: "ram",
        subKey: "temp",
        sensorId: "lmsensors/spd5118",
        label: "Temperature",
        chartKey: "ramTemp",
        chartMax: 100,
        thresholdType: "normal",
        thresholdKey: "ramTemp",
        secondaryIcon: "temperature-normal"
    },
    "swap.percent": {
        id: "swap.percent",
        group: "swap",
        subKey: "percent",
        sensorId: "memory/swap/usedPercent",
        label: "Usage",
        chartKey: "swap",
        chartMax: 100,
        thresholdType: "normal",
        thresholdKey: "swap"
    },
    "swap.used": {
        id: "swap.used",
        group: "swap",
        subKey: "used",
        sensorId: "memory/swap/used",
        label: "Used",
        chartKey: "",
        chartMax: 0,
        thresholdType: "none"
    },
    "swap.free": {
        id: "swap.free",
        group: "swap",
        subKey: "free",
        sensorId: "memory/swap/free",
        label: "Free",
        chartKey: "",
        chartMax: 0,
        thresholdType: "none"
    },
    "swap.total": {
        id: "swap.total",
        group: "swap",
        subKey: "total",
        sensorId: "memory/swap/total",
        label: "Total",
        chartKey: "",
        chartMax: 0,
        thresholdType: "none"
    },
    "temp.system": {
        id: "temp.system",
        group: "temp",
        subKey: "temp",
        sensorId: "cpu/all/averageTemperature",
        label: "System",
        chartKey: "temp",
        chartMax: 100,
        thresholdType: "normal",
        thresholdKey: "system"
    },
    // GPU metrics use sensorPattern; MetricStore substitutes {id} per discovered GPU.
    "gpu.usage": {
        id: "gpu.usage",
        group: "gpu",
        subKey: "usage",
        sensorPattern: "gpu/{id}/usage",
        label: "Usage",
        chartKey: "gpu",
        chartMax: 100,
        thresholdType: "normal",
        thresholdKey: "gpu"
    },
    "gpu.vram": {
        id: "gpu.vram",
        group: "gpu",
        subKey: "vram",
        sensorPattern: "gpu/{id}/usedVram",
        label: "VRAM",
        chartKey: "",
        chartMax: 0,
        thresholdType: "none"
    },
    "gpu.temp": {
        id: "gpu.temp",
        group: "gpu",
        subKey: "temp",
        sensorPattern: "gpu/{id}/temperature",
        label: "Temperature",
        chartKey: "gpuTemp",
        chartMax: 100,
        thresholdType: "normal",
        thresholdKey: "gpuTemp",
        secondaryIcon: "temperature-normal"
    },
    "bat.percentage": {
        id: "bat.percentage",
        group: "bat",
        subKey: "percentage",
        sensorPattern: "power/{id}/chargePercentage",
        label: "Battery",
        chartKey: "bat",
        chartMax: 100,
        thresholdType: "inverted",
        thresholdKey: "battery"
    },
    "bat.power": {
        id: "bat.power",
        group: "bat",
        subKey: "power",
        sensorPattern: "power/{id}/chargeRate",
        label: "Power",
        chartKey: "",
        chartMax: 0,
        thresholdType: "none",
        iconOverrideKey: "powerIcon"
    },
    // prefix on net/disk entries is copied to subLabel by _createMetric so the
    // direction arrow appears in the label column, not prepended to the value.
    "net.down": {
        id: "net.down",
        group: "net",
        subKey: "down",
        sensorPattern: "network/{id}/download",
        label: "Download",
        prefix: "↓",
        chartKey: "netDown",
        chartMax: 0,
        thresholdType: "none"
    },
    "net.up": {
        id: "net.up",
        group: "net",
        subKey: "up",
        sensorPattern: "network/{id}/upload",
        label: "Upload",
        prefix: "↑",
        chartKey: "netUp",
        chartMax: 0,
        thresholdType: "none"
    },
    "net.ip": {
        id: "net.ip",
        group: "net",
        subKey: "ip",
        sensorPattern: "network/{id}/ipv4withPrefixLength",
        label: "Local IP",
        chartKey: "",
        chartMax: 0,
        thresholdType: "none"
    },
    "disk.read": {
        id: "disk.read",
        group: "disk",
        subKey: "read",
        sensorPattern: "disk/{id}/read",
        label: "Read",
        prefix: "↓",
        chartKey: "",
        chartMax: 0,
        thresholdType: "none"
    },
    "disk.write": {
        id: "disk.write",
        group: "disk",
        subKey: "write",
        sensorPattern: "disk/{id}/write",
        label: "Write",
        prefix: "↑",
        chartKey: "",
        chartMax: 0,
        thresholdType: "none"
    },
    "disk.temp": {
        id: "disk.temp",
        group: "disk",
        subKey: "temp",
        sensorPattern: "lmsensors/{id}/temp1",
        label: "Temperature",
        chartKey: "diskTemp",
        chartMax: 100,
        thresholdType: "normal",
        thresholdKey: "diskTemp",
        secondaryIcon: "temperature-normal"
    },
    // fan.speed uses a two-level pattern: {adapter} is the lmsensors chip name,
    // {id} is the fan sensor within that chip.
    "fan.speed": {
        id: "fan.speed",
        group: "fan",
        subKey: "speed",
        sensorPattern: "{adapter}/{id}/fan1",
        label: "Fan Speed",
        chartKey: "fan",
        chartMax: 0,
        thresholdType: "none"
    },
    "uptime.uptime": {
        id: "uptime.uptime",
        group: "uptime",
        subKey: "uptime",
        sensorId: "os/system/uptime",
        label: "System Uptime",
        chartKey: "",
        chartMax: 0,
        thresholdType: "none"
    }
};
