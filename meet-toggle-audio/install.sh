#!/bin/sh

SRCFLD=$(dirname "$(readlink -m "$0")")

PREFIX="${PREFIX:-$HOME/.local/bin}"

ln -s -f -v "${SRCFLD}/meet-toggle-audio.sh" "${PREFIX}/meet-toggle-audio"
