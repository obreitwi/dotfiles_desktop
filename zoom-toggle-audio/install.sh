#!/bin/sh

SRCFLD=$(dirname "$(readlink -m "$0")")

PREFIX="${PREFIX:-$HOME/.local/bin}"

ln -s -f -v "${SRCFLD}/zoom-toggle-audio.sh" "${PREFIX}/zoom-toggle-audio"
