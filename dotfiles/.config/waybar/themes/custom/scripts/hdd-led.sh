#!/usr/bin/env bash

DEV="${1:-nvme0n1}"
STATE="/tmp/waybar-hddled-$DEV"

read_io() {
    read -r _ _ r _ _ _ w _ < "/sys/block/$DEV/stat"
    echo $((r + w))
}

CUR=$(read_io 2>/dev/null)

if [[ -z "$CUR" ]]; then
    echo '{"text":"⬤","class":"idle"}'
    exit 1
fi

# epoch milliseconds without spawning `date`
NOW=${EPOCHREALTIME/.}
NOW=${NOW:0:13}

if [[ ! -f "$STATE" ]]; then
    echo "$CUR 0" > "$STATE"
    echo '{"text":"<span foreground=\"#003300\">⬤</span>","class":"idle"}'
    exit 0
fi

read -r PREV LAST_PULSE < "$STATE"

if (( CUR != PREV )); then
    LAST_PULSE=$NOW
fi

echo "$CUR $LAST_PULSE" > "$STATE"

DELTA=$((NOW - LAST_PULSE))

if (( DELTA < 6 )); then
    COLOR="#66ff66"
    CLASS="flash3"
elif (( DELTA < 14 )); then
    COLOR="#33dd33"
    CLASS="flash2"
elif (( DELTA < 40 )); then
    COLOR="#007700"
    CLASS="flash1"
else
    COLOR="#001100"
    CLASS="idle"
fi

echo "{\"text\":\"<span foreground='$COLOR'>⬤</span>\",\"class\":\"$CLASS\"}"