#!/bin/sh

SRCFLD=$(dirname $(readlink -m "$0"))
TGTFLD="${HOME}/.config/kitty"

mkdir -p "${TGTFLD}"

ln -s -f -v $SRCFLD/kitty.conf  $TGTFLD
