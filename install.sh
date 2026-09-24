#!/usr/bin/env bash
#
# Link dotfiles into place.
#
# Each TOP-LEVEL DIRECTORY is symlinked as a whole:
#
#     ~/dotfiles/hypr  ->  ~/.config/hypr
#
# rather than mirroring every file inside it. That means a new file added to
# the repo is live immediately -- no need to re-run this script.
#
# An existing real directory at the destination is moved aside to <dir>.bak
# before the link is made.
#
# WHY NOT PER-FILE: the previous version walked `find -type f` and linked each
# file individually. Once any destination directory was itself a symlink back
# into the repo, `dest` resolved to the SAME path as `src`, so the "back up the
# existing file" step renamed the repo's own file to .bak and then linked it to
# itself -- leaving a broken self-reference and, on a second run, a .bak.bak.
# That is what happened to nvim/lua/lang/{lsp,dap}.lua. Linking whole folders
# removes the entire class of bug, and the guard in link_dir() below refuses
# any destination that resolves inside the repo.

set -euo pipefail

DOTFILES="${HOME}/dotfiles"
CONFIG="${HOME}/.config"

DRY_RUN=0
[[ "${1:-}" == "--dry-run" || "${1:-}" == "-n" ]] && DRY_RUN=1
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    sed -n '2,25p' "$0" | sed 's/^#//'
    echo "Usage: $(basename "$0") [--dry-run|-n]"
    exit 0
fi

# Top-level entries that are never linked.
#   .claude  -- ~/.claude is Claude Code's real state directory (projects,
#               history, memory). Folder-linking it would replace all of that
#               with this repo. Its one tracked file is handled in FILE_LINKS.
IGNORE=(.git .github .gitignore .claude install.sh README.md LICENSE)

# Genuine per-file exceptions: "<path relative to repo>" -> "<absolute dest>"
declare -A FILE_LINKS=(
    [".claude/settings.local.json"]="${HOME}/.claude/settings.local.json"
)

linked=0 backed_up=0 skipped=0

run() {
    if (( DRY_RUN )); then
        echo "      would: $*"
    else
        "$@"
    fi
}

# Move an existing destination aside. Never cascades into .bak.bak: if a .bak
# is already there, the new one gets a timestamp.
backup() {
    local dest="$1" bak="$1.bak"
    if [[ -e "$bak" || -L "$bak" ]]; then
        bak="$1.bak.$(date +%Y%m%d%H%M%S)"
    fi
    echo "    backing up -> $(basename "$bak")"
    run mv -- "$dest" "$bak"
    (( ++backed_up ))
}

link_dir() {
    local src="$1" dest="$2" name
    name="$(basename "$dest")"

    # Guard: never write to anything that resolves back inside the repo.
    # This is what the old script got wrong.
    local resolved
    resolved="$(readlink -f "$(dirname "$dest")" 2>/dev/null || true)"
    if [[ -n "$resolved" && "$resolved" == "$DOTFILES"* ]]; then
        echo "  !  $name: destination resolves inside the repo, refusing"
        (( ++skipped ))
        return
    fi

    # Already pointing where we want it.
    if [[ -L "$dest" && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
        echo "  =  $name (already linked)"
        (( ++skipped ))
        return
    fi

    echo "  ->  $name"

    if [[ -L "$dest" ]]; then
        # A wrong symlink: just drop it, there is nothing to preserve.
        run rm -- "$dest"
    elif [[ -e "$dest" ]]; then
        backup "$dest"
    fi

    run mkdir -p -- "$(dirname "$dest")"
    run ln -s -- "$src" "$dest"
    (( ++linked ))
}

link_file() {
    local src="$1" dest="$2" name
    name="$(basename "$dest")"

    [[ -e "$src" ]] || return 0

    if [[ -L "$dest" && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
        echo "  =  $name (already linked)"
        (( ++skipped ))
        return
    fi

    echo "  ->  $name"
    if [[ -L "$dest" ]]; then
        run rm -- "$dest"
    elif [[ -e "$dest" ]]; then
        backup "$dest"
    fi

    run mkdir -p -- "$(dirname "$dest")"
    run ln -s -- "$src" "$dest"
    (( ++linked ))
}

is_ignored() {
    local name="$1" ig
    for ig in "${IGNORE[@]}"; do
        [[ "$name" == "$ig" ]] && return 0
    done
    return 1
}

echo
(( DRY_RUN )) && echo "DRY RUN -- nothing will be changed" && echo
echo "Linking directories into $CONFIG"
echo

for src in "$DOTFILES"/*/ "$DOTFILES"/.*/; do
    [[ -d "$src" ]] || continue
    src="${src%/}"
    name="$(basename "$src")"
    [[ "$name" == "." || "$name" == ".." ]] && continue
    is_ignored "$name" && continue
    link_dir "$src" "$CONFIG/$name"
done

if (( ${#FILE_LINKS[@]} )); then
    echo
    echo "Individual files"
    echo
    for rel in "${!FILE_LINKS[@]}"; do
        link_file "$DOTFILES/$rel" "${FILE_LINKS[$rel]}"
    done
fi

echo
echo "Done. ${linked} linked, ${backed_up} backed up, ${skipped} unchanged."
(( DRY_RUN )) && echo "(dry run -- re-run without --dry-run to apply)"
echo
