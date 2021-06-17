#!/usr/bin/env sh

# On Linux, firefox prevents certain keys like <c-n> or <c-w> to be overwritten
# by firenvim, which is quite annoying.
# This script needs to be executed after every firefox update.
#
# Adapted from: https://github.com/glacambre/firefox-patches/issues/1
sudo perl -i -pne 's/reserved="true"/               /g' /usr/lib/firefox/browser/omni.ja \
    && find "$HOME/.cache/mozilla/firefox" -print0 -type d -name startupCache | xargs -0 rm -rf
