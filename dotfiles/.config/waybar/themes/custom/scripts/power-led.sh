#!/usr/bin/env bash
# ------------------------------------------------------
# power-led.sh nvme0n1
# ------------------------------------------------------
# inspired by Dave Plummer BlinkenDisk - https://x.com/davepl1968/status/2059320143994589539

export LC_NUMERIC=C

DEV="${1:-nvme0n1}"
STATE="/dev/shm/waybar-power-led-$DEV"
HDD_STATE="/dev/shm/waybar-hddled-$DEV"

MODEL="$(cat "/sys/block/$DEV/device/model" 2>/dev/null | xargs)"
[[ -z "$MODEL" ]] && MODEL="$DEV"

if [[ ! -b "/dev/$DEV" ]]; then
    echo '{"text":"<span foreground=\"#1a0800\">⬤</span>","class":"off"}'
    exit 0
fi

# Read HDD LED energy + flicker state
ENERGY=0
FLICKER=0
if [[ -f "$HDD_STATE" ]]; then
    read -r _ ENERGY _ FLICKER < "$HDD_STATE"
    [[ -z "$ENERGY"  ]] && ENERGY=0
    [[ -z "$FLICKER" ]] && FLICKER=0
fi

# Load phase
if [[ -f "$STATE" ]]; then
    read -r PHASE < "$STATE"
else
    PHASE=$(( RANDOM % 10 ))
fi
# Very slow drift
PHASE=$(( (PHASE + RANDOM % 2 + 9) % 10 ))

echo "$PHASE" > "$STATE"
case "$PHASE" in
    0|1)   COLOR="#ff8888" ;;  # peak
    2|3)   COLOR="#dd2222" ;;  # normal bright
    4|5|6) COLOR="#aa0000" ;;  # steady nominal
    *)     COLOR="#660000" ;;  # slight dim at idle
esac
if (( ENERGY >= 9 )); then
    case "$COLOR" in
        "#ff8888") COLOR="#ffd0d0" ;;
        "#dd2222") COLOR="#ff6666" ;;
        "#aa0000") COLOR="#dd3333" ;;
        "#660000") COLOR="#aa2222" ;;
    esac
fi

echo "{\"text\":\"<span foreground='$COLOR'>⬤</span>\",\"class\":\"power\",\"tooltip\":\"$MODEL\"}"