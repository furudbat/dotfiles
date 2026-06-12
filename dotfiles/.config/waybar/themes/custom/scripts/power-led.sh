#!/usr/bin/env bash
# ------------------------------------------------------
# power-led.sh nvme0n1
# ------------------------------------------------------
# inspired by Dave Plummer BlinkenDisk - https://x.com/davepl1968/status/2059320143994589539

DEV="${1:-nvme0n1}"
#STATE="$XDG_RUNTIME_DIR/waybar-power-hddled-$DEV"
STATE="/dev/shm/waybar-power-led-$DEV"
#HDD_STATE="$XDG_RUNTIME_DIR/waybar-hddled-$DEV"
HDD_STATE="/dev/shm/waybar-hddled-$DEV"

MODEL="$(cat "/sys/block/$DEV/device/model" 2>/dev/null | xargs)"
[[ -z "$MODEL" ]] && MODEL="$DEV"

# device missing/offline
if [[ ! -b "/dev/$DEV" ]]; then
    echo '{"text":"<span foreground=\"#330000\">⬤</span>","class":"off"}'
    exit 0
fi

# ------------------------------------------------------
# read HDD LED energy (if available)
# format: CUR ENERGY LAST_TS
# ------------------------------------------------------
ENERGY=0
if [[ -f "$HDD_STATE" ]]; then
    read -r _ ENERGY _ < "$HDD_STATE"
    [[ -z "$ENERGY" ]] && ENERGY=0
fi

# ------------------------------------------------------
# load phase (persistent realism anchor)
# ------------------------------------------------------
if [[ -f "$STATE" ]]; then
    read -r PHASE < "$STATE"
else
    PHASE=$(( RANDOM % 10 ))
fi

# slow drift
PHASE=$(( (PHASE + RANDOM % 3 - 1 + 10) % 10 ))

# occasional electrical spike
if (( RANDOM % 25 == 0 )); then
    PHASE=$(( RANDOM % 10 ))
fi

echo "$PHASE" > "$STATE"

# ------------------------------------------------------
# base color mapping
# ------------------------------------------------------
case "$PHASE" in
    0|1) COLOR="#ff8888" ;;   # bright flash
    2|3) COLOR="#dd2222" ;;   # strong red
    4|5|6) COLOR="#aa0000" ;; # stable red
    *) COLOR="#660000" ;;     # dim glow
esac

# ------------------------------------------------------
# ENERGY-based brightness boost (from HDD LED)
# ------------------------------------------------------
if (( ENERGY >= 9 )); then
    case "$COLOR" in
        "#ff8888") COLOR="#ffd0d0" ;;
        "#dd2222") COLOR="#ff6666" ;;
        "#aa0000") COLOR="#dd3333" ;;
        "#660000") COLOR="#aa2222" ;;
    esac
elif (( ENERGY >= 5 )); then
    case "$COLOR" in
        "#ff8888") COLOR="#ffb3b3" ;;
        "#dd2222") COLOR="#ff4d4d" ;;
        "#aa0000") COLOR="#c62828" ;;
        "#660000") COLOR="#882222" ;;
    esac
fi

echo "{\"text\":\"<span foreground='$COLOR'>⬤</span>\",\"class\":\"power\",\"tooltip\":\"$MODEL\"}"