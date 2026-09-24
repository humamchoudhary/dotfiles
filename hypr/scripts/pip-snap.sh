#!/usr/bin/env bash
# Snap Picture-in-Picture windows to the nearest screen corner after dragging.
#
# Polls the PiP window's position; once it has been stationary for a short
# debounce window (i.e. the user released the drag), the window is clipped to
# whichever corner of the monitor's work area its centre is nearest.
#
# Initial placement (bottom-right) is handled by a `move` window rule in
# conf/rules.lua; this script only reacts to drags.
#
# Logging: appends to $PIP_SNAP_LOG (default ~/.cache/hypr/pip-snap.log).
# Set PIP_SNAP_DEBUG=1 for per-poll detail (helps diagnose a title mismatch).

set -u

TITLE="${PIP_SNAP_TITLE:-Picture-in-Picture}"
MARGIN=20
POLL=0.15
STABLE_THRESHOLD=2   # polls of stability before snapping (~300ms)
LOG="${PIP_SNAP_LOG:-$HOME/.cache/hypr/pip-snap.log}"
DEBUG="${PIP_SNAP_DEBUG:-0}"

mkdir -p "$(dirname "$LOG")"

log() {
    printf '%s %s\n' "$(date '+%H:%M:%S')" "$*" >> "$LOG"
}

# ── helpers ────────────────────────────────────────────────────────────────────

# Snap the given window address to the nearest corner of its monitor's work area.
snap_to_corner() {
    local addr="$1"

    local win
    win=$(hyprctl clients -j 2>/dev/null | jq -c --arg a "$addr" '.[] | select(.address == $a)')
    [ -n "$win" ] || return

    # Only act on the PiP window.
    [ "$(jq -r '.title' <<<"$win")" = "$TITLE" ] || return

    local wx wy ww wh
    wx=$(jq -r '.at[0]' <<<"$win")
    wy=$(jq -r '.at[1]' <<<"$win")
    ww=$(jq -r '.size[0]' <<<"$win")
    wh=$(jq -r '.size[1]' <<<"$win")

    # Window centre, used to pick the monitor and the nearest corner.
    local cx=$((wx + ww / 2))
    local cy=$((wy + wh / 2))

    local mon
    mon=$(hyprctl monitors -j 2>/dev/null | jq -c --argjson cx "$cx" --argjson cy "$cy" \
        '.[] | select($cx >= .x and $cx < .x + .width and $cy >= .y and $cy < .y + .height)')
    [ -n "$mon" ] || return

    local mx my mw mh
    mx=$(jq -r '.x' <<<"$mon")
    my=$(jq -r '.y' <<<"$mon")
    mw=$(jq -r '.width' <<<"$mon")
    mh=$(jq -r '.height' <<<"$mon")

    # Work area = monitor minus reserved (bars).
    local left=$((mx + $(jq -r '.reserved[0] // 0' <<<"$mon")))
    local top=$((my + $(jq -r '.reserved[1] // 0' <<<"$mon")))
    local right=$((mx + mw - $(jq -r '.reserved[2] // 0' <<<"$mon")))
    local bottom=$((my + mh - $(jq -r '.reserved[3] // 0' <<<"$mon")))

    # Nearest corner by squared distance from the window centre.
    local bestd=-1 d px py bx by
    for px in "$left" "$right"; do
        for py in "$top" "$bottom"; do
            d=$(( (cx - px) * (cx - px) + (cy - py) * (cy - py) ))
            if [ "$bestd" -lt 0 ] || [ "$d" -lt "$bestd" ]; then
                bestd=$d
                bx=$px
                by=$py
            fi
        done
    done

    # Target position: inset the window MARGIN from the chosen corner.
    local tx ty
    if [ "$bx" -eq "$left" ]; then tx=$((left + MARGIN)); else tx=$((right - ww - MARGIN)); fi
    if [ "$by" -eq "$top" ]; then ty=$((top + MARGIN)); else ty=$((bottom - wh - MARGIN)); fi

    # Skip if already there (prevents a snap → move → snap loop).
    if [ $(( (wx - tx) * (wx - tx) + (wy - ty) * (wy - ty) )) -le 4 ]; then
        return
    fi

    hyprctl dispatch "hl.dsp.window.move({ window = 'address:$addr', x = $tx, y = $ty, relative = false })" 2>/dev/null
    log "snapped $addr ($wx,$wy) -> ($tx,$ty)"
}

# ── main loop ─────────────────────────────────────────────────────────────────

log "started (title='$TITLE' margin=$MARGIN poll=${POLL}s threshold=$STABLE_THRESHOLD)"

last_pos=""     # position observed on the previous poll
snapped_pos=""  # position we last snapped to (avoids re-snapping at rest)
stable_count=0
had_pip=""

while true; do
    cur=$(hyprctl clients -j 2>/dev/null | jq -r --arg t "$TITLE" \
        '.[] | select(.title == $t) | "\(.address) \(.at[0]) \(.at[1])"' | head -1)

    if [ -z "$cur" ]; then
        if [ -n "$had_pip" ]; then
            log "pip gone"
            had_pip=""
        fi
        if [ "$DEBUG" = "1" ]; then
            floats=$(hyprctl clients -j 2>/dev/null | jq -r '.[] | select(.floating==true) | .title' | tr '\n' ' ')
            [ -n "$floats" ] && log "no match — floating titles: $floats"
        fi
        last_pos=""
        snapped_pos=""
        stable_count=0
        sleep "$POLL"
        continue
    fi

    if [ -z "$had_pip" ]; then
        log "pip detected: ${cur%% *} at (${cur#* })"
        had_pip=1
    fi

    if [ "$cur" != "$last_pos" ]; then
        # Still moving (drag in progress) — reset the debounce.
        last_pos="$cur"
        stable_count=0
    else
        stable_count=$((stable_count + 1))
        if [ "$stable_count" -ge "$STABLE_THRESHOLD" ] && [ "$cur" != "$snapped_pos" ]; then
            snap_to_corner "${cur%% *}"
            snapped_pos="$cur"
            stable_count=0
        fi
    fi

    sleep "$POLL"
done
