# Changelog

All notable changes to KVitals will be documented in this file.

## [2.0.0] - 2026-02-27

### Changed
- **Major Architecture Overhaul**: Replaced the previous `sys-stats.sh` backend with native KDE KSysGuard sensors (`org.kde.ksysguard.sensors`).
- Completely eliminates "file descriptor leak" crashes (Issue #8) and improves overall performance by relying directly on the `ksystemstats` D-Bus daemon instead of constantly spawning bash processes.
- Automatic fallback for battery monitoring (BAT0 and BAT1) logic implemented directly in QML.

## [1.4.1] - 2026-02-24

### Fixed
- RAM usage showing empty on non-English locales — `free` translates its `Mem:` header based on locale, causing the parser to match nothing
- Switched RAM data source from `free -b` to `/proc/meminfo` (locale-independent, faster, more accurate)

## [1.4.0] - 2026-02-22

### Added
- **Display mode setting** — choose between Text, Icons, or Icons + Text for the panel
- **Custom icon picker** — select icons from your installed theme for each metric (via KDE's native icon picker)
- **Icon size slider** — adjust icon size (8–24px) when using icon mode
- **Font customization** — choose any system font and font size for the panel text
- **Settings tabs** — split configuration into General, Metrics, and Icons tabs
- **Reset to defaults** button on the Icons tab
- **CHANGELOG.md** — version history
- **Documentation** — MkDocs site with installation, configuration, architecture, contributing, and troubleshooting guides

## [1.3.0] - 2026-02-16

### Added
- Power consumption tracking (via `/sys/class/power_supply/`) — contributed by [@Pijuli](https://github.com/Pijuli)

### Fixed
- ShellCheck warnings from power consumption PR (SC2034, SC2155)

## [1.2.1] - 2026-02-16

### Fixed
- AMD CPU temperature detection — added `k10temp`, `zenpower`, `zenergy`, `amdgpu` to thermal_zone and hwmon detection
- lm-sensors fallback now matches AMD `Tccd1` label
- Reordered temperature fallback tiers to prioritize CPU-specific sources over generic thermal zones

## [1.2.0] - 2026-02-13

### Added
- Auto-detect network interface via `ip route` with manual override in settings
- Network interface selector in widget configuration

### Fixed
- ShellCheck warnings (SC2010, SC2155)

## [1.1.0] - 2026-02-12

### Changed
- Modularized `sys-stats.sh` into functions
- Enhanced CPU temperature detection with 4-tier fallback (thermal_zone → hwmon → lm-sensors → generic)

## [1.0.0] - 2026-02-12

### Added
- Initial release
- CPU usage (delta-based from `/proc/stat`)
- RAM usage (from `/proc/meminfo`)
- CPU temperature (multi-source detection)
- Battery status with emoji indicators
- Network speed (delta-based from `/proc/net/dev`)
- Configurable update interval
- Toggle visibility per metric
