export const COLORS = Object.freeze({
    base: "#ffffff",
    warning: "#e5a50a",
    critical: "#da4453"
});

export const SENSOR_IDS = Object.freeze({
    cpuOverall: "cpu/all/usage",
    cpuCores: ["cpu/cpu10/usage", "cpu/cpu2/usage", "cpu/cpu0/usage"],
    gpus: ["gpu/gpu1/usage", "gpu/gpu0/usage"],
    disks: ["disk/nvme0n1/read", "disk/sda/read"],
    ignoredDisk: "disk/all/read",
    networks: ["network/wlan0/download", "network/lo/download", "network/all/download"],
    battery: "power/BAT0/chargePercentage",
    fan: "lmsensors/it8688-isa-0a30/fan1",
    diskTemperature: "disk/nvme0n1/temperature"
});

export const SYSFS = Object.freeze({
    nvme0: "nvme0n1:nvme:/sys/devices/pci0000:00/0000:00:1d.0/0000:01:00.0/nvme/nvme0",
    nvme2: "nvme2n1:nvme:/sys/devices/pci0000:00/0000:00:1d.0/0000:04:00.0/nvme/nvme2",
    sata0: "sda:drivetemp:/sys/devices/pci0000:00/0000:00:17.0/ata1/host0/target0:0:0/0:0:0:0",
    sata2: "sdb:drivetemp:/sys/devices/pci0000:00/0000:00:17.0/ata2/host2/target2:0:0/2:0:0:0"
});

export const TEMP_SENSORS = Object.freeze({
    nvme0: "lmsensors/nvme-pci-0100/temp1",
    nvme2: "lmsensors/nvme-pci-0400/temp1",
    sata0: "lmsensors/drivetemp-scsi-0-0/temp1",
    sata2: "lmsensors/drivetemp-scsi-2-0/temp1"
});

export function metric(overrides = {}) {
    return {
        id: "cpu/usage",
        group: "cpu",
        subKey: "usage",
        label: "CPU",
        groupLabel: "CPU",
        icon: "cpu-symbolic",
        groupIcon: "cpu-symbolic",
        displayValue: "25%",
        color: COLORS.base,
        status: "ready",
        ...overrides
    };
}

export function profile(overrides = {}) {
    return {
        id: "profile-1",
        name: "Default",
        createdAt: 1,
        isDefault: true,
        data: { pinnedMetrics: "cpu/usage" },
        ...overrides
    };
}
