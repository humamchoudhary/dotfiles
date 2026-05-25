#!/usr/bin/env bash
# Wallpaper selector using rofi + swww

WALLPAPERS_DIR="${1:-$HOME/wallpapers}"

# ── pick theme ────────────────────────────────────────────────────────────────
theme=$(
  ls -1 "$WALLPAPERS_DIR" \
    | grep -v '^_unmatched$' \
    | rofi -dmenu \
           -p "Theme" \
           -mesg "Select a theme" \
           -theme-str 'window {width: 400px;}'
)

[[ -z "$theme" ]] && exit 0

THEME_DIR="$WALLPAPERS_DIR/$theme"

[[ ! -d "$THEME_DIR" ]] && { notify-send "wallpaper-selector" "Theme not found: $theme"; exit 1; }

# ── pick wallpaper (with image preview via rofi-icon) ────────────────────────
wallpaper=$(
  find "$THEME_DIR" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
       -o -iname '*.webp' -o -iname '*.bmp' \) \
    -printf "%f\0%p\n" \
  | awk -F'\0' '
      { name=$1; path=$2 }
      { print name "\0icon\x1f" path }
    ' \
  | rofi -dmenu \
         -p "Wallpaper" \
         -mesg "$theme" \
         -show-icons \
         -theme-str '
           window    { width: 800px; }
           listview  { columns: 4; lines: 3; }
           element   { orientation: vertical; }
           element-icon { size: 160px; }
           element-text { horizontal-align: 0.5; }
         ' \
  | head -n1
)

[[ -z "$wallpaper" ]] && exit 0

# ── apply ─────────────────────────────────────────────────────────────────────
swww img "$THEME_DIR/$wallpaper" \
  --transition-type fade \
  --transition-duration 1
