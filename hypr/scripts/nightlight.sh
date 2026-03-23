#!/usr/bin/env bash
# Night light toggle for Windows 11 style

PIDFILE="/tmp/gammastep.pid"

case $1 in
    on)
        if [ -f "$PIDFILE" ]; then
            notify-send "Night Light" "Already enabled"
        else
            gammastep -l 0:0 -t 6500:3500 -b 1:0.8 &
            echo $! > "$PIDFILE"
            notify-send "Night Light" "Enabled"
        fi
        ;;
    off)
        if [ -f "$PIDFILE" ]; then
            kill $(cat "$PIDFILE") 2>/dev/null
            rm "$PIDFILE"
            gammastep -x
            notify-send "Night Light" "Disabled"
        else
            notify-send "Night Light" "Already disabled"
        fi
        ;;
    toggle)
        if [ -f "$PIDFILE" ]; then
            $0 off
        else
            $0 on
        fi
        ;;
    *)
        echo "Usage: $0 {on|off|toggle}"
        ;;
esac
