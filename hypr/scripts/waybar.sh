#!/usr/bin/env bash
#
# Start waybar with logging.
#
# waybar (and anything its custom/ modules print on stderr) normally goes to
# wherever Hyprland's own stdout happened to be pointing, which is nowhere
# useful. This wrapper puts all of it in one file instead:
#
#     ~/.cache/waybar/waybar.log      current session
#     ~/.cache/waybar/waybar.log.1    previous session
#
# Tail it while debugging a module:  tail -f ~/.cache/waybar/waybar.log
# Raise the detail with:             WAYBAR_LOG_LEVEL=debug ~/.config/hypr/scripts/waybar.sh

LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
LOG_FILE="$LOG_DIR/waybar.log"
LOG_LEVEL="${WAYBAR_LOG_LEVEL:-info}"   # trace|debug|info|warning|error|critical|off

mkdir -p "$LOG_DIR"
[ -f "$LOG_FILE" ] && mv -f "$LOG_FILE" "$LOG_FILE.1"

echo "=== waybar started $(date '+%Y-%m-%d %H:%M:%S') (log-level=$LOG_LEVEL) ===" > "$LOG_FILE"

exec waybar -l "$LOG_LEVEL" >> "$LOG_FILE" 2>&1
