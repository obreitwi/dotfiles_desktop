#!/bin/sh

SRCFLD=$(dirname "$(readlink -m "$0")")
TGTFLD="${HOME}/.config/redshift"

[ ! -d "${TGTFLD}" ] && mkdir -vp "${TGTFLD}"

ln -s -f -v "${SRCFLD}/redshift.conf" "${TGTFLD}"
