#!/usr/bin/env bash
#
# organize-wallpapers.sh — classify wallpapers into your color palettes.
#
# Scans $WALLPAPERS_DIR/.all/ (default ~/wallpapers/.all), extracts the
# dominant colors of each image with
# ImageMagick, matches it against the palettes defined in dotthemes/colors.json
# and symlinks it into $WALLPAPERS_DIR/<Palette>/.
# An image can belong to multiple palettes. Re-running is safe: existing
# symlinks are skipped, stale/broken ones are cleaned, and only new images
# are processed (dominant colors are cached).
#
# Usage:
#   organize-wallpapers.sh [options]
#
# Options:
#   -j, --json FILE     Path to colors.json (default: colors.json next to
#                       this script)
#   -r, --ratio F       Fraction of palette colors that must be close to an
#                       image color for a match (0-1). Default: 0.5
#   -c, --cap N         "Close" distance in RGB space (0-441). Default: 120
#   -m, --max N         Max palettes an image is linked to (best N by score).
#                       Default: 3
#   -n, --dry-run       Show what would be linked without touching anything
#       --prune         Remove palette dirs that are no longer defined and
#                       stale symlinks pointing into .all/ ("__Name"
#                       collection dirs are always left alone)
#   -h, --help          Show this help
#
set -euo pipefail

# Wallpaper root: $WALLPAPERS_DIR (see hypr/conf/env.lua), with the older
# WALLPAPER_SRC / WALLPAPER_OUT still honoured for finer control.
WALLPAPERS_DIR="${WALLPAPERS_DIR:-/games/wallpapers}"
ALL_DIR="${WALLPAPER_SRC:-$WALLPAPERS_DIR/.all}"
OUT_DIR="${WALLPAPER_OUT:-$WALLPAPERS_DIR}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-organizer"
THEMES_JSON="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/colors.json"
MATCH_RATIO=0.4
CLOSE_DIST=120
ACCENT_WEIGHT=2
MAX_PER_IMAGE=3
COLORS=10
DRY_RUN=0
PRUNE=0

usage() { grep '^# ' "$0" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
    case "$1" in
        -j|--json)      THEMES_JSON="$2"; shift 2 ;;
        -c|--cap)       CLOSE_DIST="$2"; shift 2 ;;
        -r|--ratio)     MATCH_RATIO="$2"; shift 2 ;;
        -m|--max)       MAX_PER_IMAGE="$2"; shift 2 ;;
        -n|--dry-run)   DRY_RUN=1; shift ;;
        --prune)        PRUNE=1; shift ;;
        -h|--help)      usage; exit 0 ;;
        *)              echo "Unknown option: $1" >&2; usage; exit 1 ;;
    esac
done

# --- palettes from colors.json ----------------------------------------------
# palette file format: <dir_name><TAB>hex colors (same order as the JSON)
# dir_name = palette name with spaces replaced by underscores
command -v jq >/dev/null 2>&1 || { echo "Error: jq not found" >&2; exit 1; }
command -v magick >/dev/null 2>&1 || { echo "Error: ImageMagick (magick) not found" >&2; exit 1; }
command -v md5sum >/dev/null 2>&1 || { echo "Error: md5sum not found" >&2; exit 1; }

[ -f "$THEMES_JSON" ] || { echo "Error: $THEMES_JSON not found" >&2; exit 1; }
[ -d "$ALL_DIR" ] || { echo "Error: $ALL_DIR does not exist" >&2; exit 1; }

mkdir -p "$CACHE_DIR"
# --- palettes from colors.json ----------------------------------------------
# palette file format: <dir_name><TAB>hex colors (same order as the JSON)
# dir_name = palette name with spaces replaced by underscores
jq -r '.[] | [(.palette | gsub(" "; "_")), ([.colors[].hex] | join(" "))] | @tsv' \
    "$THEMES_JSON" > "$CACHE_DIR/palettes.tsv"
PALETTE_FILE="$CACHE_DIR/palettes.tsv"
PALETTE_NAMES=$(cut -f1 "$PALETTE_FILE")

# --- helpers ----------------------------------------------------------------

# extract dominant hex colors of an image with their pixel share (cached by
# path+size+mtime); emits tokens of the form "count:#HEX"
get_colors() {
    local src="$1" key cache
    key=$(printf '%s|%s|%s|%s|hist' "$src" "$(stat -Lc %s "$src")" "$(stat -Lc %Y "$src")" "$COLORS" \
        | md5sum | cut -d' ' -f1)
    cache="$CACHE_DIR/colors/$key"
    if [ ! -s "$cache" ]; then
        mkdir -p "$CACHE_DIR/colors"
        magick "$src[0]" -resize 200x200 -colors "$COLORS" -depth 8 -format %c histogram:info:- \
            | sed -nE 's/^ *([0-9]+):.*#([0-9A-Fa-f]{6}).*/\1:\U\2\E/p' \
            > "$cache" 2>/dev/null || : > "$cache"
    fi
    tr '\n' ' ' < "$cache"
}
# match image colors against every palette; prints "name<TAB>score" per hit
# (sorted by score, best first, limited to MAX_PER_IMAGE)
#
# An image matches a palette if at least MATCH_RATIO (0-1) of the palette
# colors are "close" to some image color, close = within CLOSE_DIST
# (RGB euclidean). Score = mean distance of all palette colors;
# accent / accent_dim (last two colors in the JSON) count double.
match_palettes() {
    local hexes="$1"
    awk -v ratio="$MATCH_RATIO" -v closelimit="$CLOSE_DIST" -v accw="$ACCENT_WEIGHT" -v img="$hexes" '
        function hd(c) { return index("0123456789ABCDEF", c) - 1 }
        function hex2rgb(s, t) {
            split("", t, " ")
            t[1] = hd(substr(s,2,1))*16 + hd(substr(s,3,1))
            t[2] = hd(substr(s,4,1))*16 + hd(substr(s,5,1))
            t[3] = hd(substr(s,6,1))*16 + hd(substr(s,7,1))
        }
        BEGIN {
            n = split(img, a, " ")
            for (i = 1; i <= n; i++) {
                split(a[i], b, ":")
                hex2rgb(b[2], t); ir[i]=t[1]; ig[i]=t[2]; ib[i]=t[3]
            }
        }
        {
            hit = 0; wsum = 0; sum = 0; cnt = 0
            for (j = 2; j <= NF; j++) {
                w = (j >= NF - 1) ? accw : 1
                hex2rgb($j, t); pr=t[1]; pg=t[2]; pb=t[3]
                best = 1000
                for (k = 1; k <= n; k++) {
                    dr = pr - ir[k]; dg = pg - ig[k]; db = pb - ib[k]
                    d = sqrt(dr*dr + dg*dg + db*db)
                    if (d < best) best = d
                }
                cnt++
                sum += best
                wsum += w
                if (best <= closelimit) { hit += w }
            }
            if (cnt == 0 || hit / wsum < ratio) next
            printf "%s\t%.1f\n", $1, sum / cnt
        }
    ' "$PALETTE_FILE" | sort -t$'\t' -k2,2n | head -n "$MAX_PER_IMAGE"
}

# create dir + symlink (idempotent); returns 0 if created, 1 if already there
link_into() {
    local dir="$1" src="$2"
    local name link target
    name=$(basename "$src")
    link="$dir/$name"
    target=$(readlink -f "$src")
    if [ -L "$link" ] && [ "$(readlink -f "$link" 2>/dev/null || true)" = "$target" ]; then
        return 1
    fi
    if [ "$DRY_RUN" -eq 0 ]; then
        mkdir -p "$dir"
        ln -sfn "$target" "$link"
    fi
    return 0
}

# --- cleanup ----------------------------------------------------------------

# remove broken symlinks in every existing theme dir
cleanup_broken() {
    local dir link
    while IFS= read -r -d '' link; do
        [ -e "$link" ] || { [ "$DRY_RUN" -eq 0 ] && rm -f "$link" || true; \
            echo "  clean: removed stale $(basename "$(dirname "$link")")/$(basename "$link")"; }
    done < <(find "$OUT_DIR" -maxdepth 2 -type l -print0 2>/dev/null)
}

# remove theme dirs that are no longer in the palette list
prune_dirs() {
    local dir name
    while IFS= read -r -d '' dir; do
        name=$(basename "$dir")
        [ "$name" = "_unmatched" ] && continue
        # "__Name" dirs are hand-curated, theme-independent collections
        case "$name" in __*) continue ;; esac
        grep -qx "$name" <<< "$PALETTE_NAMES" && continue
        local removed=0 link tgt
        while IFS= read -r -d '' link; do
            tgt=$(readlink -f "$link") || true
            case "$tgt" in
                "$ALL_DIR"/*)
                    [ "$DRY_RUN" -eq 0 ] && rm -f "$link"
                    removed=$((removed + 1)) ;;
            esac
        done < <(find "$dir" -maxdepth 1 -type l -print0)
        if [ "$removed" -gt 0 ]; then
            echo "  prune: $name ($removed links removed)"
        fi
        if [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
            [ "$DRY_RUN" -eq 0 ] && rmdir "$dir"
            echo "  prune: removed empty dir $name"
        fi
    done < <(find "$OUT_DIR" -maxdepth 1 -mindepth 1 -type d -print0)
}

# --- main -------------------------------------------------------------------

total=0; count=0; new_links=0; skipped=0; unmatched=0; failed=0

if [ "$DRY_RUN" -eq 1 ]; then
    echo "=== DRY RUN (no changes will be made) ==="
fi

cleanup_broken
[ "$PRUNE" -eq 1 ] && prune_dirs

echo
echo "Scanning $ALL_DIR ..."
while IFS= read -r -d '' src; do
    count=$((count + 1))
    name=$(basename "$src")
    hexes=$(get_colors "$src")
    if [ -z "${hexes// /}" ]; then
        echo "  ! could not read colors: $name"
        failed=$((failed + 1))
        continue
    fi

    hits=$(match_palettes "$hexes")
    linked_any=0
    if [ -n "$hits" ]; then
        while IFS=$'\t' read -r theme score; do
            dir="$OUT_DIR/$theme"
            if link_into "$dir" "$src"; then
                echo "  + $name -> $theme (score $score)"
                new_links=$((new_links + 1))
            else
                skipped=$((skipped + 1))
            fi
            linked_any=1
        done <<< "$hits"
    fi

    if [ "$linked_any" -eq 0 ]; then
        echo "  - $name -> no palette match"
        if link_into "$OUT_DIR/_unmatched" "$src"; then
            echo "    linked to _unmatched"
        fi
        unmatched=$((unmatched + 1))
    fi
    total=$((total + 1))
done < <(find "$ALL_DIR" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
       -o -iname '*.webp' -o -iname '*.bmp' -o -iname '*.gif' \) -print0)

echo
echo "=== Summary ==="
echo "Images processed: $total"
echo "New symlinks:     $new_links"
echo "Already linked:   $skipped"
echo "Unmatched:        $unmatched"
echo "Failed:           $failed"
echo
echo "Per-theme totals:"
for theme in $(cut -f1 "$PALETTE_FILE"); do
    c=$(find "$OUT_DIR/$theme" -maxdepth 1 -type l 2>/dev/null | wc -l || true)
    [ "$c" -gt 0 ] && printf '  %-24s %s\n' "$theme" "$c"
done
c=$(find "$OUT_DIR/_unmatched" -maxdepth 1 -type l 2>/dev/null | wc -l || true)
[ "$c" -gt 0 ] && printf '  %-24s %s\n' "_unmatched" "$c"
