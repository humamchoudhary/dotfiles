# Sourced by every zsh (interactive or not), after ~/.zshenv sets ZDOTDIR.
# Keep this minimal — it runs for scripts too.

# Wallpaper root, for shells Hyprland did not spawn (TTY, SSH, systemd units).
# Hyprland exports the same value from hypr/conf/env.lua; `:=` defers to that
# one when it is already set, so the two can never disagree at runtime.
# Moving the wallpapers means changing the path in BOTH files.
: "${WALLPAPERS_DIR:=$HOME/wallpapers}"
export WALLPAPERS_DIR
