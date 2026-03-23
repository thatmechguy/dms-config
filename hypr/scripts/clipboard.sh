#!/usr/bin/env bash
# Clipboard manager with cliphist

# Store clipboard history
wl-paste --watch cliphist store &

# Show clipboard history with rofi
case $1 in
    show)
        cliphist list | rofi -dmenu -p "Clipboard:" -theme-str 'window {width: 600px; height: 400px;}' | cliphist decode | wl-copy
        ;;
    clear)
        cliphist wipe
        notify-send "Clipboard" "History cleared"
        ;;
    *)
        echo "Usage: $0 {show|clear}"
        ;;
esac
