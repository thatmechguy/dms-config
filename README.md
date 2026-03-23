# QuickShell Desktop Configuration

A Windows 11-inspired desktop shell for Hyprland with QuickShell.

## Features

- **Start Menu** - Windows 11 style app launcher with search, pinned apps, and recommendations
- **Action Center** - Quick settings panel with brightness, volume, night light, bluetooth controls
- **Power Menu** - Sleep, restart, shutdown, hibernate, lock, logoff options
- **Wallpaper Selector** - Pick wallpapers with live preview and matugen-based theming
- **Settings App** - Full-featured settings panel for display, mouse, keyboard, sound, and more
- **Dynamic Theming** - Automatic color extraction from wallpapers using matugen

## Installation

### Prerequisites

```bash
# Install required packages (Arch Linux)
sudo pacman -S quickshell hyprland swww matugen rofi waybar NetworkManager blueman \
  brightnessctl playerctl hyprpicker grim slurp wl-clipboard cliphist

# Install optional but recommended
sudo pacman -S kitty chromium nautilus btop pavucontrol blueman polkit-kde-agent
```

### Quick Install

```bash
# Backup existing config (optional)
mv ~/.config/quickshell ~/.config/quickshell.bak
mv ~/.config/hypr ~/.config/hypr.bak

# Clone/install this config
git clone https://github.com/yourusername/dms-config.git ~/.config/dms-config
cd ~/.config/dms-config

# Run installation script
./install.sh
```

### Manual Install

```bash
# Copy quickshell config
cp quickshell/*.qml ~/.config/quickshell/
chmod +x hypr/scripts/*.sh

# Copy hypr config
cp hypr/*.conf ~/.config/hypr/
cp -r hypr/scripts/* ~/.config/hypr/scripts/

# Create wallpaper directory
mkdir -p ~/Pictures/Wallpapers
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
| `Ctrl+Escape` | Toggle Power Menu |

## Configuration

### Themes

The setup uses matugen for dynamic theming. Wallpaper colors are extracted and applied to:
- GTK applications
- Qt applications
- Terminal emulators
- System colors

### Scripts

| Script | Purpose |
|--------|---------|
| `theme.sh` | Wallpaper and theme management |
| `nightlight.sh` | Blue light filter toggle |
| `volume.sh` | Volume controls for media keys |
| `brightness.sh` | Brightness controls for media keys |
| `clipboard.sh` | Clipboard history manager |

### Theme Script Usage

```bash
# Pick wallpaper with rofi
theme.sh pick

# Set specific wallpaper
theme.sh set ~/Pictures/wallpaper.jpg

# Toggle light/dark mode
theme.sh toggle

# Apply preset theme
theme.sh preset nord
theme.sh preset dracula
theme.sh preset gruvbox

# Show current theme info
theme.sh info
```

## File Structure

```
~/.config/
├── quickshell/
│   ├── shell.qml          # Main shell configuration
│   └── settings-app.qml     # Settings application
└── hypr/
    ├── hyprland.conf       # Hyprland configuration
    ├── hypridle.conf       # Idle management
    ├── hyprlock.conf       # Lock screen config
    ├── colors.conf         # Color definitions
    └── scripts/
        ├── theme.sh        # Theme management
        ├── nightlight.sh   # Night light toggle
        ├── volume.sh       # Volume controls
        ├── brightness.sh   # Brightness controls
        └── clipboard.sh    # Clipboard history
```

## Troubleshooting

### QuickShell won't start
```bash
# Check for errors
quickshell -p ~/.config/quickshell/shell.qml 2>&1

# Validate QML
cd ~/.config/quickshell
qmllint shell.qml settings-app.qml
```

### Wallpaper not changing
```bash
# Check swww is running
pkill swww
swww-daemon &

# Check matugen is working
matugen --version
```

### Keybindings not working
```bash
# Reload Hyprland config
hyprctl reload
```

## Customization

### Adding Apps to Start Menu

Edit `~/.config/quickshell/shell.qml` and add to `pinnedAppsModel`:

```qml
ListElement { n: "AppName"; ic: "icon-name"; c: "command"; nf: "󰀻" }
```

### Adding Theme Presets

Edit `~/.config/quickshell/settings-app.qml` and add to `themePresets`:

```qml
ListElement { name: "My Theme"; color: "#HEXCOLOR"; accent: "#HEXCOLOR" }
```

### Custom Wallpaper Directory

Edit `~/.config/hypr/scripts/theme.sh`:
```bash
WALLPAPERS_DIR="$HOME/Your/Wallpaper/Path"
```

## Credits

- Inspired by [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell)
- Built with [QuickShell](https://quickshell.org/)
- Dynamic theming powered by [matugen](https://github.com/InioX/matugen)

## License

MIT License
