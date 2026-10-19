hl.on("hyprland.start", function ()
  hl.exec_cmd("awww-daemon --format xrgb &")
  hl.exec_cmd("~/.config/hypr/scripts/wallpaper-restore.sh &")
  hl.exec_cmd("swaync")
  -- waybar runs as a systemd user unit (waybar.service) now. Started from
  -- here it raced xdg-desktop-portal: waybar asks the portal for the
  -- color-scheme at startup, the portal took ~26s to activate at boot, and
  -- waybar died on the 25s D-Bus timeout. The unit orders it after the
  -- portal. Logs: journalctl --user -u waybar -f
  -- scripts/waybar.sh is still there for manual/debug runs.
  hl.exec_cmd("cclipd -P 256")
  hl.exec_cmd("swayosd-server")
  hl.exec_cmd("~/.config/hypr/scripts/pip-snap.sh &")
end)

