#!/usr/bin/env bash

set -eu

original="$HOME/.xmonad/xmobar"
for sid in $(seq 0 2); do
    target="${original}_${sid}"
    cp -v "${original}" "${target}"
    sed -i "s:_XMONAD_LOG:_XMONAD_LOG_$sid:g" "${target}"
done
