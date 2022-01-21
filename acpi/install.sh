#!/bin/sh

SRCFLD=$(dirname $(readlink -m "$0"))
TGTFLD="/etc/acpi"

sudo mkdir -p "${TGTFLD}"
sudo install -v -o root -g root -m 755 "${SRCFLD}/handler.sh" "${TGTFLD}"
