#!/usr/bin/env bash

sourcedir="$(dirname "$(readlink -m "${BASH_SOURCE[0]}")")"

install -v -m 555 "${sourcedir}/user_exec_xmodmap.sh" "${HOME}/.local/bin"

sudo install -v -m 444 "${sourcedir}/10-detect-daskeyboard.rules" /etc/udev/rules.d
sudo install -v -m 555 ${sourcedir}/exec_xmodmap.sh /usr/local/bin
