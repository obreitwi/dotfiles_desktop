#!/bin/sh

SRCFLD=$(dirname $(readlink -m "$0"))
TGTFLD="${HOME}/.config/autorandr"

[ ! -d "${TGTFLD}" ] && mkdir -p "${TGTFLD}"

ln -s -f -v "${SRCFLD}/postswitch"  "${TGTFLD}"
