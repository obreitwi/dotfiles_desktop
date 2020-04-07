#!/usr/bin/env bash

PID_FILE=/tmp/update_keyboard_settings_pid

echo $$ > "${PID_FILE}"

update_xmodmap() {
    logger -i -t "$(basename "$0")" "Executing xmodmap update"
    xmodmap "${HOME}/.Xmodmap"
}

update_xkbmap() {
    logger -i -t "$(basename "$0")" "Setting xkbmap"
    setxkbmap us\
      -variant altgr-intl \
      -model pc105\
      -option compose:menu \
      -option lv3:ralt_switch \
      -option eurosign:e \
      -option nbsp:level3n
}

# trap update_xmodmap USR1

while true; do
    kill -STOP $$
    sleep 1
    update_xkbmap
    update_xmodmap
done

