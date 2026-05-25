#!/bin/bash


pkill -SIGUSR2 waybar
hyprctl reload
hyprctl notify 1 5000 "rgb(4a90e2)" "Hyprland Config reloaded"
