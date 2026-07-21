## Description

Adds proper multi-fan support: per-fan naming, RPM/percentage display with a configurable max-RPM fallback, per-fan sparkline history, and a compact-panel padding fix so fluctuating values no longer reflow the whole row.

Builds on top of the metrics-restructure branch (hierarchical metrics, per-metric visibility). Rebased on top of it before opening, so this PR is scoped to fan-only changes.

### Features

- **Per-fan labeling**: each discovered fan gets a stable number (`Fan 1`, `Fan 2`, ...) instead of relying on KSysGuard's `Qt.DisplayRole`, which is often generic/duplicated across fans (e.g. every fan reporting the same "Fan Speed" label) and can't be used to tell them apart. Users can override with a custom name per fan, same UX pattern as GPU/disk labeling.
- **Multi-fan display**: compact panel shows one grouped row (`FAN: 1:1450RPM 2:980RPM ...`) with the fan number as a small distinctly-colored sub-label next to each value, so many fans stay readable without eating panel width. The popup lists each fan on its own line as `N: friendly-name`.
- **RPM / percentage unit toggle with configurable max**: percentage mode divides by the sensor's own reported max when available, falling back to a user-configurable `Max RPM` setting (default 2000) when the hardware doesn't expose one, replacing the old hardcoded 6000 default.
- **Per-fan sparklines**: fan RPM history now feeds the same `chartHistory`/`chartVersion` protocol used by CPU/GPU/RAM, keyed per fan id (`"fan:" + id`), so each fan gets its own trend line in the popup.
- **Compact panel padding fix**: value labels (plain and segmented) grow a sticky minimum width within the session instead of reflowing the whole compact row every time a fluctuating value crosses a digit-count boundary (e.g. RPM going from 800 to 1000).

### Files changed

| File | Description |
|------|-------------|
| `contents/config/main.xml` | New config entries: `fanLabel`, `fanLabels`, `fanMaxRpm` |
| `contents/ui/sensors/FanSensors.qml` | Stable per-fan numbering, custom labels, `fanDataList` with per-fan raw values, configurable max-RPM fallback |
| `contents/ui/main.qml` | Multi-fan compact segments, per-fan popup rows, fan chart history accumulation |
| `contents/ui/configMetrics.qml` | Per-fan label fields, Max RPM spinbox |
| `contents/ui/CompactView.qml` | Segment sub-label rendering, sticky-width padding fix for compact panel values |

## Testing

- [x] Tested on Plasma 6
- [x] Distro: Fedora 42
- [x] HW: ASUS TUF GAMING B650-E WiFi, Ryzen 9 9900X, RTX 5070 Ti (3 fan headers)
- [x] Widget installs cleanly with `install.sh`
- [x] Verified compact panel and popup fan display, RPM/percent toggle, per-fan labels, sparklines
