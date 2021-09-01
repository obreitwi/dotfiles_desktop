#!/bin/sh

SRCFLD=$(dirname $(readlink -m "$0"))
TGTFLD="${HOME}/.local/bin"

mkdir -p "${TGTFLD}"

# disabled since not used right now
# ln -s -f -v "$SRCFLD/brightness_down.sh"  "$TGTFLD"
# ln -s -f -v "$SRCFLD/brightness_up.sh"  "$TGTFLD"
