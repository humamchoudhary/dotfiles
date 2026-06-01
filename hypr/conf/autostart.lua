-- # ── Wallpaper ─────────────────────────────────────────────────────────────────
-- exec-once = awww-daemon
hl.on("hyprland.start", function ()
  hl.exec_cmd("awww-daemon --format xrgb &")
  hl.exec_cmd("~/.config/hypr/scripts/wallpaper-restore.sh &")
  hl.exec_cmd("swaync")
  hl.exec_cmd("nm-applet")
  hl.exec_cmd("waybar")
  hl.exec_cmd("wl-paste --type text --watch cliphist store &")
  hl.exec_cmd("wl-paste --type image --watch cliphist store &")
  hl.exec_cmd("ags run ~/.config/waybar/widgets/init.tsx")
end)
--
-- # ── Bar ───────────────────────────────────────────────────────────────────────
-- exec-once = waybar
--
-- # ── Notifications ─────────────────────────────────────────────────────────────
-- exec-once = dunst
--
-- # ── Idle & Lock ───────────────────────────────────────────────────────────────
-- exec-once = hypridle
--
-- # ── Clipboard ─────────────────────────────────────────────────────────────────
-- exec-once = wl-paste --type text --watch cliphist store
-- exec-once = wl-paste --type image --watch cliphist store
--
-- # ── Auth agent ────────────────────────────────────────────────────────────────
-- exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
--
-- # ── Network & Bluetooth tray ──────────────────────────────────────────────────
-- exec-once = nm-applet --indicator
-- exec-once = blueman-applet
--
-- # ── XDG portals ───────────────────────────────────────────────────────────────
-- exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
-- exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
--
-- # ── Wallpaper (initial set) ───────────────────────────────────────────────────
-- exec-once = ~/.config/hypr/scripts/wallpaper.sh
