#!/usr/bin/env bash

MONITOR="$1"
CACHE_FILE="/dev/shm/ddcutil_display_${MONITOR// /_}"
LOCK_FILE="/dev/shm/ddcutil_lock_${MONITOR// /_}"

# ---- avoid concurrent scans ----
exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

# ---- get cached display ID ----
if [[ -f "$CACHE_FILE" ]]; then
    DISPLAY_ID=$(<"$CACHE_FILE")
else
    DISPLAY_ID=$(
        ddcutil detect --brief 2>/dev/null |
        awk -v mon="$MONITOR" '
            /^Display [0-9]+/ { id=$2 }
            $0 ~ mon { print id; exit }
        '
    )

    # only cache valid IDs
    if [[ -n "$DISPLAY_ID" ]]; then
        echo "$DISPLAY_ID" > "$CACHE_FILE"
    fi
fi

# ---- fallback safety ----
if [[ -z "$DISPLAY_ID" ]]; then
    printf '{"text":"󰃞 ?%%","tooltip":"Monitor not found: %s"}\n' "$MONITOR"
    exit 1
fi

# ---- lightweight query with timeout protection ----
BRIGHTNESS=$(
    timeout 0.8 ddcutil --display "$DISPLAY_ID" getvcp 10 2>/dev/null |
    sed -n 's/.*current value = *\([0-9]\+\).*/\1/p'
)

BRIGHTNESS=${BRIGHTNESS:-100}

# ---- icon selection ----
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