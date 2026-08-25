.pragma library

// GROUPS describes each metric category: its default label, icon, and which
// sub-metrics are active by default. MetricConfig reads defaultSubMetrics as
// a fallback when the user hasn't saved a custom selection yet.
var GROUPS = {
    cpu: {
        id: "cpu",
        name: "CPU",
        defaultLabel: "CPU",
        defaultIcon: "cpu-symbolic",
        defaultSubMetrics: "usage,freq,temp",
        subs: [
            { key: "usage",  label: "Usage" },
            { key: "freq",   label: "Frequency" },
            { key: "temp",   label: "Temperature" },
            { key: "load1",  label: "Load (1m)" },
            { key: "load5",  label: "Load (5m)" },
            { key: "load15", label: "Load (15m)" },
            { key: "core",   label: "Cores" }
        ]
    },
    ram: {
        id: "ram",
        name: "RAM",
        defaultLabel: "RAM",
        defaultIcon: "memory-symbolic",
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
        defaultIcon: "memory-symbolic",
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
        defaultIcon: "temperature-symbolic",
        defaultSubMetrics: "system",
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
        defaultIcon: "battery-symbolic",
        defaultSubMetrics: "percentage,power",
        subs: [
            { key: "percentage", label: "Percentage" },
            { key: "power",      label: "Power consumption" },
            { key: "health",     label: "Health" }
        ]
    },
    net: {
        id: "net",
        name: "Network",
        defaultLabel: "NET",
        defaultIcon: "network-symbolic",
        defaultSubMetrics: "down,up",
        subs: [
            { key: "down",      label: "Download" },
            { key: "up",        label: "Upload" },
            { key: "totalDown", label: "Total Downloaded" },
            { key: "totalUp",   label: "Total Uploaded" },
            { key: "signal",    label: "Wi-Fi Signal" },
            { key: "ip",        label: "IP address" }
        ]
    },
    disk: {
        id: "disk",
        name: "Disk",
        defaultLabel: "DSK",
        defaultIcon: "storage-symbolic",
        defaultSubMetrics: "read,write",
        subs: [
            { key: "read",  label: "Read" },
            { key: "write", label: "Write" },
            { key: "usage", label: "Usage (%)" },
            { key: "space", label: "Space (Used/Total)" },
            { key: "temp",  label: "Temperature" }
        ]
    },
    fan: {
        id: "fan",
        name: "Fan",
        defaultLabel: "FAN",
        defaultIcon: "fan-symbolic",
        defaultSubMetrics: "speed",
        subs: []
    },
    uptime: {
        id: "uptime",
        name: "Uptime",
        defaultLabel: "UPTIME",
        defaultIcon: "system-symbolic",
        defaultSubMetrics: "uptime",
        subs: [
            { key: "uptime", label: "Uptime" }
        ]
    }
};

var ALL_GROUP_KEYS = ["cpu", "ram", "swap", "temp", "gpu", "bat", "net", "disk", "fan", "uptime"];

var BUNDLED_ICONS = [
    "battery-symbolic",
    "cpu-symbolic",
    "fan-symbolic",
    "gpu-symbolic",
    "memory-symbolic",
    "network-download-symbolic",
    "network-symbolic",
    "network-upload-symbolic",
    "network-wireless-symbolic",
    "storage-symbolic",
    "system-symbolic",
    "temperature-symbolic",
    "voltage-symbolic"
];

function isBundledIcon(name) {
    if (!name) return false;
    return BUNDLED_ICONS.indexOf(String(name)) !== -1;
}

// Canonical discovery patterns for dynamic hardware devices
var PATTERNS = {
    CPU_CORE: /^cpu\/(cpu\d+)\/usage$/,
    GPU: /^gpu\/(gpu\d+)\/usage$/,
    DISK_READ: /^disk\/(nvme\d+n\d+|sd[a-z]+)\/read$/,
    DISK_TEMP: /^disk\/(nvme\d+n\d+|sd[a-z]+)\/temperature$/,
    FAN: /^(lmsensors|cpu|gpu)\/.*\/fan\d+$/i,
    NETWORK_IFACE: /^network\/([^/]+)\/download$/,
    TEMP_LMSENSORS: /^lmsensors\/(.+)\/temp\d+$/,
    BATTERY: /^power\/((?:battery_)[a-zA-Z0-9_-]+|BAT\d+|BATT\d*)\/chargePercentage$/
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
        thresholdType: "normal",
        thresholdKey: "cpu"
    },
    "cpu.freq": {
        id: "cpu.freq",
        group: "cpu",
        subKey: "freq",
        sensorId: "cpu/all/averageFrequency",
        label: "Frequency",
        thresholdType: "none"
    },
    "cpu.temp": {
        id: "cpu.temp",
        group: "cpu",
        subKey: "temp",
        sensorId: "cpu/all/averageTemperature",
        label: "Temperature",
        thresholdType: "normal",
        thresholdKey: "temp",
        secondaryIcon: "temperature-normal"
    },
    "cpu.load1": {
        id: "cpu.load1",
        group: "cpu",
        subKey: "load1",
        sensorId: "cpu/loadaverages/loadaverage1",
        label: "Load (1m)",
        thresholdType: "none"
    },
    "cpu.load5": {
        id: "cpu.load5",
        group: "cpu",
        subKey: "load5",
        sensorId: "cpu/loadaverages/loadaverage5",
        label: "Load (5m)",
        thresholdType: "none"
    },
    "cpu.load15": {
        id: "cpu.load15",
        group: "cpu",
        subKey: "load15",
        sensorId: "cpu/loadaverages/loadaverage15",
        label: "Load (15m)",
        thresholdType: "none"
    },
    "cpu.core": {
        id: "cpu.core",
        group: "cpu",
        subKey: "core",
        sensorPattern: "cpu/{id}/usage",
        label: "Core Usage",
        thresholdType: "normal",
        thresholdKey: "cpu"
    },
    "ram.percentage": {
        id: "ram.percentage",
        group: "ram",
        subKey: "percentage",
        sensorId: "memory/physical/used",
        label: "Percentage",
        thresholdType: "normal",
        thresholdKey: "ram"
    },
    "ram.used": {
        id: "ram.used",
        group: "ram",
        subKey: "used",
        sensorId: "memory/physical/used",
        label: "Used / Total",
        thresholdType: "none"
    },
    "ram.temp": {
        id: "ram.temp",
        group: "ram",
        subKey: "temp",
        sensorId: "lmsensors/spd5118",
        label: "Temperature",
        thresholdType: "normal",
        thresholdKey: "ramTemp",
        secondaryIcon: "temperature-normal"
    },
    "swap.percent": {
        id: "swap.percent",
        group: "swap",
        subKey: "percent",
        sensorId: "memory/swap/usedPercent",
        label: "Usage (%)",
        thresholdType: "normal",
        thresholdKey: "swap"
    },
    "swap.used": {
        id: "swap.used",
        group: "swap",
        subKey: "used",
        sensorId: "memory/swap/used",
        label: "Used",
        thresholdType: "none"
    },
    "swap.free": {
        id: "swap.free",
        group: "swap",
        subKey: "free",
        sensorId: "memory/swap/free",
        label: "Free",
        thresholdType: "none"
    },
    "swap.total": {
        id: "swap.total",
        group: "swap",
        subKey: "total",
        sensorId: "memory/swap/total",
        label: "Total",
        thresholdType: "none"
    },
    "temp.system": {
        id: "temp.system",
        group: "temp",
        subKey: "system",
        sensorId: "cpu/all/averageTemperature",
        label: "System",
        thresholdType: "normal",
        thresholdKey: "system"
    },
    "gpu.usage": {
        id: "gpu.usage",
        group: "gpu",
        subKey: "usage",
        sensorPattern: "gpu/{id}/usage",
        label: "Usage",
        thresholdType: "normal",
        thresholdKey: "gpu"
    },
    "gpu.vram": {
        id: "gpu.vram",
        group: "gpu",
        subKey: "vram",
        sensorPattern: "gpu/{id}/usedVram",
        label: "VRAM",
        thresholdType: "none"
    },
    "gpu.temp": {
        id: "gpu.temp",
        group: "gpu",
        subKey: "temp",
        sensorPattern: "gpu/{id}/temperature",
        label: "Temperature",
        thresholdType: "normal",
        thresholdKey: "gpuTemp",
        secondaryIcon: "temperature-normal"
    },
    "gpu.freq": {
        id: "gpu.freq",
        group: "gpu",
        subKey: "freq",
        sensorPattern: "gpu/{id}/coreFrequency",
        label: "Frequency",
        thresholdType: "none"
    },
    "gpu.power": {
        id: "gpu.power",
        group: "gpu",
        subKey: "power",
        sensorPattern: "gpu/{id}/power",
        label: "Power",
        thresholdType: "none"
    },
    "bat.percentage": {
        id: "bat.percentage",
        group: "bat",
        subKey: "percentage",
        sensorPattern: "power/{id}/chargePercentage",
        label: "Percentage",
        thresholdType: "inverted",
        thresholdKey: "battery"
    },
    "bat.power": {
        id: "bat.power",
        group: "bat",
        subKey: "power",
        sensorPattern: "power/{id}/chargeRate",
        label: "Power",
        thresholdType: "none",
        iconOverrideKey: "powerIcon"
    },
    "bat.health": {
        id: "bat.health",
        group: "bat",
        subKey: "health",
        sensorPattern: "power/{id}/health",
        label: "Health",
        thresholdType: "inverted",
        thresholdKey: "battery"
    },
    "net.down": {
        id: "net.down",
        group: "net",
        subKey: "down",
        sensorPattern: "network/{id}/download",
        label: "Download",
        icon: "network-download-symbolic",
        thresholdType: "none"
    },
    "net.up": {
        id: "net.up",
        group: "net",
        subKey: "up",
        sensorPattern: "network/{id}/upload",
        label: "Upload",
        icon: "network-upload-symbolic",
        thresholdType: "none"
    },
    "net.ip": {
        id: "net.ip",
        group: "net",
        subKey: "ip",
        sensorPattern: "network/{id}/ipv4withPrefixLength",
        label: "Local IP",
        icon: "network-symbolic",
        thresholdType: "none"
    },
    "net.signal": {
        id: "net.signal",
        group: "net",
        subKey: "signal",
        sensorPattern: "network/{id}/signal",
        label: "Wi-Fi Signal",
        icon: "network-wireless-symbolic",
        thresholdType: "inverted",
        thresholdKey: "battery"
    },
    "net.totalDown": {
        id: "net.totalDown",
        group: "net",
        subKey: "totalDown",
        sensorPattern: "network/{id}/totalDownload",
        label: "Total Downloaded",
        icon: "network-download-symbolic",
        thresholdType: "none"
    },
    "net.totalUp": {
        id: "net.totalUp",
        group: "net",
        subKey: "totalUp",
        sensorPattern: "network/{id}/totalUpload",
        label: "Total Uploaded",
        icon: "network-upload-symbolic",
        thresholdType: "none"
    },
    "disk.read": {
        id: "disk.read",
        group: "disk",
        subKey: "read",
        sensorPattern: "disk/{id}/read",
        label: "Read",
        icon: "network-download-symbolic",
        thresholdType: "none"
    },
    "disk.write": {
        id: "disk.write",
        group: "disk",
        subKey: "write",
        sensorPattern: "disk/{id}/write",
        label: "Write",
        icon: "network-upload-symbolic",
        thresholdType: "none"
    },
    "disk.usage": {
        id: "disk.usage",
        group: "disk",
        subKey: "usage",
        sensorId: "disk/all/usedPercent",
        label: "Usage",
        thresholdType: "normal",
        thresholdKey: "disk"
    },
    "disk.space": {
        id: "disk.space",
        group: "disk",
        subKey: "space",
        sensorId: "disk/all/used",
        label: "Space",
        thresholdType: "none"
    },
    "disk.temp": {
        id: "disk.temp",
        group: "disk",
        subKey: "temp",
        sensorPattern: "disk/{id}/temperature",
        label: "Temperature",
        thresholdType: "normal",
        thresholdKey: "diskTemp",
        secondaryIcon: "temperature-normal"
    },
    "fan.speed": {
        id: "fan.speed",
        group: "fan",
        subKey: "speed",
        sensorPattern: "{adapter}/{id}/fan1",
        label: "Fan Speed",
        thresholdType: "none"
    },
    "uptime.uptime": {
        id: "uptime.uptime",
        group: "uptime",
        subKey: "uptime",
        sensorId: "os/system/uptime",
        label: "Uptime",
        thresholdType: "none"
    }
};

function buildInstanceId(group, deviceId, subKey) {
    if (deviceId && typeof deviceId === "string" && deviceId.length > 0) {
        return group + ":" + deviceId + "/" + subKey;
    }
    return group + "/" + subKey;
}
