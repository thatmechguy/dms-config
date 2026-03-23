#!/usr/bin/env bash
# QuickShell Desktop Configuration Installer

set -e

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUICKSHELL_DIR="$HOME/.config/quickshell"
HYPR_DIR="$HOME/.config/hypr"
BACKUP_DIR="$HOME/.config/dms-backup-$(date +%Y%m%d-%H%M%S)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " QuickShell Desktop Configuration Installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check prerequisites
echo ""
echo "Checking prerequisites..."

if ! command -v quickshell &> /dev/null; then
    echo "❌ QuickShell not found. Please install quickshell first."
    exit 1
fi

if ! command -v hyprctl &> /dev/null; then
    echo "❌ Hyprland not found. Please install hyprland first."
    exit 1
fi

echo "✓ QuickShell found"
echo "✓ Hyprland found"

# Backup existing config
if [ -d "$QUICKSHELL_DIR" ] || [ -d "$HYPR_DIR" ]; then
    echo ""
    echo "Backing up existing configuration..."
    mkdir -p "$BACKUP_DIR"
    
    if [ -d "$QUICKSHELL_DIR" ]; then
        cp -r "$QUICKSHELL_DIR" "$BACKUP_DIR/"
        echo "✓ Backed up quickshell config"
    fi
    
    if [ -d "$HYPR_DIR" ]; then
        cp -r "$HYPR_DIR" "$BACKUP_DIR/"
        echo "✓ Backed up hypr config"
    fi
    
    echo "Backup location: $BACKUP_DIR"
fi

# Install quickshell config
echo ""
echo "Installing QuickShell configuration..."
mkdir -p "$QUICKSHELL_DIR"
cp "$CONFIG_DIR/quickshell/"*.qml "$QUICKSHELL_DIR/"
chmod 644 "$QUICKSHELL_DIR"/*.qml
echo "✓ Installed QuickShell config to $QUICKSHELL_DIR"

# Install hypr config
echo ""
echo "Installing Hyprland configuration..."
mkdir -p "$HYPR_DIR"
mkdir -p "$HYPR_DIR/scripts"

cp "$CONFIG_DIR/hypr/"*.conf "$HYPR_DIR/"
chmod 644 "$HYPR_DIR"/*.conf

cp "$CONFIG_DIR/hypr/scripts/"*.sh "$HYPR_DIR/scripts/"
chmod +x "$HYPR_DIR/scripts/"*.sh
echo "✓ Installed Hyprland config to $HYPR_DIR"

# Create wallpaper directory
mkdir -p "$HOME/Pictures/Wallpapers"
echo "✓ Created wallpaper directory: $HOME/Pictures/Wallpapers"

# Reload Hyprland
echo ""
echo "Reloading Hyprland configuration..."
hyprctl reload 2>/dev/null || true

# Final message
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Installation Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Files installed:"
echo "  • $QUICKSHELL_DIR/"
echo "  • $HYPR_DIR/"
echo ""
echo "Key shortcuts:"
echo "  • Super+Enter  - Start Menu"
echo "  • Super+C      - Wallpaper Selector"
echo "  • Super+Y      - Wallpaper Picker"
echo "  • Super+Shift+L - Toggle Dark/Light"
echo "  • Super+Escape - Power Menu"
echo ""
echo "For more options, see the README at:"
echo "  $CONFIG_DIR/README.md"
echo ""
echo "Restart QuickShell to apply changes:"
echo "  quickshell -p ~/.config/quickshell/shell.qml"
echo ""
