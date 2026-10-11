#!/usr/bin/env bash
# wallpaper-lib.sh — shared wallpaper helpers (sourced, not executed).
#
# Knows the two kinds of wallpaper we support and which backend draws them:
#   images + animated gifs -> awww
#   videos                 -> mpvpaper
#
# Also defines the "collection" convention: directories under $WALLPAPERS_DIR
# whose name starts with "__" (e.g. __Minimal) are theme-independent sets that
# the picker offers regardless of the active theme.

# Where wallpapers live. Override by exporting WALLPAPERS_DIR (set for the
# whole session in hypr/conf/env.lua); every script that sources this file
# picks it up, so the path is configured in exactly one place.
WALLPAPERS_DIR="${WALLPAPERS_DIR:-$HOME/wallpapers}"

# Local copies of the applied wallpaper, so it survives the source going away.
WALLPAPER_CACHE_DIR="${WALLPAPER_CACHE_DIR:-$HOME/.cache/hypr/wallpapers}"

WP_IMAGE_EXTS=(jpg jpeg png webp bmp gif avif tiff)
WP_VIDEO_EXTS=(mp4 mkv webm mov avi m4v flv wmv)

# find(1) predicate group matching every supported wallpaper, e.g.
#   find "$dir" -maxdepth 1 \( -type f -o -xtype f \) $(wp_find_exts)
wp_find_exts() {
    local out=() ext
    for ext in "${WP_IMAGE_EXTS[@]}" "${WP_VIDEO_EXTS[@]}"; do
        out+=(-o -iname "*.$ext")
    done
    printf '%s ' '(' "${out[@]:1}" ')'
}

# List every wallpaper in a directory, one absolute path per line.
# Follows symlinks (organize-wallpapers.sh links into the theme dirs).
wp_list() {
    local dir="$1"
    local exprs=() ext
    for ext in "${WP_IMAGE_EXTS[@]}" "${WP_VIDEO_EXTS[@]}"; do
        exprs+=(-o -iname "*.$ext")
    done
    find "$dir" -maxdepth 1 \( -type f -o -xtype f \) \
        \( "${exprs[@]:1}" \) 2>/dev/null
}

# List just the file names in a directory, sorted, one per line.
# Never pipe wp_list through `xargs basename`: xargs splits on whitespace and
# treats quotes as special, which mangles names like "my wallpaper.png" or
# "it's mine.png". Read whole lines instead.
wp_names() {
    local dir="$1" path
    while IFS= read -r path; do
        printf '%s\n' "${path##*/}"
    done < <(wp_list "$dir") | sort
}

wp_is_video() {
    local ext="${1##*.}"
    ext="${ext,,}"
    local v
    for v in "${WP_VIDEO_EXTS[@]}"; do
        [[ "$ext" == "$v" ]] && return 0
    done
    return 1
}

# Draw a wallpaper, picking the backend from its extension.
#   wp_apply <path> [transition]     transition is awww-only (default: fade)
wp_apply() {
    local wall="$1" transition="${2:-fade}"

    # Only one backend may own the background layer at a time.
    pkill -x mpvpaper 2>/dev/null

    if wp_is_video "$wall"; then
        # Black out awww so nothing shows through while mpv starts up.
        awww clear 000000 2>/dev/null
        # setsid, not mpvpaper's own -f: the pickers run inside a kitty window
        # that exits the moment a wallpaper is chosen, and a merely forked
        # mpvpaper dies with that process group. A new session survives it.
        setsid -f mpvpaper -p -a MAX \
            -o "no-audio --loop-file=inf --loop-playlist=inf --hwdec=auto --panscan=1.0" \
            '*' "$wall" </dev/null >/dev/null 2>&1
    else
        awww img "$wall" --transition-type "$transition" --transition-duration 1
    fi
}

# Copy a wallpaper into the local cache so it survives the source going away
# (the theme dirs are symlinks into ~/wallpapers/.all). Prints the cached path.
#   wp_cache <path> <prefix>
wp_cache() {
    local wall="$1" prefix="$2"
    local cache_dir="$WALLPAPER_CACHE_DIR"
    mkdir -p "$cache_dir"
    local cached="$cache_dir/${prefix}_$(basename "$wall")"
    cp -L -- "$wall" "$cached" 2>/dev/null || return 1
    printf '%s\n' "$cached"
}

# Theme-independent collection dirs ("__Name"), one absolute path per line.
wp_collections() {
    local root="$1"
    find "$root" -maxdepth 1 -mindepth 1 -type d -name '__*' 2>/dev/null | sort
}
