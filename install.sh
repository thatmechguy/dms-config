#!/usr/bin/env bash
# QuickShell Desktop Configuration Installer
# One-command installation for Arch Linux

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

INSTALL_DIR="${HOME}/.config/dms-config"
REPO_URL="https://github.com/thatmechguy/dms-config"
CONFIG_QUICKSHELL="${HOME}/.config/quickshell"
CONFIG_HYPR="${HOME}/.config/hypr"

echo -e "${BOLD}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " QuickShell Desktop - One-Command Installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${NC}"

# Check if running as Arch Linux
if [ ! -f /etc/arch-release ]; then
    echo -e "${RED}✗ This installer is designed for Arch Linux${NC}"
    exit 1
fi

# Parse arguments
AUTO_YES=false
SKIP_PACKAGES=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -y|--yes) AUTO_YES=true; shift ;;
        --skip-packages) SKIP_PACKAGES=true; shift ;;
        -h|--help)
            echo "Usage: curl -fsSL ${REPO_URL}/install.sh | bash [options]"
            echo ""
            echo "Options:"
            echo "  -y, --yes         Auto-confirm package installation"
            echo "  --skip-packages   Skip package installation"
            echo "  -h, --help        Show this help"
            exit 0
            ;;
        *) shift ;;
    esac
done

# Step 1: Install packages
install_packages() {
    echo -e "${BOLD}${YELLOW}→ Installing required packages...${NC}"
    
    PACKAGES=(
        # Core
        quickshell hyprland swww matugen

        # Utilities
        rofi brightnessctl playerctl cliphist
        hyprpicker grim slurp wl-clipboard

        # Optional (recommended)
        kitty chromium nautilus btop pavucontrol
        blueman polkit-kde-agent
    )

    echo "The following packages will be installed:"
    echo "  ${PACKAGES[*]}"
    echo ""

    if [ "$AUTO_YES" = false ]; then
        read -p "Continue? [Y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
            exit 1
        fi
    fi

    echo -e "${GREEN}→ Running sudo pacman -Syu...${NC}"
    sudo pacman -Syu --noconfirm || true

    echo -e "${GREEN}→ Installing packages...${NC}"
    sudo pacman -S --noconfirm --needed "${PACKAGES[@]}" || {
        echo -e "${RED}✗ Package installation failed${NC}"
        exit 1
    }

    echo -e "${GREEN}✓ Packages installed${NC}"
}

# Step 2: Clone/download config
download_config() {
    echo -e "${BOLD}${YELLOW}→ Downloading configuration...${NC}"
    
    if [ -d "${INSTALL_DIR}" ]; then
        echo "Config already exists, pulling latest..."
        cd "${INSTALL_DIR}"
        git pull origin master 2>/dev/null || {
            rm -rf "${INSTALL_DIR}"
            git clone --depth 1 "${REPO_URL}" "${INSTALL_DIR}"
        }
    else
        echo "Cloning repository..."
        git clone --depth 1 "${REPO_URL}" "${INSTALL_DIR}"
    fi

    cd "${INSTALL_DIR}"
    chmod +x install.sh Makefile *.sh 2>/dev/null || true
    chmod +x hypr/scripts/*.sh 2>/dev/null || true

    echo -e "${GREEN}✓ Configuration downloaded${NC}"
}

# Step 3: Install configuration
install_config() {
    echo -e "${BOLD}${YELLOW}→ Installing configuration...${NC}"
    
    # Backup existing
    if [ -d "${CONFIG_QUICKSHELL}" ] || [ -d "${CONFIG_HYPR}" ]; then
        BACKUP_DIR="${HOME}/.config/dms-backup-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "${BACKUP_DIR}"
        
        if [ -d "${CONFIG_QUICKSHELL}" ]; then
            cp -r "${CONFIG_QUICKSHELL}" "${BACKUP_DIR}/"
            rm -rf "${CONFIG_QUICKSHELL}"
        fi
        
        if [ -d "${CONFIG_HYPR}" ]; then
            cp -r "${CONFIG_HYPR}" "${BACKUP_DIR}/"
            rm -rf "${CONFIG_HYPR}"
        fi
        
        echo -e "${YELLOW}✓ Existing config backed up to ${BACKUP_DIR}${NC}"
    fi

    # Install quickshell
    mkdir -p "${CONFIG_QUICKSHELL}"
    cp "${INSTALL_DIR}/quickshell/"*.qml "${CONFIG_QUICKSHELL}/"
    
    # Install hypr
    mkdir -p "${CONFIG_HYPR}/scripts"
    cp "${INSTALL_DIR}/hypr/"*.conf "${CONFIG_HYPR}/"
    cp "${INSTALL_DIR}/hypr/scripts/"*.sh "${CONFIG_HYPR}/scripts/"
    chmod +x "${CONFIG_HYPR}/scripts/"*.sh

    # Create wallpaper directory
    mkdir -p "${HOME}/Pictures/Wallpapers"

    echo -e "${GREEN}✓ Configuration installed${NC}"
}

# Step 4: Setup autostart
setup_autostart() {
    echo -e "${BOLD}${YELLOW}→ Setting up autostart...${NC}"
    
    AUTOSTART_DIR="${HOME}/.config/autostart"
    mkdir -p "${AUTOSTART_DIR}"
    
    cat > "${AUTOSTART_DIR}/quickshell.desktop" << 'AUTOSTART_EOF'
[Desktop Entry]
Type=Application
Name=QuickShell
Exec=quickshell -p ~/.config/quickshell/shell.qml
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
AUTOSTART_EOF
    
    # Also create hyprland exec line
    if ! grep -q "exec.*quickshell" "${CONFIG_HYPR}/hyprland.conf" 2>/dev/null; then
        echo "" >> "${CONFIG_HYPR}/hyprland.conf"
        echo "# QuickShell autostart" >> "${CONFIG_HYPR}/hyprland.conf"
        echo "exec-once = quickshell -p ~/.config/quickshell/shell.qml" >> "${CONFIG_HYPR}/hyprland.conf"
    fi

    echo -e "${GREEN}✓ Autostart configured${NC}"
}

# Main
main() {
    if [ "$SKIP_PACKAGES" = false ]; then
        install_packages
    else
        echo -e "${YELLOW}→ Skipping package installation (--skip-packages)${NC}"
    fi
    
    download_config
    install_config
    setup_autostart

    # Reload hyprland
    echo -e "${BOLD}${YELLOW}→ Reloading Hyprland...${NC}"
    hyprctl reload 2>/dev/null || true

    echo ""
    echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo " Installation Complete!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BOLD}Quick Start:${NC}"
    echo "  • Super+Enter  - Open Start Menu"
    echo "  • Super+C      - Wallpaper Selector"
    echo "  • Super+Y      - Wallpaper Picker"
    echo "  • Super+Shift+L - Toggle Dark/Light Mode"
    echo "  • Super+Escape - Power Menu"
    echo ""
    echo -e "${BOLD}Restart QuickShell to apply:${NC}"
    echo "  quickshell -p ~/.config/quickshell/shell.qml"
    echo ""
}

main "$@"
