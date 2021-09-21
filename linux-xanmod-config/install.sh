#!/bin/sh

SRCFLD="$(dirname $(readlink -m "$0"))"
TGTFLD="${HOME}/.config/linux-xanmod"

mkdir -p "${TGTFLD}"

ln -s -f -v "$SRCFLD/myconfig" "$TGTFLD"
