#!/bin/bash
# Volume control via pipewire/pulse

case "$1" in
    up)
        wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+
        ;;
    down)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        ;;
    mute)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
    *)
        echo "Usage: volume.sh [up|down|mute]"
        exit 1
        ;;
esac

# Get current volume for notification
VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2}')
MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED && echo "muted" || echo "")

notify-send -t 800 "Volume" "${MUTED:-$VOL}"