#!/bin/bash

# install with local stack
# stack --stack-root $HOME/.xmonad/.stack install --local-bin-path $HOME/.xmonad/bin

# install with user stack
stack install --local-bin-path "${HOME}/.xmonad/bin"
