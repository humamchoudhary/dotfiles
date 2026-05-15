#!/bin/bash
# Screenshot: full screen or selected area
# Saves to ~/Pictures/screenshots/

DIR="$HOME/Pictures/screenshots"
mkdir -p "$DIR"
FILE="$DIR/$(date +%Y%m%d_%H%M%S).png"

case "$1" in
    full)
        grim "$FILE"
        ;;
    area)
        grim -g "$(slurp)" "$FILE"
        ;;
    *)
        echo "Usage: screenshot.sh [full|area]"
        exit 1
        ;;
esac

wl-copy < "$FILE" 2>/dev/null
notify-send "Screenshot saved" "$FILE"