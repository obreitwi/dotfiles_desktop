#!/usr/bin/env bash

PID_FILE=/tmp/update_keyboard_settings_pid

echo $$ > "${PID_FILE}"

ensure_exists() {
    if ! which "$1" >/dev/null; then
        echo "ERROR: $1 missing!" >&2
    fi
}

ensure_exists setxkbmap
ensure_exists xdotool
ensure_exists xmodmap
ensure_exists xset
ensure_exists logger

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
      -option compose:prsc \
      -option lv3:ralt_switch \
      -option eurosign:e \
      -option nbsp:level3n
}

# trap update_xmodmap USR1

while true; do
    kill -STOP $$
    sleep 0.1
    update_xkbmap
    sleep 0.1
    update_xmodmap
    sleep 0.1
    if xset -q | grep -q "Caps Lock:   on"; then
        xdotool key Caps_Lock
    fi
done

