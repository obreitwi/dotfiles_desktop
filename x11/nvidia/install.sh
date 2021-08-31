#!/bin/sh

SRCFLD=$(dirname $(readlink -m "$0"))
TGTFLD="/usr/local/sbin"

sudo -v

sudo install -v -d "${TGTFLD}"
sudo install -v -o root -g root -m 755 "${SRCFLD}/nvidia-enable-gpu" "${SRCFLD}/nvidia-disable-gpu" "${TGTFLD}"
