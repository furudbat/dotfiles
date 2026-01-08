#!/usr/bin/env bash
exec 200>/tmp/bongocat-toggle.lock
flock -n 200 || exit 0

pkill -USR1 wpets
pkill -USR1 wpets-all
pkill -USR1 wpets-pkmn

# Explicitly release the lock (optional) -> flock releases on exit
flock -u 200
exec 200>&-