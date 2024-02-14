#!/usr/bin/env bash

PID_FILE=/tmp/pid_html_to_markdown_link
LOCKFILE="${PID_FILE}"

DEBOUNCE_PERIOD_SEC=1

get_modtime() {
    stat -c %Y "${@}"
}

if [ ! -f "${LOCKFILE}" ] || (( ($(date +%s) - $(stat -c %Y "${LOCKFILE}")) > DEBOUNCE_PERIOD_SEC )); then
    logger -t "$(basename "$0")" "Converting HTML link to Markdown"
    touch "${LOCKFILE}"
    chmod 777 "${LOCKFILE}" 1>/dev/null 2>&1 || true
    kill -CONT "$(cat "${PID_FILE}")"
fi
