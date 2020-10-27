#!/bin/sh

SRCFLD=$(dirname "$(readlink -m "$0")")
TGTFLD="${HOME}/.config/zathura"

[ ! -d "${TGTFLD}" ] && mkdir -vp "${TGTFLD}"

ln -s -f -v "${SRCFLD}/zathurarc" "${TGTFLD}"
