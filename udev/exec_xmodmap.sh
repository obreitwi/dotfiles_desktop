#!/usr/bin/env bash

PID_FILE=/tmp/exec_xmodmap_pid
LOCKFILE="${PID_FILE}"

get_modtime() {
    stat -c %Y "${@}"
}

if [ ! -f "${LOCKFILE}" ] || (( ($(date +%s) - $(stat -c %Y "${LOCKFILE}")) > 5 )); then
    logger -t "$(basename "$0")" "Triggering xmodmap update."
    touch "${LOCKFILE}"
    kill -USR1 "$(cat "${PID_FILE}")"
fi
