#!/bin/sh

SRCFLD=$(dirname $(readlink -m "$0"))
TGTFLD="$HOME/.xmonad"

mkdir -v $TGTFLD

ln -s -f -v $SRCFLD/xmonad.hs $TGTFLD/
ln -s -f -v $SRCFLD/lib $TGTFLD/
ln -s -f -v $SRCFLD/build $TGTFLD/

pydemx $SRCFLD/xmobar.pydemx


