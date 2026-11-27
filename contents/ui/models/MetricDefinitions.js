.pragma library

// Mark static display strings for gettext; translate in the consuming QML context.
function I18N_NOOP(message) { return message; }

// GROUPS describes each metric category: its default label, icon, and which
// sub-metrics are active by default. MetricConfig reads defaultSubMetrics as
// a fallback when the user hasn't saved a custom selection yet.
var GROUPS = {
    cpu: {
        id: "cpu",
        name: I18N_NOOP("CPU"),
        defaultLabel: "CPU",
        defaultIcon: "cpu-symbolic",
        defaultSubMetrics: "usage,freq,temp",
        subs: [
            { key: "usage",  label: I18N_NOOP("Usage") },
            { key: "freq",   label: I18N_NOOP("Frequency") },
            { key: "temp",   label: I18N_NOOP("Temperature") },
            { key: "load1",  label: I18N_NOOP("Load (1m)") },
            { key: "load5",  label: I18N_NOOP("Load (5m)") },
            { key: "load15", label: I18N_NOOP("Load (15m)") },
            { key: "core",   label: I18N_NOOP("Cores") }
        ]
    },
    ram: {
        id: "ram",
        name: I18N_NOOP("RAM"),
        defaultLabel: "RAM",
        defaultIcon: "memory-symbolic",
        defaultSubMetrics: "percentage",
        subs: [
            { key: "percentage", label: I18N_NOOP("Percentage") },
            { key: "used",       label: I18N_NOOP("Used / Total") },
            { key: "temp",       label: I18N_NOOP("Temperature (DDR5)") }
        ]
    },
    swap: {
        id: "swap",
        name: I18N_NOOP("Swap"),
        defaultLabel: "SWAP",
        defaultIcon: "memory-symbolic",
        defaultSubMetrics: "percent,used",
        subs: [
            { key: "percent", label: I18N_NOOP("Usage (%)") },
            { key: "used",    label: I18N_NOOP("Used") },
            { key: "free",    label: I18N_NOOP("Free") },
            { key: "total",   label: I18N_NOOP("Total") }
        ]
    },
    temp: {
        id: "temp",
        name: I18N_NOOP("Temperature"),
        defaultLabel: "System",
        defaultIcon: "temperature-symbolic",
        defaultSubMetrics: "system",
        subs: [
            { key: "system",  label: I18N_NOOP("System Temperature") },
            { key: "temp",    label: I18N_NOOP("Temperature") },
            { key: "coolant", label: I18N_NOOP("Coolant") }
        ]
    },
    gpu: {
        id: "gpu",
        name: I18N_NOOP("GPU"),
        defaultLabel: "GPU",
        defaultIcon: "gpu-symbolic",
        defaultSubMetrics: "usage,vram,temp",
        subs: [
            { key: "usage", label: I18N_NOOP("Usage") },
            { key: "vram",  label: I18N_NOOP("VRAM") },
            { key: "temp",  label: I18N_NOOP("Temperature") },
            { key: "freq",  label: I18N_NOOP("Frequency") },
            { key: "power", label: I18N_NOOP("Power") }
        ]
    },
    bat: {
        id: "bat",
        name: I18N_NOOP("Battery"),
        defaultLabel: "BAT",
        defaultIcon: "battery-symbolic",
        defaultSubMetrics: "percentage,power",
        subs: [
            { key: "percentage", label: I18N_NOOP("Percentage") },
            { key: "power",      label: I18N_NOOP("Power consumption") },
            { key: "health",     label: I18N_NOOP("Health") }
        ]
    },
    net: {
        id: "net",
        name: I18N_NOOP("Network"),
        defaultLabel: "NET",
        defaultIcon: "network-symbolic",
        defaultSubMetrics: "down,up",
        subs: [
            { key: "down",      label: I18N_NOOP("Download") },
            { key: "up",        label: I18N_NOOP("Upload") },
            { key: "totalDown", label: I18N_NOOP("Total Downloaded") },
            { key: "totalUp",   label: I18N_NOOP("Total Uploaded") },
            { key: "signal",    label: I18N_NOOP("Wi-Fi Signal") },
            { key: "ip",        label: I18N_NOOP("IP address") }
        ]
    },
    disk: {
        id: "disk",
        name: I18N_NOOP("Disk"),
        defaultLabel: "DSK",
        defaultIcon: "storage-symbolic",
        defaultSubMetrics: "read,write",
        subs: [
            { key: "read",  label: I18N_NOOP("Read") },
            { key: "write", label: I18N_NOOP("Write") },
            { key: "usage", label: I18N_NOOP("Usage (%)") },
            { key: "space", label: I18N_NOOP("Space (Used/Total)") },
            { key: "temp",  label: I18N_NOOP("Temperature") }
        ]
    },
    fan: {
        id: "fan",
        name: I18N_NOOP("Fan"),
        defaultLabel: "FAN",
        defaultIcon: "fan-symbolic",
        defaultSubMetrics: "speed",
        subs: []
    },
    uptime: {
        id: "uptime",
        name: I18N_NOOP("Uptime"),
        defaultLabel: "UPTIME",
        defaultIcon: "system-symbolic",
        defaultSubMetrics: "uptime",
        subs: [
            { key: "uptime", label: I18N_NOOP("Uptime") }
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
    DISK_READ: /^disk\/(nvme\d+(?:c\d+)?n\d+|nvme\d+|sd[a-z]+|vd[a-z]+|xvd[a-z]+|mmcblk\d+)\/read$/,
    DISK_TEMP: /^(?:disk\/(?:nvme\d+(?:c\d+)?n\d+|nvme\d+|sd[a-z]+|vd[a-z]+|xvd[a-z]+|mmcblk\d+)\/temperature|lmsensors\/(?:nvme-pci-[^/]+|drivetemp-scsi-[^/]+|scsi-[^/]+|drivetemp-[^/]+)\/temp\d+)$/,
    FAN: /^(lmsensors|cpu|gpu)\/.*\/fan\d+$/i,
    COOLANT: /^lmsensors\/([^/]+)\/temp\d+$/,
    NETWORK_IFACE: /^network\/([^/]+)\/download$/,
    TEMP_LMSENSORS: /^lmsensors\/(.+)\/temp\d+$/,
    BATTERY: /^power\/(.+)\/chargePercentage$/
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
        label: I18N_NOOP("Usage"),
        thresholdType: "normal",
        thresholdKey: "cpu"
    },
    "cpu.freq": {
        id: "cpu.freq",
        group: "cpu",
        subKey: "freq",
        sensorId: "cpu/all/averageFrequency",
        label: I18N_NOOP("Frequency"),
        thresholdType: "none"
    },
    "cpu.temp": {
        id: "cpu.temp",
        group: "cpu",
        subKey: "temp",
        sensorId: "cpu/all/averageTemperature",
        label: I18N_NOOP("Temperature"),
        thresholdType: "normal",
        thresholdKey: "temp",
        secondaryIcon: "temperature-normal"
    },
    "cpu.load1": {
        id: "cpu.load1",
        group: "cpu",
        subKey: "load1",
        sensorId: "cpu/loadaverages/loadaverage1",
        label: I18N_NOOP("Load (1m)"),
        thresholdType: "none"
    },
    "cpu.load5": {
        id: "cpu.load5",
        group: "cpu",
        subKey: "load5",
        sensorId: "cpu/loadaverages/loadaverage5",
        label: I18N_NOOP("Load (5m)"),
        thresholdType: "none"
    },
    "cpu.load15": {
        id: "cpu.load15",
        group: "cpu",
        subKey: "load15",
        sensorId: "cpu/loadaverages/loadaverage15",
        label: I18N_NOOP("Load (15m)"),
        thresholdType: "none"
    },
    "cpu.core": {
        id: "cpu.core",
        group: "cpu",
        subKey: "core",
        sensorPattern: "cpu/{id}/usage",
        label: I18N_NOOP("Core Usage"),
        thresholdType: "normal",
        thresholdKey: "cpu"
    },
    "ram.percentage": {
        id: "ram.percentage",
        group: "ram",
        subKey: "percentage",
        sensorId: "memory/physical/used",
        label: I18N_NOOP("Percentage"),
        thresholdType: "normal",
        thresholdKey: "ram"
    },
    "ram.used": {
        id: "ram.used",
        group: "ram",
        subKey: "used",
        sensorId: "memory/physical/used",
        label: I18N_NOOP("Used / Total"),
        thresholdType: "none"
    },
    "ram.temp": {
        id: "ram.temp",
        group: "ram",
        subKey: "temp",
        sensorId: "lmsensors/spd5118",
        label: I18N_NOOP("Temperature"),
        thresholdType: "normal",
        thresholdKey: "ramTemp",
        secondaryIcon: "temperature-normal"
    },
    "swap.percent": {
        id: "swap.percent",
        group: "swap",
        subKey: "percent",
        sensorId: "memory/swap/usedPercent",
        label: I18N_NOOP("Usage (%)"),
        thresholdType: "normal",
        thresholdKey: "swap"
    },
    "swap.used": {
        id: "swap.used",
        group: "swap",
        subKey: "used",
        sensorId: "memory/swap/used",
        label: I18N_NOOP("Used"),
        thresholdType: "none"
    },
    "swap.free": {
        id: "swap.free",
        group: "swap",
        subKey: "free",
        sensorId: "memory/swap/free",
        label: I18N_NOOP("Free"),
        thresholdType: "none"
    },
    "swap.total": {
        id: "swap.total",
        group: "swap",
        subKey: "total",
        sensorId: "memory/swap/total",
        label: I18N_NOOP("Total"),
        thresholdType: "none"
    },
    "temp.system": {
        id: "temp.system",
        group: "temp",
        subKey: "system",
        sensorId: "cpu/all/averageTemperature",
        label: I18N_NOOP("System"),
        thresholdType: "normal",
        thresholdKey: "system"
    },
    "temp.temp": {
        id: "temp.temp",
        group: "temp",
        subKey: "temp",
        sensorPattern: "lmsensors/{id}/temp1",
        label: I18N_NOOP("Temperature"),
        thresholdType: "normal",
        thresholdKey: "system",
        icon: "temperature-symbolic"
    },
    "temp.coolant": {
        id: "temp.coolant",
        group: "temp",
        subKey: "coolant",
        sensorPattern: "lmsensors/{adapter}/temp{n}",
        label: I18N_NOOP("Coolant"),
        thresholdType: "normal",
        thresholdKey: "coolantTemp",
        secondaryIcon: "temperature-normal"
    },
    "gpu.usage": {
        id: "gpu.usage",
        group: "gpu",
        subKey: "usage",
        sensorPattern: "gpu/{id}/usage",
        label: I18N_NOOP("Usage"),
        thresholdType: "normal",
        thresholdKey: "gpu"
    },
    "gpu.vram": {
        id: "gpu.vram",
        group: "gpu",
        subKey: "vram",
        sensorPattern: "gpu/{id}/usedVram",
        label: I18N_NOOP("VRAM"),
        thresholdType: "none"
    },
    "gpu.temp": {
        id: "gpu.temp",
        group: "gpu",
        subKey: "temp",
        sensorPattern: "gpu/{id}/temperature",
        label: I18N_NOOP("Temperature"),
        thresholdType: "normal",
        thresholdKey: "gpuTemp",
        secondaryIcon: "temperature-normal"
    },
    "gpu.freq": {
        id: "gpu.freq",
        group: "gpu",
        subKey: "freq",
        sensorPattern: "gpu/{id}/coreFrequency",
        label: I18N_NOOP("Frequency"),
        thresholdType: "none"
    },
    "gpu.power": {
        id: "gpu.power",
        group: "gpu",
        subKey: "power",
        sensorPattern: "gpu/{id}/power",
        label: I18N_NOOP("Power"),
        thresholdType: "none"
    },
    "bat.percentage": {
        id: "bat.percentage",
        group: "bat",
        subKey: "percentage",
        sensorPattern: "power/{id}/chargePercentage",
        label: I18N_NOOP("Percentage"),
        thresholdType: "inverted",
        thresholdKey: "battery"
    },
    "bat.power": {
        id: "bat.power",
        group: "bat",
        subKey: "power",
        sensorPattern: "power/{id}/chargeRate",
        label: I18N_NOOP("Power"),
        thresholdType: "none",
        iconOverrideKey: "powerIcon"
    },
    "bat.health": {
        id: "bat.health",
        group: "bat",
        subKey: "health",
        sensorPattern: "power/{id}/health",
        label: I18N_NOOP("Health"),
        thresholdType: "inverted",
        thresholdKey: "battery"
    },
    "net.down": {
        id: "net.down",
        group: "net",
        subKey: "down",
        sensorPattern: "network/{id}/download",
        label: I18N_NOOP("Download"),
        icon: "network-download-symbolic",
        thresholdType: "none"
    },
    "net.up": {
        id: "net.up",
        group: "net",
        subKey: "up",
        sensorPattern: "network/{id}/upload",
        label: I18N_NOOP("Upload"),
        icon: "network-upload-symbolic",
        thresholdType: "none"
    },
    "net.ip": {
        id: "net.ip",
        group: "net",
        subKey: "ip",
        sensorPattern: "network/{id}/ipv4withPrefixLength",
        label: I18N_NOOP("Local IP"),
        icon: "network-symbolic",
        thresholdType: "none"
    },
    "net.signal": {
        id: "net.signal",
        group: "net",
        subKey: "signal",
        sensorPattern: "network/{id}/signal",
        label: I18N_NOOP("Wi-Fi Signal"),
        icon: "network-wireless-symbolic",
        thresholdType: "inverted",
        thresholdKey: "battery"
    },
    "net.totalDown": {
        id: "net.totalDown",
        group: "net",
        subKey: "totalDown",
        sensorPattern: "network/{id}/totalDownload",
        label: I18N_NOOP("Total Downloaded"),
        icon: "network-download-symbolic",
        thresholdType: "none"
    },
    "net.totalUp": {
        id: "net.totalUp",
        group: "net",
        subKey: "totalUp",
        sensorPattern: "network/{id}/totalUpload",
        label: I18N_NOOP("Total Uploaded"),
        icon: "network-upload-symbolic",
        thresholdType: "none"
    },
    "disk.read": {
        id: "disk.read",
        group: "disk",
        subKey: "read",
        sensorPattern: "disk/{id}/read",
        label: I18N_NOOP("Read"),
        icon: "network-download-symbolic",
        thresholdType: "none"
    },
    "disk.write": {
        id: "disk.write",
        group: "disk",
        subKey: "write",
        sensorPattern: "disk/{id}/write",
        label: I18N_NOOP("Write"),
        icon: "network-upload-symbolic",
        thresholdType: "none"
    },
    "disk.usage": {
        id: "disk.usage",
        group: "disk",
        subKey: "usage",
        sensorId: "disk/all/usedPercent",
        label: I18N_NOOP("Usage"),
        thresholdType: "normal",
        thresholdKey: "disk"
    },
    "disk.space": {
        id: "disk.space",
        group: "disk",
        subKey: "space",
        sensorId: "disk/all/used",
        label: I18N_NOOP("Space"),
        thresholdType: "none"
    },
    "disk.temp": {
        id: "disk.temp",
        group: "disk",
        subKey: "temp",
        sensorPattern: "disk/{id}/temperature",
        label: I18N_NOOP("Temperature"),
        thresholdType: "normal",
        thresholdKey: "diskTemp",
        secondaryIcon: "temperature-normal"
    },
    "fan.speed": {
        id: "fan.speed",
        group: "fan",
        subKey: "speed",
        sensorPattern: "{adapter}/{id}/fan1",
        label: I18N_NOOP("Fan Speed"),
        thresholdType: "none"
    },
    "uptime.uptime": {
        id: "uptime.uptime",
        group: "uptime",
        subKey: "uptime",
        sensorId: "os/system/uptime",
        label: I18N_NOOP("Uptime"),
        thresholdType: "none"
    }
};

function buildInstanceId(group, deviceId, subKey) {
    if (deviceId && typeof deviceId === "string" && deviceId.length > 0) {
        return group + ":" + deviceId + "/" + subKey;
    }
    return group + "/" + subKey;
}
