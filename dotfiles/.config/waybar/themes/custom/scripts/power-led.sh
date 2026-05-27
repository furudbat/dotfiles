#!/usr/bin/env bash
# ------------------------------------------------------
# power-led.sh nvme0n1
# ------------------------------------------------------
# inspired by Dave Plummer BlinkenDisk - https://x.com/davepl1968/status/2059320143994589539

DEV="${1:-nvme0n1}"


PHASE=$(( ($(date +%s%N) / 50000000) % 2 ))

if (( PHASE == 0 )); then
    RED="#ff2222"
else
    RED="#aa0000"
fi

echo "{\"text\":\"<span foreground='$RED'>⬤</span>\",\"class\":\"hdd-power\"}"