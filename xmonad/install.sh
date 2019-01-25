#!/bin/sh

SRCFLD=$(dirname $(readlink -m "$0"))
TGTFLD="$HOME/.xmonad"

mkdir -v $TGTFLD

ln -sfv $SRCFLD/xmonad.hs $TGTFLD/
ln -sfv $SRCFLD/lib $TGTFLD/
ln -sfv $SRCFLD/build $TGTFLD/
ln -sfv $SRCFLD/stack.yaml $TGTFLD/
ln -sfv $SRCFLD/mrconfig $TGTFLD/.mrconfig

pydemx $SRCFLD/xmobar.pydemx


