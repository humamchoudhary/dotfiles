#!/usr/bin/env bash
# tui.sh — host TUI apps in a floating kitty window
#
# usage: tui.sh [-r] [-o <kitty-option>]... <class> <command> [args...]
#   default : toggle — open the TUI if not running, close it if it is
#   -r      : replace — kill any running instance, then open with new args
#   -o      : forward one `kitty -o` override (repeatable); used to give a
#             TUI a kitty-drawn keybind hint line via the tab bar
#
# The <class> is passed to `kitty --class` and matched by window rules in
# hypr/conf/rules.lua, which set the float size/position for each TUI.
#
# Examples:
#   tui.sh fsel fsel -d
#   tui.sh linktui linktui -tab bluetooth   # replace mode switches the tab
#   tui.sh powermenu ~/.config/hypr/scripts/powermenu.sh
#   tui.sh -o tab_bar_edge=bottom cclip fsel --cclip

mode=toggle
kitty_opts=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -r) mode=replace; shift ;;
        -o) kitty_opts+=(-o "$2"); shift 2 ;;
        *)  break ;;
    esac
done

class=$1
shift

pat="kitty --class $class"
if pgrep -f "$pat" >/dev/null 2>&1; then
    pkill -f "$pat" 2>/dev/null
    # toggle mode: this click only closes the window
    [[ "$mode" == "toggle" ]] && exit 0
    # replace mode: let the old window die before spawning the new one
    sleep 0.15
fi

exec kitty --class "$class" "${kitty_opts[@]}" "$@"
