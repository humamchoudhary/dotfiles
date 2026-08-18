#!/bin/bash
# Night mode toggle via wl-gammactl-rust.
# The tool holds the wlroots gamma-control lock for as long as it runs,
# so gamma snaps back to normal the moment it is killed.

BIN="wl-gammactl-rust"
CONTRAST="0.6"
GAMMA="0.6"

# comm is truncated at 15 chars, so match on the full command line
is_on() { pgrep -f "$BIN" >/dev/null; }

case "${1:-toggle}" in
    toggle)
        is_on && ACTION=off || ACTION=on
        ;;
    on|off)
        ACTION="$1"
        ;;
    status)
        is_on && echo "on" || echo "off"
        exit 0
        ;;
    *)
        echo "Usage: nightmode.sh [toggle|on|off|status]"
        exit 1
        ;;
esac

# always clear the old instance: releases the lock when going off,
# and stops a stale one from holding it when going on
pkill -f "$BIN"

if [ "$ACTION" = "on" ]; then
    setsid -f "$BIN" -c "$CONTRAST" -g "$GAMMA" >/dev/null 2>&1
fi

notify-send -t 800 "Night mode" "$ACTION"
