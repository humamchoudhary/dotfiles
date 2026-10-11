#!/usr/bin/env bash
# wallpaper-preview.sh — emit preview bytes for one fsel row.
#
# usage: WP_BASE=<base-dir> WP_ROOT=<wallpapers-root> wallpaper-preview.sh <row>
#
# fsel renders whatever lands on stdout: raw image bytes become a picture,
# anything else is shown as text. So:
#   "Name/"      collection row -> thumbnail of its first wallpaper
#   video file   -> frame grabbed with ffmpegthumbnailer
#   image file   -> the file itself
#
# WP_BASE is the directory a plain file row is relative to; collection rows are
# resolved against WP_ROOT, as $WP_ROOT/__<Name>.
#
# The directories come in through the environment rather than as arguments:
# fsel parses the --preview string itself, and a path containing a quote gets
# truncated no matter how it is escaped. Only the {} row is passed as an
# argument, which fsel does quote correctly.

LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/wallpaper-lib.sh"
# shellcheck source=wallpaper-lib.sh
source "$LIB"

BASE="$WP_BASE"
ROOT="$WP_ROOT"
ROW="$1"

[[ -z "$ROW" ]] && exit 0

# Collection row: resolve to the first wallpaper inside it
if [[ "$ROW" == */ ]]; then
    name="${ROW%/}"
    dir="$ROOT/__$name"
    [[ -d "$dir" ]] || { echo "missing: $dir"; exit 0; }
    mapfile -t items < <(wp_list "$dir" | sort)
    if [[ ${#items[@]} -eq 0 ]]; then
        echo "$name — empty collection"
        exit 0
    fi
    TARGET="${items[0]}"
else
    TARGET="$BASE/$ROW"
fi

[[ -f "$TARGET" ]] || { echo "not found: $ROW"; exit 0; }

if wp_is_video "$TARGET"; then
    ffmpegthumbnailer -i "$TARGET" -o - -s 1024 -q 8 -c png 2>/dev/null \
        || ffmpeg -loglevel quiet -i "$TARGET" -vframes 1 -f image2pipe -vcodec png - 2>/dev/null \
        || echo "video: $(basename "$TARGET")"
else
    cat -- "$TARGET"
fi
