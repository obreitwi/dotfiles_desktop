#!/bin/sh

SRCFLD=$(dirname $(readlink -m "$0"))
TGTFLD="$HOME/.xmonad"

ln -sfv "${SRCFLD}" ${TGTFLD}

pydemx $SRCFLD/xmobar.pydemx


