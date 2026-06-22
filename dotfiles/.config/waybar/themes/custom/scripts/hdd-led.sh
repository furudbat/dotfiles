#!/usr/bin/env bash
# ------------------------------------------------------
# hdd-led.sh nvme0n1
# ------------------------------------------------------
# inspired by Dave Plummer BlinkenDisk - https://x.com/davepl1968/status/2059320143994589539

DEV="${1:-nvme0n1}"
if [[ -d /dev/shm ]]; then
    STATE="/dev/shm/waybar-hddled-$DEV"
else
    STATE="${XDG_RUNTIME_DIR:-/tmp}/waybar-hddled-$DEV"
fi

read_io() {
    # read sectors read + written
    read -r _ _ r _ _ _ w _ < "/sys/block/$DEV/stat"
    echo $((r + w))
}

CUR=$(read_io 2>/dev/null)
if [[ -z "$CUR" ]]; then
    echo '{"text":"⬤","class":"idle"}'
    exit 1
fi

# robust timestamp in milliseconds (no locale issues)
NOW=$(date +%s%3N)

# init state file
if [[ ! -f "$STATE" ]]; then
    echo "$CUR $NOW" > "$STATE"
    echo '{"text":"<span foreground=\"#003300\">⬤</span>","class":"idle"}'
    exit 0
fi

read -r PREV LAST_PULSE < "$STATE"

# update pulse if IO changed
if (( CUR != PREV )); then
    LAST_PULSE=$NOW
fi

echo "$CUR $LAST_PULSE" > "$STATE"

DELTA=$((NOW - LAST_PULSE))

# color / class logic
if (( DELTA < 600 )); then
    COLOR="#66ff66"
    CLASS="flash3"
elif (( DELTA < 2000 )); then
    COLOR="#33dd33"
    CLASS="flash2"
elif (( DELTA < 5000 )); then
    COLOR="#007700"
    CLASS="flash1"
else
    COLOR="#003300"
    CLASS="idle"
fi

echo "{\"text\":\"<span foreground='$COLOR'>⬤</span>\",\"class\":\"$CLASS\"}"