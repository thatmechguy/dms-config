#!/usr/bin/env bash
# Volume control with OSD

ACTION=$1

case $ACTION in
    up)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
        ;;
    down)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        ;;
    mute)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
esac

# Get current volume
VOLUME=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100}')
MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -c MUTED)

if [ "$MUTED" -eq 1 ]; then
    VOLUME=0
fi

# Show OSD
quickshell ipc call osd showVolume "$VOLUME" 2>/dev/null
