#!/usr/bin/env bash
# ------------------------------------------------------
# hdd-led.sh nvme0n1
# ------------------------------------------------------
# inspired by Dave Plummer BlinkenDisk - https://x.com/davepl1968/status/2059320143994589539

DEV="${1:-nvme0n1}"
STATE="/tmp/waybar-hddled-$DEV"

POLL_US=8333
HOLD_MS=10

# ----------------------------------------

read_io() {
    awk '{print $3 + $7}' "/sys/block/$DEV/stat" 2>/dev/null
}

now_ms() {
    date +%s%3N
}

CUR=$(read_io)

if [[ -z "$CUR" ]]; then
    echo '{"text":"ERR","class":"error"}'
    exit 1
fi

NOW=$(now_ms)

# TODO: move colors into CSS and style by theme

if [[ ! -f "$STATE" ]]; then
    echo "$CUR $NOW" > "$STATE"

    echo '{"text":"<span foreground=\"#aa0000\">⬤</span> <span foreground=\"#002200\">⬤</span>","class":"idle"}'
    exit 0
fi

read -r PREV LAST_ACTIVE < "$STATE"

ACTIVE=0
if (( CUR != PREV )); then
    ACTIVE=1
    LAST_ACTIVE=$NOW
fi
# incandescent LED persistence
if (( NOW - LAST_ACTIVE <= HOLD_MS )); then
    ACTIVE=1
fi

echo "$CUR $LAST_ACTIVE" > "$STATE"

if (( ACTIVE )); then
    echo '{"text":"<span foreground=\"#aa0000\">⬤</span> <span foreground=\"#00ff66\">⬤</span>","class":"active"}'
else
    echo '{"text":"<span foreground=\"#aa0000\">⬤</span> <span foreground=\"#003300\">⬤</span>","class":"idle"}'
fi

sleep 0.$POLL_US