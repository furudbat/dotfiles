#!/usr/bin/env bash
exec 200>/tmp/bongocat-reload.lock
flock -n 200 || exit 0

pkill -USR2 wpets
pkill -USR2 wpets-all
pkill -USR2 wpets-pkmn

# Explicitly release the lock (optional) -> flock releases on exit
flock -u 200
exec 200>&-