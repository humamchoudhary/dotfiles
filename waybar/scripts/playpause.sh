#!/bin/bash

player=$(playerctl --list-all 2>/dev/null | head -n 1)

status=$(playerctl -p "$player" status 2>/dev/null)

if [ "$status" = "Playing" ]; then
  icon=""   # pause icon
else
  icon=""   # play icon
fi

echo "{\"text\":\"$icon\"}"
