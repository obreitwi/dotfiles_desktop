#!/usr/bin/env bash

PID_FILE=/tmp/exec_xmodmap_pid

echo $$ > "${PID_FILE}"

update_xmodmap() {
    logger -i -t "$(basename "$0")" "Executing xmodmap update"
    sleep 1
    xmodmap "${HOME}/.Xmodmap"
}


trap update_xmodmap USR1

while true; do
    :
done
