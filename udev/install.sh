#!/usr/bin/env bash

sudo -v

sourcedir="$(dirname "$(readlink -m "${BASH_SOURCE[0]}")")"

install -v -m 555 "${sourcedir}/restore_keyboard_settings_user.sh" "${HOME}/.local/bin"

sudo install -v -m 444 "${sourcedir}/10-detect-daskeyboard.rules" /etc/udev/rules.d
sudo install -v -m 444 "${sourcedir}/99-logitech-default-zoom.rules" /etc/udev/rules.d
sudo install -v -m 555 ${sourcedir}/restore_keyboard_settings.sh /usr/local/bin
