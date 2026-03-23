# QuickShell Desktop

A Windows 11-inspired desktop shell for Hyprland with QuickShell. Features include a start menu, action center, power menu, wallpaper selector with matugen theming, and a full settings app.

## Quick Install

```bash
curl -fsSL https://github.com/thatmechguy/dms-config/install.sh | bash
```

Or with auto-confirm:
```bash
curl -fsSL https://github.com/thatmechguy/dms-config/install.sh | bash -s -- --yes
```

## Features

- **Start Menu** - Windows 11 style app launcher with search, pinned apps, and recommendations
- **Action Center** - Quick settings panel with brightness, volume, night light, bluetooth controls
- **Power Menu** - Sleep, restart, shutdown, hibernate, lock, logoff options
- **Wallpaper Selector** - Pick wallpapers with live preview and matugen-based theming
- **Settings Panel** - Inline settings panel for display, mouse, keyboard, sound
- **Dynamic Theming** - Automatic color extraction from wallpapers using matugen

## File Structure

```
~/.config/quickshell/
├── shell.qml              # Main shell (imports all panels)
├── settings-app.qml       # Standalone settings application
├── panels/
│   ├── StartMenu.qml      # Start menu with search and pinned apps
│   ├── ActionCenter.qml    # Quick settings and controls
│   ├── PowerMenu.qml      # Bottom power bar
│   ├── PopupPowerMenu.qml # Centered power popup
│   ├── SettingsPanel.qml  # Inline settings panel
│   ├── WallpaperSelector.qml # Wallpaper picker popup
│   ├── AllAppsPanel.qml   # All apps grid view
│   ├── WorkspaceOverview.qml # Workspace switcher
│   ├── WidgetsPanel.qml   # CPU/Memory widgets
│   └── PowerProfilesPanel.qml # Power mode selector
└── widgets/
    └── SystemTray.qml     # Top bar with clock and tray icons
```

## Keybindings

| Shortcut | Action |
|----------|--------|
| `Super+Enter` | Open Start Menu |
| `Super+D` | Show Desktop |
| `Super+E` | Open File Manager |
| `Super+C` | Open Wallpaper Selector |
| `Super+Y` | Open Wallpaper Picker |
| `Super+Shift+L` | Toggle Dark/Light Mode |
| `Super+F` | Toggle Fullscreen |
| `Super+T` | Toggle Floating |
| `Super+Shift+M` | Pin/Maximize Window |
| `Super+Escape` | Toggle Power Menu |
| `Escape` | Close all panels/menus |

## Theme Management

The setup uses [matugen](https://github.com/InioX/matugen) for dynamic theming. Wallpaper colors are automatically extracted and applied to GTK, Qt, and terminal applications.

### Theme Script Usage

```bash
# Pick wallpaper with rofi
~/.config/hypr/scripts/theme.sh pick

# Set specific wallpaper
~/.config/hypr/scripts/theme.sh set ~/Pictures/wallpaper.jpg

# Toggle light/dark mode
~/.config/hypr/scripts/theme.sh toggle

# Apply preset theme
~/.config/hypr/scripts/theme.sh preset nord
~/.config/hypr/scripts/theme.sh preset dracula
~/.config/hypr/scripts/theme.sh preset gruvbox
```

## Manual Installation

### Prerequisites

```bash
# Install required packages (Arch Linux)
sudo pacman -S quickshell hyprland swww matugen rofi brightnessctl playerctl cliphist hyprpicker grim slurp wl-clipboard

# Optional (recommended)
sudo pacman -S kitty chromium nautilus btop pavucontrol blueman polkit-kde-agent networkmanager
```

### Clone and Install

```bash
# Clone the repository
git clone https://github.com/thatmechguy/dms-config.git ~/.config/dms-config
cd ~/.config/dms-config

# Install all files
cp -r quickshell/* ~/.config/quickshell/
cp -r hypr/* ~/.config/hypr/
chmod +x ~/.config/hypr/scripts/*.sh
mkdir -p ~/Pictures/Wallpapers
```

### Start QuickShell

```bash
quickshell -p ~/.config/quickshell/shell.qml
```

## Troubleshooting

### QuickShell won't start
```bash
# Check for errors
quickshell -p ~/.config/quickshell/shell.qml 2>&1

# Validate QML
qmllint ~/.config/quickshell/shell.qml
```

### Wallpaper not changing
```bash
# Check swww is running
pkill swww
swww-daemon &

# Check matugen
matugen --version
```

### Keybindings not working
```bash
hyprctl reload
```

## Credits

- Inspired by [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell)
- Built with [QuickShell](https://quickshell.org/)
- Dynamic theming powered by [matugen](https://github.com/InioX/matugen)

## License

MIT License
