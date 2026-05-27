#!/usr/bin/env bash
# Rofi wallpaper picker — only shows wallpapers for the currently active theme.

WALLPAPERS_DIR="${1:-$HOME/wallpapers}"
STATE_DIR="$HOME/.config/hypr/state"
THEME_CACHE="$STATE_DIR/theme"
WALLPAPER_CACHE="$STATE_DIR/wallpaper"

mkdir -p "$STATE_DIR"

# Determine active theme
if [[ -f "$THEME_CACHE" ]]; then
    CURRENT_THEME=$(cat "$THEME_CACHE")
else
    CURRENT_THEME="Neon Purple"
fi

DIR_NAME="${CURRENT_THEME// /_}"
THEME_DIR="$WALLPAPERS_DIR/$DIR_NAME"

if [[ ! -d "$THEME_DIR" ]]; then
    notify-send "Wallpaper Picker" "No wallpaper directory for theme: $CURRENT_THEME"
    exit 1
fi

# Build rofi input: "filename NUL icon US full_path NEWLINE"
selected=$(
    find "$THEME_DIR" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
           -o -iname '*.webp' -o -iname '*.bmp' \) \
    | sort \
    | while IFS= read -r path; do
        printf '%s\000icon\037%s\n' "$(basename "$path")" "$path"
    done \
    | rofi -dmenu \
           -p "" \
           -mesg "$CURRENT_THEME" \
           -show-icons \
           -theme-str '
               window    { width: 900px; border-radius: 12px; }
               listview  { columns: 4; lines: 3; spacing: 8px; padding: 8px; }
               element   { orientation: vertical; border-radius: 8px; padding: 4px; }
               element-icon { size: 180px; }
               element-text { horizontal-align: 0.5; padding: 4px 0 0 0; }
           ' \
    | head -n1
)

[[ -z "$selected" ]] && exit 0

WALL_PATH="$THEME_DIR/$selected"

if [[ ! -f "$WALL_PATH" ]]; then
    notify-send "Wallpaper Picker" "File not found: $selected"
    exit 1
fi

swww img "$WALL_PATH" --transition-type fade --transition-duration 1
echo "$WALL_PATH" > "$WALLPAPER_CACHE"
