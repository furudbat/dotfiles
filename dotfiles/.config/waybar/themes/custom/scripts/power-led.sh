#!/usr/bin/env bash
# ------------------------------------------------------
# power-led.sh nvme0n1
# ------------------------------------------------------
# inspired by Dave Plummer BlinkenDisk - https://x.com/davepl1968/status/2059320143994589539

DEV="${1:-nvme0n1}"

MODEL="$(cat "/sys/block/$DEV/device/model" 2>/dev/null | xargs)"
[[ -z "$MODEL" ]] && MODEL="$DEV"

# device missing/offline
if [[ ! -b "/dev/$DEV" ]]; then
    echo '{"text":"<span foreground=\"#330000\">⬤</span>","class":"off"}'
    exit 0
fi

#PHASE=$(( ( $(date +%s%N) / 500000000 ) % 10 ))
PHASE=$(( RANDOM % 500 ))

BASE="#cc0000"
case "$PHASE" in
    0|7)
        COLOR="#ff6666"
        ;;
    1|8)
        COLOR="#dd2222"
        ;;
    2|9)
        COLOR="#cc0000"
        ;;
    *)
        COLOR="$BASE"
        ;;
esac

echo "{\"text\":\"<span foreground='$COLOR'>⬤</span>\",\"class\":\"power\",\"tooltip\":\"$MODEL\"}"