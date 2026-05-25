#!/bin/bash

truncate() {
  local str="$1"
  local max="$2"

  if [ ${#str} -gt $max ]; then
    echo "${str:0:$((max-1))}…"
  else
    echo "$str"
  fi
}

escape() {
  sed -e 's/&/\&amp;/g' \
      -e 's/</\&lt;/g' \
      -e 's/>/\&gt;/g'
}

player=$(playerctl --list-all 2>/dev/null | head -n 1)

if [ -z "$player" ]; then
  echo '{"text":" No Media"}'
  exit
fi

title=$(playerctl -p "$player" metadata xesam:title 2>/dev/null)
artist=$(playerctl -p "$player" metadata xesam:artist 2>/dev/null)

case "$player" in
  *firefox*) icon="" ;;
  *spotify*) icon="" ;;
  *mpv*) icon="" ;;
  *) icon="" ;;
esac

# 1. build raw string first
text="$icon $title - $artist"

# 2. truncate raw string
text=$(truncate "$text" 20)

# 3. escape LAST (critical fix)
text=$(echo "$text" | escape)

echo "{\"text\":\"$text\"}"
