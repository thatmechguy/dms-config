#!/usr/bin/env bash
# Theme management script using matugen

THEME_DIR="$HOME/.config/quickshell/themes"
CURRENT_THEME_FILE="$HOME/.config/quickshell/current-theme.conf"

# Default themes
DARK_THEME="dark"
LIGHT_THEME="light"

# Get current theme mode
get_mode() {
    if [ -f "$CURRENT_THEME_FILE" ]; then
        grep "MODE=" "$CURRENT_THEME_FILE" 2>/dev/null | cut -d= -f2
    else
        echo "dark"
    fi
}

# Set wallpaper and generate theme
set_wallpaper_theme() {
    local wallpaper="$1"
    
    if [ ! -f "$wallpaper" ]; then
        echo "Wallpaper not found: $wallpaper"
        return 1
    fi
    
    local mode=$(get_mode)
    
    # Set wallpaper with swww
    swww img "$wallpaper" --transition-type grow --transition-pos 0.5,0.5 --transition-step 90
    
    # Generate theme with matugen
    matugen image "$wallpaper" --mode "$mode" 2>&1 | grep -v "^⚠" | grep -v "^✖"
    
    # Save current wallpaper
    echo "WALLPAPER=$wallpaper" > "$CURRENT_THEME_FILE"
    echo "MODE=$mode" >> "$CURRENT_THEME_FILE"
    
    notify-send "Theme" "Applied wallpaper theme ($mode mode)" -i "$wallpaper"
}

# Set theme mode (light/dark)
set_mode() {
    local mode="$1"
    
    if [ "$mode" != "light" ] && [ "$mode" != "dark" ]; then
        echo "Invalid mode. Use 'light' or 'dark'"
        return 1
    fi
    
    # Update current theme file
    if [ -f "$CURRENT_THEME_FILE" ]; then
        sed -i "s/MODE=.*/MODE=$mode/" "$CURRENT_THEME_FILE"
    else
        echo "MODE=$mode" > "$CURRENT_THEME_FILE"
    fi
    
    # If wallpaper exists, regenerate theme with new mode
    local wallpaper=$(grep "WALLPAPER=" "$CURRENT_THEME_FILE" 2>/dev/null | cut -d= -f2)
    if [ -n "$wallpaper" ] && [ -f "$wallpaper" ]; then
        matugen image "$wallpaper" --mode "$mode" 2>&1 | grep -v "^⚠" | grep -v "^✖"
    fi
    
    notify-send "Theme" "Switched to $mode mode"
}

# Apply preset theme
apply_preset() {
    local preset="$1"
    local mode=$(get_mode)
    
    case "$preset" in
        "nord")
            matugen color hex "#2E3440" --mode "$mode"
            ;;
        "catppuccin")
            matugen color hex "#1E1E2E" --mode "$mode"
            ;;
        "gruvbox")
            matugen color hex "#282828" --mode "$mode"
            ;;
        "dracula")
            matugen color hex "#282A36" --mode "$mode"
            ;;
        "tokyo-night")
            matugen color hex "#1A1B26" --mode "$mode"
            ;;
        "synthwave")
            matugen color hex "#1A0A2E" --mode "$mode"
            ;;
        "forest")
            matugen color hex "#2D4A3E" --mode "$mode"
            ;;
        "ocean")
            matugen color hex "#1A2742" --mode "$mode"
            ;;
        *)
            echo "Unknown preset: $preset"
            return 1
            ;;
    esac
    
    notify-send "Theme" "Applied $preset preset ($mode mode)"
}

# Toggle light/dark mode
toggle_mode() {
    local current=$(get_mode)
    if [ "$current" = "dark" ]; then
        set_mode "light"
    else
        set_mode "dark"
    fi
}

# Pick wallpaper with rofi
pick_wallpaper() {
    local wallpapers_dir="$HOME/Pictures/Wallpapers"
    
    if [ ! -d "$wallpapers_dir" ]; then
        mkdir -p "$wallpapers_dir"
    fi
    
    local selected=$(find "$wallpapers_dir" -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" \) 2>/dev/null | \
        xargs -0 -I{} basename {} | \
        rofi -dmenu -p "Select Wallpaper:")
    
    if [ -n "$selected" ]; then
        set_wallpaper_theme "$wallpapers_dir/$selected"
    fi
}

# Show current theme info
show_info() {
    local mode=$(get_mode)
    local wallpaper=$(grep "WALLPAPER=" "$CURRENT_THEME_FILE" 2>/dev/null | cut -d= -f2)
    
    echo "Current Theme:"
    echo "  Mode: $mode"
    echo "  Wallpaper: ${wallpaper:-None}"
}

# Main command handler
case "$1" in
    set)
        set_wallpaper_theme "$2"
        ;;
    mode)
        set_mode "$2"
        ;;
    toggle)
        toggle_mode
        ;;
    preset)
        apply_preset "$2"
        ;;
    pick)
        pick_wallpaper
        ;;
    info)
        show_info
        ;;
    *)
        echo "Usage: theme.sh {set|mode|toggle|preset|pick|info}"
        echo "  set <wallpaper>   - Set wallpaper and generate theme"
        echo "  mode <light|dark> - Set theme mode"
        echo "  toggle            - Toggle between light/dark"
        echo "  preset <name>     - Apply preset theme"
        echo "  pick             - Pick wallpaper with rofi"
        echo "  info             - Show current theme info"
        ;;
esac
