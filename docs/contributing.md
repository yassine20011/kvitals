# Contributing

Thanks for your interest in contributing to KVitals!

## Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/<your-username>/kvitals.git
   cd kvitals
   ```
3. Install locally for development:
   ```bash
   bash install.sh
   ```

## Development Workflow

### Making Changes

1. Edit files in the project directory
2. Reinstall and test:
   ```bash
   bash install.sh
   kquitapp6 plasmashell && kstart plasmashell &
   ```
3. Check for QML errors:
   ```bash
   journalctl -b --no-pager | grep kvitals
   ```

!!! tip "Fast Iteration"
    You don't always need to restart plasmashell. For config-only changes, just reopen the settings dialog. For QML changes, a restart is required.

### Adding a New Metric

For adding a sub-metric to an existing sensor group (the most common addition):

1. **Find sensor ID**: Identify the sensor path in `ksystemstats` using `kstatsviewer` or `qdbus org.kde.ksystemstats1 /org/kde/ksystemstats1 org.kde.ksystemstats1.allSensors`.
2. **Metric definition**: Add the metric entry to `DEFINITIONS` in `contents/ui/models/MetricDefinitions.js`. If the sub-metric should be enabled by default on new installs, add its key to `GROUPS[group].defaultSubMetrics` in `MetricDefinitions.js` and update the static `<default>` in `contents/config/main.xml`.
3. **Sensor module**: Subscribe to the sensor and expose the numeric or formatted property in `contents/ui/sensors/<Group>Sensors.qml`.
4. **Metric store**: Push the metric in `contents/ui/models/MetricStore.qml` using `_createMetric("group.subKey", { ... })`.
5. **Config UI**: Add `{ key: "subKey", label: i18n("...") }` to `metricMeta[group].subs` in `contents/ui/configMetrics.qml`.

To add an entirely new hardware category (such as NPU or Cooler), see the module guide in [Architecture Documentation](architecture.md#workflow-b-adding-a-new-hardware-category--sensor-module).

### Adding a New Setting

1. Add the entry to `contents/config/main.xml` with a default value.
2. Add the matching `cfg_<key>` property and UI control to the appropriate config tab (`configGeneral.qml`, `configMetrics.qml`, `configIcons.qml`, or `configColors.qml`) so the KCM can load and persist the value.
3. Expose the value in `contents/ui/models/MetricConfig.qml` (for metric settings) or read it in `contents/ui/main.qml` (for general presentation settings).

## Pull Requests

1. Create a feature branch: `git checkout -b feat/my-feature`
2. Make your changes and test locally
3. Ensure ShellCheck passes
4. Push and open a PR against `master`

!!! tip "Commit Messages"
    Use conventional commits for clear history:

    - `feat:`: New feature
    - `fix:`: Bug fix
    - `chore:`: Maintenance
    - `docs:`: Documentation

## Code Style

- **QML**: Follow KDE QML conventions, use Kirigami components where possible
- **Commits**: Use conventional commits (`feat:`, `fix:`, `chore:`, `docs:`)

## Reporting Issues

When filing a bug report, please include:

- KDE Plasma version (`plasmashell --version`)
- Linux distribution and version
- Whether you're using Intel or AMD CPU
- Relevant journal output (`journalctl -b | grep kvitals`)

!!! note "Debugging Output"
    To capture detailed logs for a bug report:
    ```bash
    journalctl -b --no-pager | grep -i "kvitals\|sys-state" > kvitals-debug.log
    ```
