#!/bin/bash
# Set wallpaper via awww — expects a plain black image by default

WALL_DIR="$HOME/.config/hypr/wallpapers"
WALL="${1:-$WALL_DIR/black.png}"

if [ ! -f "$WALL" ]; then
    echo "Wallpaper not found: $WALL — generating solid black"
    convert -size 1920x1080 xc:black "$WALL" 2>/dev/null || \
        magick -size 1920x1080 xc:black "$WALL" 2>/dev/null || true
fi

awww img "$WALL" --transition-type fade --transition-duration 1