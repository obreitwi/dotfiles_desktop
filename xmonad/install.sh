#!/usr/bin/env bash

SRCFLD=$(dirname $(readlink -m "$0"))
TGTFLD="$HOME/.xmonad"

if [ ! -e "${TGTFLD}" ]; then
    ln -sfv "${SRCFLD}" ${TGTFLD}
fi

TGTFLD="${HOME}/.local/bin"
mkdir -p "${TGTFLD}"
find "${SRCFLD}/utils" -type f -executable -print0 | xargs -0 ln -sfvt "${TGTFLD}"

pydemx $SRCFLD/xmobar.pydemx
