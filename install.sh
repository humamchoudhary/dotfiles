#!/bin/bash

DOTFILES="/home/testusr/dotfiles"
CONFIG="/home/testusr/.config"

link_file() {
    local src="$1"
    local dest="$2"

    # Make sure destination directory exists
    mkdir -p "$(dirname "$dest")"

    # If a real file already exists (not a symlink), back it up
    if [ -f "$dest" ] && [ ! -L "$dest" ]; then
        echo "  backing up $dest → $dest.bak"
        mv "$dest" "$dest.bak"
    fi

    # Remove old symlink if it points somewhere wrong
    [ -L "$dest" ] && rm "$dest"

    ln -sf "$src" "$dest"
    echo "  ✓ $dest"
}

echo ""
echo "Linking dotfiles..."
echo ""

# Walk every file inside dotfiles/ and mirror it into ~/.config/
find "$DOTFILES" \
    -not -path "*/.git/*" \
    -not -name ".gitignore" \
    -not -name "install.sh" \
    -not -name "README.md" \
    -type f | while read -r src; do

    # Strip the dotfiles/ prefix to get the relative path
    # e.g. /home/user/dotfiles/hypr/conf/keybinds.conf → hypr/conf/keybinds.conf
    rel="${src#$DOTFILES/}"

    dest="$CONFIG/$rel"
    link_file "$src" "$dest"
done

echo ""
echo "Done."
