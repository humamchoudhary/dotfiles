#!/usr/bin/env bash

STATE=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .specialWorkspace.name')

if [[ "$STATE" == "true" ]]; then
    echo '{ "text":"\ue795","class":"active"}'
else
    echo '{ "text":"\ue795","class":"inactive"}'
fi
