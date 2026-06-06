#!/usr/bin/env bash

MONITOR="$1"

DISPLAY_ID=$(
    ddcutil detect --brief 2>/dev/null |
    awk -v mon="$MONITOR" '
        /^Display [0-9]+/ { id=$2 }
        $0 ~ mon { print id; exit }
    '
)

if [[ -z "$DISPLAY_ID" ]]; then
    printf '{"text":"󰃞 ?%%","tooltip":"Monitor not found: %s"}\n' "$MONITOR"
    exit 1
fi

BRIGHTNESS=$(
    ddcutil --display "$DISPLAY_ID" getvcp 10 2>/dev/null |
    sed -n 's/.*current value = *\([0-9]\+\).*/\1/p'
)

if (( BRIGHTNESS >= 100 )); then
    ICON="󰃠"   
elif (( BRIGHTNESS >= 75 )); then
    ICON="󰃝"   
elif (( BRIGHTNESS >= 50 )); then
    ICON="󰃟"   
elif (( BRIGHTNESS >= 25 )); then
    ICON="󰃞"   
else
    ICON="󰃜"   
fi

printf '{"text":"%s %d%%"}\n' "$ICON" "$BRIGHTNESS"