#!/usr/bin/env bash
# ------------------------------------------------------
# hdd-led.sh nvme0n1
# ------------------------------------------------------
# inspired by Dave Plummer BlinkenDisk - https://x.com/davepl1968/status/2059320143994589539

DEV="${1:-nvme0n1}"
STATE="/tmp/waybar-hddled-$DEV"

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
    echo '{"text":"⬤","class":"off"}'
    exit 1
fi

NOW=$(now_ms)

if [[ ! -f "$STATE" ]]; then
    echo "$CUR $NOW 0" > "$STATE"
    echo '{"text":"<span foreground=\"#001100\">⬤</span>","class":"idle"}'
    exit 0
fi

read -r PREV LAST_ACTIVE PHASE < "$STATE"

ACTIVE=0

if (( CUR != PREV )); then
    ACTIVE=1
    LAST_ACTIVE=$NOW
    PHASE=$(( (PHASE + 1) % 4 ))
fi

DELTA=$((NOW - LAST_ACTIVE))

if (( DELTA <= HOLD_MS )); then
    ACTIVE=1
fi

echo "$CUR $LAST_ACTIVE $PHASE" > "$STATE"

if (( ACTIVE )); then
    case "$PHASE" in
        0)
            COLOR="#00ff99"
            CLASS="blink1"
            ;;
        1)
            COLOR="#00ff44"
            CLASS="blink2"
            ;;
        2)
            COLOR="#55ff00"
            CLASS="blink3"
            ;;
        *)
            COLOR="#00cc66"
            CLASS="blink4"
            ;;
    esac

else
    COLOR="#001100"
    CLASS="idle"
fi

echo "{\"text\":\"<span foreground='$COLOR'>⬤</span>\",\"class\":\"$CLASS\"}"