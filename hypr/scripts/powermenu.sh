#!/bin/bash

entries="󰌾  lock\n󰍃  logout\n󰑓  reboot\n󰐥  shutdown"

chosen=$(printf "%b" "$entries" | rofi -dmenu -p "" \
    -no-fixed-num-lines \
    -theme "$HOME/.config/rofi/powermenu.rasi")

case "$chosen" in
    "󰌾  lock")     ~/.local/share/quickshell-lockscreen/lock.sh ;;
    "󰍃  logout")   hyprctl dispatch 'hl.dsp.exit()';;
    "󰑓  reboot")   systemctl reboot ;;
    "󰐥  shutdown") systemctl poweroff ;;
esac
