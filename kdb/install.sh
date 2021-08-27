#!/bin/sh

SRCFLD=$(dirname $(readlink -m "$0"))
TGTFLD="/usr/local/share/kbd/keymaps/i386/qwerty"

sudo mkdir -p "$TGTFLD"
sudo cp -v "${SRCFLD}/us-acentos-vim-friendly.map" "${TGTFLD}"
sudo cp -v "${SRCFLD}/vconsole.conf" /etc
