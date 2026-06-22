#!/usr/bin/env bash
# ------------------------------------------------------
# hdd-led.sh nvme0n1
# ------------------------------------------------------
# inspired by Dave Plummer BlinkenDisk - https://x.com/davepl1968/status/2059320143994589539

export LC_NUMERIC=C

DEV="${1:-nvme0n1}"
STATE="/dev/shm/waybar-hddled-$DEV"

MODEL="$(cat "/sys/block/$DEV/device/model" 2>/dev/null | xargs)"
[[ -z "$MODEL" ]] && MODEL="$DEV"

if [[ ! -b "/dev/$DEV" ]]; then
    echo '{"text":"<span foreground=\"#1a0800\">⬤</span>","class":"off"}'
    exit 0
fi

read_io() {
    read -r r _ _ _ w _ _ _ < "$STATE"
    echo $(( r + w ))
}

CUR=$(read_io 2>/dev/null) || {
    echo '{"text":"⬤","class":"idle"}'
    exit 1
}
NOW=${EPOCHREALTIME%%[.,]*}
# load state
if [[ -f "$STATE" ]]; then
    read -r PREV ENERGY LAST_TS FLICKER < "$STATE"
else
    PREV=$CUR
    ENERGY=0
    LAST_TS=$NOW
    FLICKER=0
fi

DT=$(( NOW - LAST_TS ))
(( DT < 0  )) && DT=0
(( DT > 5  )) && DT=5

DIFF=$(( CUR - PREV ))
if (( DIFF > 0 )); then
    # Hard snap on
    ENERGY=12

    # flicker at ~10-30Hz during sequential I/O
    FLICKER=$(( DIFF / 256 + 1 ))
    (( FLICKER > 8 )) && FLICKER=8
else
    # Hard decay — real LED drivers cut power fast
    # 2 ticks per second feels right; no romantic glow
    ENERGY=$(( ENERGY - DT * 4 ))
    FLICKER=$(( FLICKER - 1 ))
fi
(( FLICKER < 0 )) && FLICKER=0
(( ENERGY  > 12 )) && ENERGY=12
(( ENERGY  < 0  )) && ENERGY=0

echo "$CUR $ENERGY $NOW $FLICKER" > "$STATE"
if (( ENERGY >= 9 )); then
    if (( FLICKER > 0 && RANDOM % 3 == 0 )); then
        COLOR="#3a1800"
        CLASS="flicker-off"
    else
        COLOR="#99ff99"
        CLASS="active"
    fi
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