#!/usr/bin/env bash
# Web search / URL opener with history, via rofi.
#
# Typed text is classified: anything carrying a scheme or looking like a host is
# opened as-is, everything else goes to a search engine. A leading !bang picks a
# different engine ("!yt lofi"); a bang on its own re-prompts for the query.
# History is kept most-recent-first, Shift+Delete forgets the highlighted entry.

set -euo pipefail

HIST_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/rofi/websearch_history"
HIST_MAX=100
THEME="$HOME/.config/rofi/websearch.rasi"
OPENER=(xdg-open)

# key|name|url template (%s = url-encoded query). First entry is the default.
ENGINES=(
    "g|Google|https://www.google.com/search?q=%s"
    "ddg|DuckDuckGo|https://duckduckgo.com/?q=%s"
    "yt|YouTube|https://www.youtube.com/results?search_query=%s"
    "gh|GitHub|https://github.com/search?q=%s"
    "w|Wikipedia|https://en.wikipedia.org/w/index.php?search=%s"
    "aw|Arch Wiki|https://wiki.archlinux.org/index.php?search=%s"
    "ap|Arch Packages|https://archlinux.org/packages/?q=%s"
    "aur|AUR|https://aur.archlinux.org/packages?K=%s"
    "so|Stack Overflow|https://stackoverflow.com/search?q=%s"
    "map|Maps|https://www.google.com/maps/search/%s"
    "tr|Translate|https://translate.google.com/?op=translate&text=%s"
)

DEFAULT_KEY=${ENGINES[0]%%|*}

# ── helpers ────────────────────────────────────────────────────────────────────

# Print field $2 (2 = name, 3 = url) of the engine with key $1; fail if unknown.
engine_field() {
    local key=$1 field=$2 e k n u
    for e in "${ENGINES[@]}"; do
        IFS='|' read -r k n u <<< "$e"
        if [[ $k == "$key" ]]; then
            case $field in
                2) printf '%s' "$n" ;;
                3) printf '%s' "$u" ;;
            esac
            return 0
        fi
    done
    return 1
}

trim() {
    local s=$1
    s=${s#"${s%%[![:space:]]*}"}
    s=${s%"${s##*[![:space:]]}"}
    printf '%s' "$s"
}

# Byte-wise percent encoding; LC_ALL=C makes ${#s}/${s:i:1} operate on bytes so
# multibyte characters encode correctly.
urlencode() {
    local LC_ALL=C s=$1 out='' i c
    for (( i = 0; i < ${#s}; i++ )); do
        c=${s:i:1}
        case $c in
            [a-zA-Z0-9.~_-]) out+=$c ;;
            *) printf -v c '%%%02X' "'$c"; out+=$c ;;
        esac
    done
    printf '%s' "$out"
}

is_url() {
    local s=$1
    [[ $s == *[[:space:]]* ]] && return 1
    [[ $s =~ ^[a-zA-Z][a-zA-Z0-9+.-]*:// ]] && return 0
    [[ $s =~ ^(about|file|mailto|magnet|view-source): ]] && return 0
    [[ $s =~ ^(localhost|(\[[0-9a-fA-F:]+\])|(([0-9]{1,3}\.){3}[0-9]{1,3}))(:[0-9]+)?([/?#].*)?$ ]] && return 0
    [[ $s =~ ^[a-zA-Z0-9][a-zA-Z0-9._~-]*\.[a-zA-Z]{2,}(:[0-9]+)?([/?#].*)?$ ]] && return 0
    return 1
}

normalize_url() {
    local u=$1
    # Bare host:port must be checked first — "localhost:3000" otherwise reads as
    # a "localhost:" scheme and gets passed through without one.
    if [[ $u =~ ^(localhost|(([0-9]{1,3}\.){3}[0-9]{1,3}))(:[0-9]+)?([/?#].*)?$ ]]; then
        printf 'http://%s' "$u"
    elif [[ $u =~ ^[a-zA-Z][a-zA-Z0-9+.-]*: ]]; then
        printf '%s' "$u"
    else
        printf 'https://%s' "$u"
    fi
}

hist_add() {
    local entry=$1 tmp="$HIST_FILE.tmp"
    mkdir -p "${HIST_FILE%/*}"
    {
        printf '%s\n' "$entry"
        [[ -f $HIST_FILE ]] && grep -vxF -- "$entry" "$HIST_FILE"
    } 2>/dev/null | head -n "$HIST_MAX" > "$tmp" || true
    mv -f "$tmp" "$HIST_FILE"
}

hist_del() {
    local entry=$1 tmp="$HIST_FILE.tmp"
    [[ -f $HIST_FILE ]] || return 0
    grep -vxF -- "$entry" "$HIST_FILE" > "$tmp" || true
    mv -f "$tmp" "$HIST_FILE"
}

# History first (newest on top), then the bang list so typing "!" reveals it.
menu() {
    local line e k n u
    if [[ -f $HIST_FILE ]]; then
        while IFS= read -r line; do
            [[ -n $line ]] || continue
            if is_url "$line"; then
                printf '%s\0icon\x1fapplications-internet\n' "$line"
            else
                printf '%s\0icon\x1fsystem-search\n' "$line"
            fi
        done < "$HIST_FILE"
    fi
    for e in "${ENGINES[@]}"; do
        IFS='|' read -r k n u <<< "$e"
        printf '!%s   %s\0icon\x1fsystem-search\n' "$k" "$n"
    done
}

# ── pick an entry ──────────────────────────────────────────────────────────────

while :; do
    choice=$(menu | rofi -dmenu -i \
        -p "󰖟 " \
        -show-icons \
        -icon-theme "Papirus-Dark" \
        -theme "$THEME" \
        -mesg "Enter open · Ctrl+Enter use typed text · Shift+Delete forget" \
        -kb-delete-entry "" \
        -kb-custom-1 "Shift+Delete") && rc=0 || rc=$?

    case $rc in
        0)  break ;;
        10) [[ -n ${choice:-} ]] && hist_del "$choice"; continue ;;
        *)  exit 0 ;;
    esac
done

input=$(trim "$choice")
[[ -n $input ]] || exit 0

# ── resolve engine / query ─────────────────────────────────────────────────────

engine=''
query=$input

if [[ $input == '!'* ]]; then
    tok=${input%%[[:space:]]*}
    key=${tok#!}
    if engine_field "$key" 2 >/dev/null; then
        engine=$key
        rest=${input#"$tok"}
        rest=$(trim "$rest")
        # A bang row picked straight from the list ("!yt   YouTube") carries the
        # engine name as its remainder — treat that as "no query yet".
        [[ $rest == "$(engine_field "$key" 2)" ]] && rest=''
        query=$rest
    fi
fi

if [[ -n $engine && -z $query ]]; then
    name=$(engine_field "$engine" 2)
    query=$(rofi -dmenu -i \
        -p "$name " \
        -theme "$THEME" \
        -mesg "Search $name" < /dev/null) || exit 0
    query=$(trim "$query")
    [[ -n $query ]] || exit 0
    input="!$engine $query"
fi

if [[ -z $engine ]] && is_url "$query"; then
    url=$(normalize_url "$query")
else
    tpl=$(engine_field "${engine:-$DEFAULT_KEY}" 3)
    url=${tpl//%s/$(urlencode "$query")}
fi

hist_add "$input"
setsid -f "${OPENER[@]}" "$url" >/dev/null 2>&1
