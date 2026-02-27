# Installation

## KDE Store (Recommended)

Install directly from the KDE Store:

👉 **[Get KVitals on the KDE Store](https://www.pling.com/p/2347917/)**

Or from within KDE Plasma:
1. Right-click on the panel → **Add Widgets...**
2. Click **Get New Widgets...** → **Download New Plasma Widgets...**
3. Search for **"KVitals"**
4. Click **Install**

## Quick Install (curl)

```bash
curl -fsSL https://raw.githubusercontent.com/yassine20011/kvitals/master/install-remote.sh | bash
```

## Quick Install (wget)

```bash
wget -qO- https://raw.githubusercontent.com/yassine20011/kvitals/master/install-remote.sh | bash
```

## Manual Install

```bash
git clone https://github.com/yassine20011/kvitals.git
cd kvitals
bash install.sh
```

Then add the widget:
1. Right-click on the panel → **Add Widgets...**
2. Search for **KVitals**
3. Drag it onto your panel

!!! note "Restart Required"
    You may need to restart Plasma for the widget to appear:
    ```bash
    plasmashell --replace &
    ```

## Requirements

- KDE Plasma 6.0+

## Uninstall

```bash
rm -rf ~/.local/share/plasma/plasmoids/org.kde.plasma.kvitals
plasmashell --replace &
```

!!! warning
    This permanently removes the widget and all its configuration. Your settings will not be preserved.
