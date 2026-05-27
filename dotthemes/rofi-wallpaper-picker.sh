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

# Resolve the wallpaper directory from the filesystem using underscore names.
# Folder names use spaces-replaced-with-underscores, so we look for an exact
# match on disk rather than assuming a specific conversion.
DIR_NAME="${CURRENT_THEME// /_}"
THEME_DIR="$WALLPAPERS_DIR/$DIR_NAME"
echo ${THEME_DIR}

# Fallback: case-insensitive search if the direct lookup misses
if [[ ! -d "$THEME_DIR" ]]; then
    THEME_DIR=$(find "$WALLPAPERS_DIR" -maxdepth 1 -type d -iname "$DIR_NAME" | head -1)
fi

if [[ -z "$THEME_DIR" || ! -d "$THEME_DIR" ]]; then
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
           -matching fuzzy \
           -p "" \
           -mesg "$CURRENT_THEME" \
           -show-icons \
           -theme "$HOME/.config/rofi/wallpaper-picker.rasi" \
    | head -n1
)

[[ -z "$selected" ]] && exit 0

WALL_PATH="$THEME_DIR/$selected"
echo ${WALL_PATH}
if [[ ! -f "$WALL_PATH" ]]; then
    notify-send "Wallpaper Picker" "File not found: $selected"
    exit 1
fi

awww img "$WALL_PATH" --transition-type fade --transition-duration 1
echo "$WALL_PATH" > "$WALLPAPER_CACHE"
