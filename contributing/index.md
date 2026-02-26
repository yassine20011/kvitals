# Contributing

Thanks for your interest in contributing to KVitals!

## Getting Started

1. Fork the repository

1. Clone your fork:

   ```
   git clone https://github.com/<your-username>/kvitals.git
   cd kvitals
   ```

1. Install locally for development:

   ```
   bash install.sh
   ```

## Development Workflow

### Making Changes

1. Edit files in the project directory

1. Reinstall and test:

   ```
   bash install.sh
   kquitapp6 plasmashell && kstart plasmashell &
   ```

1. Check for QML errors:

   ```
   journalctl -b --no-pager | grep kvitals
   ```

Fast Iteration

You don't always need to restart plasmashell. For config-only changes, just reopen the settings dialog. For QML changes, a restart is required.

### Shell Script Changes

Always run ShellCheck before committing:

```
shellcheck contents/scripts/sys-stats.sh
```

CI Enforcement

ShellCheck is enforced in CI. PRs with ShellCheck warnings will fail the pipeline.

### Adding a New Metric

1. **Script** — Add a new function in `sys-stats.sh` that outputs the value
1. **JSON** — Include the new field in the JSON output
1. **Config** — Add `showNewMetric` (Bool) and optionally `newMetricIcon` (String) to `main.xml`
1. **Settings** — Add checkbox to `configMetrics.qml`, icon picker to `configIcons.qml`
1. **UI** — Add property bindings and model entry in `main.qml`

Note

Don't forget to add a default icon name for the new metric in `configIcons.qml`'s reset button handler.

### Adding a New Setting

1. Add the entry to `contents/config/main.xml` with a default value
1. Add the UI control to the appropriate config tab (`configGeneral.qml`, `configMetrics.qml`, or `configIcons.qml`)
1. Bind the value in `main.qml` via `Plasmoid.configuration.<key>`

## Pull Requests

1. Create a feature branch: `git checkout -b feat/my-feature`
1. Make your changes and test locally
1. Ensure ShellCheck passes
1. Push and open a PR against `master`

Commit Messages

Use conventional commits for clear history:

- `feat:` — New feature
- `fix:` — Bug fix
- `chore:` — Maintenance
- `docs:` — Documentation

## Code Style

- **QML** — Follow KDE's QML conventions, use `Kirigami` components where possible
- **Bash** — Must pass ShellCheck with no warnings
- **Commits** — Use conventional commits: `feat:`, `fix:`, `chore:`, `docs:`

## Reporting Issues

When filing a bug report, please include:

- KDE Plasma version (`plasmashell --version`)
- Linux distribution and version
- Whether you're using Intel or AMD CPU
- Relevant journal output (`journalctl -b | grep kvitals`)

Debugging Output

To capture detailed logs for a bug report:

```
journalctl -b --no-pager | grep -i "kvitals\|sys-state" > kvitals-debug.log
```
