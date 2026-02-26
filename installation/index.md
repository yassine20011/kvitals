# Installation

## KDE Store (Recommended)

Install directly from the KDE Store:

👉 **[Get KVitals on the KDE Store](https://www.pling.com/p/2347917/)**

Or from within KDE Plasma:

1. Right-click on the panel → **Add Widgets...**
1. Click **Get New Widgets...** → **Download New Plasma Widgets...**
1. Search for **"KVitals"**
1. Click **Install**

## Quick Install (curl)

```
curl -fsSL https://raw.githubusercontent.com/yassine20011/kvitals/master/install-remote.sh | bash
```

## Quick Install (wget)

```
wget -qO- https://raw.githubusercontent.com/yassine20011/kvitals/master/install-remote.sh | bash
```

## Manual Install

```
git clone https://github.com/yassine20011/kvitals.git
cd kvitals
bash install.sh
```

Then add the widget:

1. Right-click on the panel → **Add Widgets...**
1. Search for **KVitals**
1. Drag it onto your panel

Restart Required

You may need to restart Plasma for the widget to appear:

```
plasmashell --replace &
```

## Requirements

- KDE Plasma 6.0+
- Bash
- Standard Linux utilities (`free`, `awk`, `bc`)

Checking Requirements

All required utilities are pre-installed on most Linux distributions. You can verify with:

```
which free awk bc bash
```

## Uninstall

```
rm -rf ~/.local/share/plasma/plasmoids/org.kde.plasma.kvitals
plasmashell --replace &
```

Warning

This permanently removes the widget and all its configuration. Your settings will not be preserved.
