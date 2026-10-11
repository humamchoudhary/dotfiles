#!/usr/bin/env bash
# Wallpaper picker — fsel --dmenu inside a floating kitty window.
# Launch via: tui.sh wallpick <this script>
#
# Top level lists the wallpapers of the active theme, plus every
# theme-independent collection (a "__Name" directory under $WALLPAPERS_DIR,
# shown as "Name/"). Entering a collection opens its own list, whatever the
# active theme is; Esc there comes back to the top level.
#
# Images and gifs are drawn with awww, videos with mpvpaper — see
# wallpaper-lib.sh.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=wallpaper-lib.sh
source "$SCRIPT_DIR/wallpaper-lib.sh"

# An explicit argument overrides $WALLPAPERS_DIR (set by wallpaper-lib.sh)
[[ -n "$1" ]] && WALLPAPERS_DIR="$1"
STATE_DIR="$HOME/.config/hypr/state"
THEME_CACHE="$STATE_DIR/theme"
WALLPAPER_CACHE="$STATE_DIR/wallpaper"
PREVIEW="$SCRIPT_DIR/wallpaper-preview.sh"
HINTS="$HOME/.config/fsel/keyhints.sh wallpaper"

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

# Fallback: case-insensitive search if the direct lookup misses
if [[ ! -d "$THEME_DIR" ]]; then
    THEME_DIR=$(find "$WALLPAPERS_DIR" -maxdepth 1 -type d -iname "$DIR_NAME" | head -1)
fi

# Collections stay available even when the theme has no directory of its own
mapfile -t COLLECTIONS < <(wp_collections "$WALLPAPERS_DIR")

if [[ -z "$THEME_DIR" || ! -d "$THEME_DIR" ]] && [[ ${#COLLECTIONS[@]} -eq 0 ]]; then
    notify-send "Wallpaper Picker" "No wallpaper directory for theme: $CURRENT_THEME"
    exit 1
fi

# Apply a wallpaper and record it in the state file
set_wallpaper() {
    local wall="$1" prefix="$2"
    if [[ ! -f "$wall" ]]; then
        notify-send "Wallpaper Picker" "File not found: $(basename "$wall")"
        return 1
    fi
    wp_apply "$wall"
    local cached
    cached=$(wp_cache "$wall" "$prefix") && echo "$cached" > "$WALLPAPER_CACHE" \
        || echo "$wall" > "$WALLPAPER_CACHE"
}

# ── Collection list: pick one wallpaper out of __<name> ────────────────────────
# Returns 1 when the user backs out, so the caller can redraw the top level.
pick_from_collection() {
    local name="$1"
    local dir="$WALLPAPERS_DIR/__$name"
    local selected

    selected=$(wp_names "$dir")
    if [[ -z "$selected" ]]; then
        notify-send "Wallpaper Picker" "Collection is empty: $name"
        return 1
    fi

    selected=$(printf '%s\n' "$selected" \
        | WP_BASE="$dir" WP_ROOT="$WALLPAPERS_DIR" \
          fsel --dmenu --only-match --info-size 45 \
               --panel "keys:bottom:10:$HINTS" \
               --preview "$PREVIEW {}")

    [[ -z "$selected" ]] && return 1

    set_wallpaper "$dir/$selected" "$name"
    return 0
}

# ── Top level ─────────────────────────────────────────────────────────────────
while true; do
    # Collections first, then the active theme's own wallpapers
    rows=$(
        for c in "${COLLECTIONS[@]}"; do
            printf '%s/\n' "$(basename "$c" | sed 's/^__//')"
        done
        if [[ -n "$THEME_DIR" && -d "$THEME_DIR" ]]; then
            wp_names "$THEME_DIR"
        fi
    )

    if [[ -z "$rows" ]]; then
        notify-send "Wallpaper Picker" "No wallpapers found"
        exit 1
    fi

    selected=$(printf '%s\n' "$rows" \
        | WP_BASE="${THEME_DIR:-$WALLPAPERS_DIR}" WP_ROOT="$WALLPAPERS_DIR" \
          fsel --dmenu --only-match --info-size 45 \
               --panel "keys:bottom:10:$HINTS" \
               --preview "$PREVIEW {}")

    # Esc / no selection at the top level: done
    [[ -z "$selected" ]] && exit 0

    if [[ "$selected" == */ ]]; then
        # Collection: descend; backing out returns here
        pick_from_collection "${selected%/}" && exit 0
        continue
    fi

    set_wallpaper "$THEME_DIR/$selected" "$DIR_NAME"
    exit $?
done
