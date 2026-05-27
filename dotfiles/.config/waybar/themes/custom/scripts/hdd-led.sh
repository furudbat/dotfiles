#!/usr/bin/env bash
# ------------------------------------------------------
# hdd-led.sh nvme0n1
# ------------------------------------------------------
# inspired by Dave Plummer BlinkenDisk - https://x.com/davepl1968/status/2059320143994589539

DEV="${1:-nvme0n1}"
STATE="/tmp/waybar-hddled-$DEV"

MODEL="$(cat "/sys/block/$DEV/device/model" 2>/dev/null | xargs)"
[[ -z "$MODEL" ]] && MODEL="$DEV"

PULSE_MS=30

# ----------------------------------------

read_io() {
    awk '{print $3 + $7}' "/sys/block/$DEV/stat" 2>/dev/null
}

now_ms() {
    date +%s%3N
}

CUR=$(read_io)

if [[ -z "$CUR" ]]; then
    echo '{"text":"⬤","class":"idle"}'
    exit 1
fi

NOW=$(now_ms)

if [[ ! -f "$STATE" ]]; then
    echo "$CUR 0" > "$STATE"

    echo '{"text":"<span foreground=\"#003300\">⬤</span>","class":"idle"}'
    exit 0
fi

read -r PREV LAST_PULSE < "$STATE"

TRIGGER=0
if (( CUR != PREV )); then
    TRIGGER=1
    LAST_PULSE=$NOW
fi

echo "$CUR $LAST_PULSE" > "$STATE"

DELTA=$((NOW - LAST_PULSE))

# pulse decay stages
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

echo "{\"text\":\"<span foreground='$COLOR'>⬤</span>\",\"class\":\"$CLASS\",\"tooltip\":\"$MODEL\"}"