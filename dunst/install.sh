#!/bin/bash

mkdir -p $HOME/.config/dunst
ln -sv "$(dirname "$(readlink -m $0)")/dunstrc" $HOME/.config/dunst
