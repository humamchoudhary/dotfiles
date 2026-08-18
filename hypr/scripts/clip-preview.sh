#!/usr/bin/env bash
# rofi -preview-cmd handler: renders a cliphist entry into {output}.
# Args: {input}=entry id (from thumbnail://<id>)  {output}=png path  {size}=px
id="$1"
output="$2"
size="${3:-452}"

decoded=$(printf '%s' "$id" | cliphist decode 2>/dev/null)

# Binary image entry: thumbnail it directly, padded on the panel background.
mime=$(printf '%s' "$decoded" | file --mime-type - 2>/dev/null | awk '{print $2}')
if [[ "$mime" == image/* ]]; then
    pad=40
    inner=$((size - pad * 2))
    printf '%s' "$decoded" | convert - \
        -resize "${inner}x${inner}>" \
        -bordercolor "#131316" -border "$pad" \
        "$output" 2>/dev/null
    exit 0
fi

# Text entry: render as a clean text panel. Render at 2x for crisp glyphs.
render=$((size * 2))
pad=72
txt_file="${output}.txt"
printf '%s' "$decoded" | head -60 | expand > "$txt_file"

convert \
    -size "$((render - pad * 2))x" \
    -background "#131316" \
    -fill "#c8c8d4" \
    -font "JetBrains-Mono-Regular" \
    -pointsize 30 \
    -gravity NorthWest \
    "caption:@${txt_file}" \
    -background "#131316" \
    -gravity NorthWest \
    -extent "$((render - pad * 2))x$((render - pad * 2))" \
    -bordercolor "#131316" -border "$pad" \
    "$output" 2>/dev/null

rm -f "$txt_file"
