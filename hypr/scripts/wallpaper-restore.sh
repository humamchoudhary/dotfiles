#!/bin/bash
# Restores the cached wallpaper on Hyprland startup.
# Run once after awww-daemon starts; falls back gracefully through several options.

# shellcheck source=../../dotthemes/wallpaper-lib.sh
source "$HOME/.config/dotthemes/wallpaper-lib.sh"

STATE_DIR="$HOME/.config/hypr/state"
WALLPAPER_CACHE="$STATE_DIR/wallpaper"
THEME_CACHE="$STATE_DIR/theme"

# Wait for awww-daemon to be ready (up to 10 s)
for _ in $(seq 1 20); do
    awww query &>/dev/null && break
    sleep 0.5
done

# Restore Hyprland border colors from saved state
if [[ -f "$STATE_DIR/accent" && -f "$STATE_DIR/accent_dim" ]]; then
    accent=$(cat "$STATE_DIR/accent")
    muted=$(cat  "$STATE_DIR/accent_dim")
    accent_hex="${accent#\#}"
    muted_hex="${muted#\#}"
    hyprctl keyword general:col.active_border   "rgba(${accent_hex}ff)" 2>/dev/null
    hyprctl keyword general:col.inactive_border "rgba(${muted_hex}33)"  2>/dev/null
fi

# 1. Try the cached wallpaper path
if [[ -f "$WALLPAPER_CACHE" ]]; then
    WALL=$(cat "$WALLPAPER_CACHE")
    if [[ -f "$WALL" ]]; then
        # awww for images/gifs, mpvpaper for videos
        wp_apply "$WALL" none
        exit 0
    fi
fi

# 2. Fall back to a random wallpaper from the current theme's directory
if [[ -f "$THEME_CACHE" ]]; then
    THEME=$(cat "$THEME_CACHE")
    DIR_NAME="${THEME// /_}"
    THEME_DIR="$WALLPAPERS_DIR/$DIR_NAME"
    # Case-insensitive fallback if direct lookup misses
    [[ ! -d "$THEME_DIR" ]] && \
        THEME_DIR=$(find "$WALLPAPERS_DIR" -maxdepth 1 -type d -iname "$DIR_NAME" | head -1)
    if [[ -n "$THEME_DIR" && -d "$THEME_DIR" ]]; then
        mapfile -t walls < <(wp_list "$THEME_DIR")
        if [[ ${#walls[@]} -gt 0 ]]; then
            WALL="${walls[RANDOM % ${#walls[@]}]}"
            wp_apply "$WALL" none
            # Cache a local copy so the wallpaper works offline
            if CACHED_WALL=$(wp_cache "$WALL" "$DIR_NAME"); then
                echo "$CACHED_WALL" > "$WALLPAPER_CACHE"
            else
                echo "$WALL" > "$WALLPAPER_CACHE"
            fi
            exit 0
        fi
    fi
fi

# 3. Final fallback: solid black image
WALL_DIR="$HOME/.config/hypr/wallpapers"
mkdir -p "$WALL_DIR"
WALL="$WALL_DIR/black.png"
if [[ ! -f "$WALL" ]]; then
    convert -size 1920x1080 xc:black "$WALL" 2>/dev/null || \
        magick  -size 1920x1080 xc:black "$WALL" 2>/dev/null || true
fi
awww img "$WALL" --transition-type none
