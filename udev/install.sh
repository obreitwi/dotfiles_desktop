#!/usr/bin/env bash

sudo -v

sourcedir="$(dirname "$(readlink -m "${BASH_SOURCE[0]}")")"

install -v -m 555 "${sourcedir}/daemon_restore_keyboard_settings_as_user.sh" "${HOME}/.local/bin/daemon_restore_keyboard_settings_as_user"

sudo install -v -m 444 "${sourcedir}/10-detect-daskeyboard.rules" /etc/udev/rules.d
sudo install -v -m 444 "${sourcedir}/20-connect-wifi.rules" /etc/udev/rules.d
sudo install -v -m 444 "${sourcedir}/99-logitech-default-zoom.rules" /etc/udev/rules.d
sudo install -v -m 555 "${sourcedir}/restore_keyboard_settings.sh" /usr/local/bin/restore_keyboard_settings
