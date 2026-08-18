#!/usr/bin/env bash
# Clipboard picker with preview via cliphist + rofi
# Each entry carries a thumbnail:// icon whose path is the entry id, so
# rofi calls clip-preview.sh (via -preview-cmd) to render the highlighted item.

selection=$(cliphist list | while IFS= read -r line; do
    id=${line%%$'\t'*}
    printf '%s\0icon\x1fthumbnail://%s\n' "$line" "$id"
done | rofi -dmenu \
    -p "󰅍 " \
    -show-icons \
    -theme "$HOME/.config/rofi/clipboard.rasi" \
    -preview-cmd "$HOME/.config/hypr/scripts/clip-preview.sh {input} {output} {size}")

[ -n "$selection" ] && printf '%s' "$selection" | cliphist decode | wl-copy
