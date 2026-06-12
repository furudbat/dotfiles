#!/usr/bin/env bash
# ------------------------------------------------------
# hdd-led.sh nvme0n1
# ------------------------------------------------------
# inspired by Dave Plummer BlinkenDisk - https://x.com/davepl1968/status/2059320143994589539

DEV="${1:-nvme0n1}"
#STATE="$XDG_RUNTIME_DIR/waybar-hddled-$DEV"
STATE="/dev/shm/waybar-hddled-$DEV"
STAT="/sys/block/$DEV/stat"


read_io() {
    read -r r _ _ _ w _ _ _ < "$STAT"
    echo $((r + w))
}

CUR=$(read_io 2>/dev/null) || {
    echo '{"text":"⬤","class":"idle"}'
    exit 1
}

NOW=${EPOCHREALTIME%.*}

# load state
if [[ -f "$STATE" ]]; then
    read -r PREV ENERGY LAST_TS < "$STATE"
else
    PREV=$CUR
    ENERGY=0
    LAST_TS=$NOW
fi

# time delta (protect against weird jumps)
DT=$(( NOW - LAST_TS ))
(( DT < 0 )) && DT=0
(( DT > 5 )) && DT=5   # clamp long sleeps

# detect IO
DIFF=$((CUR - PREV))

# charge on activity (burst)
if (( DIFF > 0 )); then
    ENERGY=$(( ENERGY + 6 + DIFF / 2048 ))
fi

# time-based decay (key realism upgrade)
if (( ENERGY > 0 )); then
    ENERGY=$(( ENERGY - DT * 2 ))
fi

# micro jitter (what makes it feel "hardware real")
(( RANDOM % 6 == 0 )) && (( ENERGY++ ))
(( RANDOM % 8 == 0 )) && (( ENERGY-- ))

# clamp
(( ENERGY > 12 )) && ENERGY=12
(( ENERGY < 0 )) && ENERGY=0

echo "$CUR $ENERGY $NOW" > "$STATE"

# visual mapping (keep it crude, like real LEDs)
if (( ENERGY >= 9 )); then
    COLOR="#99ff99"
    CLASS="active"
elif (( ENERGY >= 5 )); then
    COLOR="#55dd55"
    CLASS="blink"
elif (( ENERGY >= 1 )); then
    COLOR="#227722"
    CLASS="idle-fade"
else
    COLOR="#003300"
    CLASS="idle"
fi

echo "{\"text\":\"<span foreground='$COLOR'>⬤</span>\",\"class\":\"$CLASS\"}"