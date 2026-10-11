#!/usr/bin/env bash
# keyhints.sh — one-line keybind hint for an fsel menu.
#
# usage: keyhints.sh <mode>     mode: wallpaper | theme | power | generic
#
# Rendered inside fsel's dmenu panel (see --panel in the picker scripts).
# cclip mode can't use this: fsel's --panel implies --dmenu and the two
# modes are mutually exclusive, so the clipboard menu gets its hints from
# kitty's tab bar instead (see hypr/conf/keybinds.lua).
#
# The accent color is read from Hyprland state at run time, so the hints
# follow the active theme without theme-picker.sh having to rewrite them.

STATE_DIR="$HOME/.config/hypr/state"
ACCENT=$(cat "$STATE_DIR/accent" 2>/dev/null)
ACCENT="${ACCENT#\#}"

if [[ ${#ACCENT} -eq 6 ]]; then
    r=$((16#${ACCENT:0:2})) g=$((16#${ACCENT:2:2})) b=$((16#${ACCENT:4:2}))
    KEY=$'\033['"1;38;2;${r};${g};${b}m"
else
    KEY=$'\033[1m'
fi
DESC=$'\033[2m'
OFF=$'\033[0m'

# key() <key> <description>
key() { printf '%s%s%s %s%s%s   ' "$KEY" "$1" "$OFF" "$DESC" "$2" "$OFF"; }

printf '  '
case "${1:-generic}" in
    wallpaper)
        key "enter" "set"
        key "esc" "close"
        key "name/" "open collection"
        key "^j/^k" "move"
        ;;
    theme)
        key "enter" "apply"
        key "esc" "close"
        key "^j/^k" "move"
        key "type" "filter"
        ;;
    power)
        key "enter" "confirm"
        key "esc" "cancel"
        key "^j/^k" "move"
        ;;
    *)
        key "enter" "select"
        key "esc" "cancel"
        key "^j/^k" "move"
        key "type" "filter"
        ;;
esac
printf '\n'
