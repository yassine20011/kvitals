# Contributing to KVitals

Thanks for your interest in contributing! Here's how to get started.

## Development Setup

1. **Clone the repo**
   ```bash
   git clone https://github.com/yassine20011/kvitals.git
   cd kvitals
   ```

2. **Install the widget locally**
   ```bash
   bash install.sh
   ```

3. **Test changes** — After editing QML files, reinstall:
   ```bash
   bash install.sh
   ```
   Then restart the widget (remove & re-add to panel) or log out / log in.

## Automated Tests

The fast suite runs on Node.js 22 and exercises the same JavaScript logic imported by the QML runtime:

```bash
cd tests
npm test
```

Additional checks:

```bash
npm run test:coverage  # source-level coverage report for production JS modules
npm run test:lint-qml  # Qt 6 qmllint with the widget's import paths
npm run test:qml       # Qt Quick Test component and interaction suite
npm run test:smoke     # Plasma 6 desktop/panel/vertical/HiDPI launch matrix
```

The last three commands require Plasma 6, Qt 6 declarative development tools,
Xvfb, and DBus. The smoke test rejects Plasma 5 explicitly. Before opening a
pull request, also test the widget interactively on Plasma 6; headless tests do
not replace checking real panel sizing, theme integration, and configuration
behavior. CI runs the Node layer independently and runs the KDE-native layers
in an Ubuntu 26.04 Plasma 6 container.

The complete test architecture, current coverage, implemented checks, remaining
automation, and manual release checklist are documented in
[docs/testing.md](docs/testing.md).

## Project Structure

```
kvitals/
├── metadata.json                  # Plugin metadata (version, name, etc.)
├── contents/
│   ├── ui/
│   │   ├── main.qml               # Main widget UI
│   │   ├── models/                # Runtime models and shared testable logic
│   │   ├── sensors/               # KSystemStats sensor adapters
│   │   └── configGeneral.qml      # Settings page
│   ├── config/
│   │   └── config.qml             # Config entry point
├── install.sh                     # Local install script
├── install-remote.sh              # Remote install (curl/wget)
├── tests/
│   ├── qml/                       # Native Qt Quick component/interaction tests
│   ├── unit/                      # Fast production-JS and contract tests
│   ├── run_qml_tests.sh           # Qt 6 qmltestrunner entry point
│   └── smoke_test.sh              # Plasma 6 form-factor smoke matrix
└── package.sh                     # Build .plasmoid package
```

## Commit Messages

Use conventional commit prefixes:

- `feat:` — New feature (e.g. `feat: add GPU temperature monitoring`)
- `fix:` — Bug fix (e.g. `fix: handle missing thermal zones`)
- `docs:` — Documentation only (e.g. `docs: update install instructions`)
- `refactor:` — Code restructuring without behavior change
- `chore:` — Build scripts, CI, tooling

## Submitting a Pull Request

1. Fork the repo and create a branch: `git checkout -b feat/my-feature`
2. Make your changes and test locally on Plasma 6
3. Commit with a clear message following the conventions above
4. Push and open a PR against `master`
5. In the PR description, mention:
   - What the change does
   - Your Plasma version and distro
   - Screenshots if it's a visual change

## Reporting Bugs

Please use the [bug report template](https://github.com/yassine20011/kvitals/issues/new?template=bug_report.md) and include:
- Your **Plasma version** (`plasmashell --version`)
- Your **distro** and version
- Steps to reproduce
- Expected vs actual behavior

## Feature Requests

Use the [feature request template](https://github.com/yassine20011/kvitals/issues/new?template=feature_request.md).

## License

By contributing, you agree that your contributions will be licensed under the [GPL-3.0 License](LICENSE).
