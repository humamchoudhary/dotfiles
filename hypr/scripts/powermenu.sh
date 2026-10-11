#!/bin/bash
# Power menu — fsel --dmenu inside a floating kitty window.
# Launch via: tui.sh powermenu <this script>
# (fsel is a TUI, so the whole menu runs in the kitty host; the selection is
# captured from fsel's stdout here.)

chosen=$(printf "%b" "󰌾  lock\n󰍃  logout\n󰑓  reboot\n󰐥  shutdown" | fsel --dmenu \
    --panel "keys:bottom:16:$HOME/.config/fsel/keyhints.sh power")

case "$chosen" in
    *"lock"*)     ~/.local/share/quickshell-lockscreen/lock.sh ;;
    *"logout"*)   hyprctl dispatch 'hl.dsp.exit()' ;;
    *"reboot"*)   systemctl reboot ;;
    *"shutdown"*) systemctl poweroff ;;
esac
