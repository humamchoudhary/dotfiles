hl.env("GTK_THEME","Vanta-Black")

-- systemd's session PATH misses ~/.local/bin and ~/go/bin (hexowl, local
-- builds); extend it for every app spawned by Hyprland.
local home = os.getenv("HOME")
hl.env("PATH", home .. "/.local/bin:" .. home .. "/go/bin:" .. os.getenv("PATH"))


-- Wallpaper root, read by dotthemes/wallpaper-lib.sh and every script that
-- sources it (pickers, theme switcher, wallpaper-restore, organize script).
-- Shells Hyprland does not spawn (TTY, SSH) get the same value from
-- zsh/.zshenv -- change the path in both places if the wallpapers move.
hl.env("WALLPAPERS_DIR",  "/games/wallpapers")
