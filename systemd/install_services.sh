#!/usr/bin/env bash

set -Eeuo pipefail

sourcedir="$(dirname "$(readlink -m "${BASH_SOURCE[0]}")")"

PATH_TARGET="${HOME}/.config/systemd/user"

ln -svf "${sourcedir}/dunst.service" "${PATH_TARGET}"
ln -svf "${sourcedir}/redshift.service" "${PATH_TARGET}"
ln -svf "${sourcedir}/xsession.target" "${PATH_TARGET}"

systemctl daemon-reload --user

systemctl enable --user dunst.service
systemctl enable --user redshift.service
