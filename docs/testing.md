# Testing

KVitals uses layered tests because no single runner can validate both pure data
logic and Plasma widget behavior. The fast suite runs on Node.js, component
tests run in the Qt 6 QML engine, and the final smoke layer launches the complete
widget with Plasma 6 tooling.

## What Was Added

### Production logic instead of copied test implementations

Reusable algorithms were moved into QML-compatible JavaScript modules under
`contents/ui/models/`:

- `ConfigLogic.js`: CSV configuration, hardware selection, JSON label maps, and metric ordering
- `DiskSensorLogic.js`: disk-to-temperature-sensor resolution
- `HardwareInventoryLogic.js`: KSystemStats hardware classification
- `MetricLogic.js`: value normalization and threshold colors
- `ProfileLogic.js`: profile validation, migration, selection, deletion, and serialization
- `ShortcutLogic.js`: shortcut initialization and synchronization

The QML runtime imports these modules, and the Node suite loads those same
files. Tests no longer carry independent copies of the production algorithms.

Configuration defaults remain owned by the production module and
`contents/config/main.xml`. Contract tests check that the two sources agree.
Test fixtures may contain representative input and expected output, but they
must not become another source for operational defaults.

### Test layers

| Layer | Command | What it checks |
| --- | --- | --- |
| Production logic | `npm test --prefix tests` | Sensor mapping, metric generation helpers, configuration, profiles, shortcuts, and regressions |
| Coverage | `npm run test:coverage --prefix tests` | Production JavaScript execution with enforced line, function, and branch thresholds |
| Package contracts | Included in the Node suite | Metadata, KConfig schema, configured pages, sensor modules, icons, imports, packaging, and QML-to-logic wiring |
| QML lint | `npm run test:lint-qml --prefix tests` | Qt 6 `qmllint` with the widget's runtime import paths |
| Qt Quick components | `npm run test:qml --prefix tests` | Production configuration and metric-store QML, mocked sensors, compact-view layout, and pointer interaction |
| Plasma smoke matrix | `npm run test:smoke --prefix tests` | Complete widget startup in desktop, horizontal panel, vertical panel, and HiDPI modes |

The smoke test requires Plasma 6 explicitly. It rejects Plasma 5, premature
`plasmoidviewer` exits, component-loading failures, QML exceptions, binding
loops, invalid assignments, aborts, and segmentation faults.

## Current Baseline

The fast suite contains 56 passing tests. Its current production-module
coverage is:

| Measure | Coverage | Enforced minimum |
| --- | ---: | ---: |
| Lines | 97.58% | 90% |
| Functions | 100% | 95% |
| Branches | 79.00% | 70% |

Coverage percentages describe the extracted JavaScript modules; they do not
claim that every visual or Plasma runtime path is covered.

## Requirements

The Node layer requires Node.js 22 or newer. The KDE-native layers require:

- KDE Plasma 6 and `plasmoidviewer`
- Qt 6 declarative development tools (`qmllint` and `qmltestrunner`)
- The QtTest QML module
- The KSysGuard QML module
- Xvfb and a DBus session for headless execution

CI installs these dependencies in an Ubuntu 26.04 container. The native scripts
also recognize the common Debian/Ubuntu and openSUSE Qt 6 tool locations.

## CI Gates

The workflow separates shell linting, package creation, Node tests, and Plasma
tests. Pull requests must pass:

1. ShellCheck for repository shell scripts.
2. `.plasmoid` package creation.
3. Node logic and contract tests with coverage thresholds.
4. Qt 6 QML linting.
5. Qt Quick component and interaction tests.
6. The Plasma 6 form-factor smoke matrix.

An early clean exit from `plasmoidviewer` is treated as a failure because it
does not demonstrate that the widget remained initialized.

## What Remains

The following work would further improve confidence. It is intentionally not
represented as completed coverage:

### Release-critical validation

- Confirm the new native job on GitHub Actions and fix any distribution-specific QML import or headless-rendering issue it exposes.
- Perform a real Plasma 6 panel test before release, covering configuration persistence, popup behavior, profile switching, and panel resizing.
- Check at least one light and one dark Plasma theme and a fractional display scale; the headless matrix currently covers scale factor 1 and 2.
- Exercise the widget on a machine with real CPU, GPU, battery, network, fan, and disk sensors. Mocked component tests cannot validate driver-specific KSystemStats behavior.

### Planned automation

- Add tests that instantiate the KCM pages and verify edit, apply, cancel, reset, and profile-specific persistence behavior.
- Add keyboard-navigation and accessibility checks for the popup and profile switcher.
- Add a controllable fake KSystemStats/DBus source for end-to-end sensor subscription, hotplug, disappearance, and recovery scenarios.
- Add visual regression snapshots for compact and expanded views across themes and form factors.
- Add runtime tests for global-shortcut registration and conflict handling inside a real Plasma session.
- Raise branch coverage in `ViewHelpers.js`, especially structural resynchronization and malformed segment/group inputs.

## Manual Release Checklist

Before publishing a release:

1. Run every automated command listed above.
2. Install the generated `.plasmoid` package rather than only testing the source directory.
3. Add the widget to horizontal and vertical panels and to the desktop.
4. Open every configuration page, change a value, apply it, and reopen the dialog.
5. Exercise popup pinning, metric reordering, profiles, shortcut activation, and sensor hotplug where available.
6. Inspect `journalctl` for KVitals QML warnings, exceptions, or crashes.

