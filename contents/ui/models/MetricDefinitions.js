.pragma library

// Metric groups metadata
var GROUPS = {
    cpu: {
        id: "cpu",
        defaultLabel: "CPU",
        defaultIcon: "am-cpu-symbolic",
        defaultSubMetrics: "usage,freq,temp"
    },
    ram: {
        id: "ram",
        defaultLabel: "RAM",
        defaultIcon: "nvidia-ram-symbolic",
        defaultSubMetrics: "percentage"
    },
    temp: {
        id: "temp",
        defaultLabel: "System",
        defaultIcon: "temperature-normal",
        defaultSubMetrics: "temp"
    },
    gpu: {
        id: "gpu",
        defaultLabel: "GPU",
        defaultIcon: "gpu-symbolic",
        defaultSubMetrics: "usage,vram,temp"
    },
    bat: {
        id: "bat",
        defaultLabel: "BAT",
        defaultIcon: "battery-good",
        defaultSubMetrics: "percentage,power"
    },
    net: {
        id: "net",
        defaultLabel: "NET",
        defaultIcon: "network-wireless",
        defaultSubMetrics: "down,up"
    },
    disk: {
        id: "disk",
        defaultLabel: "DSK",
        defaultIcon: "am-disk-utility-symbolic",
        defaultSubMetrics: "read,write"
    },
    fan: {
        id: "fan",
        defaultLabel: "FAN",
        defaultIcon: "am-fan-symbolic",
        defaultSubMetrics: "speed"
    },
    uptime: {
        id: "uptime",
        defaultLabel: "UPTIME",
        defaultIcon: "clock",
        defaultSubMetrics: "uptime"
    }
};

var ALL_GROUP_KEYS = ["cpu", "ram", "temp", "gpu", "bat", "net", "disk", "fan", "uptime"];

// Authoritative metric definitions
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
