#!/usr/bin/env bash
# Brightness control with OSD

ACTION=$1

case $ACTION in
    up)
        brightnessctl set 5%+
        ;;
    down)
        brightnessctl set 5%-
        ;;
esac

# Get current brightness percentage
BRIGHTNESS=$(brightnessctl -m | awk -F',' '{print $4}' | tr -d '%')

# Show OSD
quickshell ipc call osd showBrightness "$BRIGHTNESS" 2>/dev/null
