#!/bin/sh

SRCFLD=$(dirname $(readlink -m "$0"))
TGTFLD="${HOME}/.config/alacritty"

mkdir -p "${TGTFLD}"

ln -s -f -v $SRCFLD/alacritty.yml  $TGTFLD
ln -s -f -v $SRCFLD/alacritty.toml  $TGTFLD
