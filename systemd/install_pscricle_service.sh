#!/usr/bin/env bash

set -Eeuo pipefail

sourcedir="$(dirname "$(readlink -m "${BASH_SOURCE[0]}")")"

PATH_TARGET="${HOME}/.config/systemd/user"

ln -svf "${sourcedir}/pscircle.service" "${PATH_TARGET}"
ln -svf "${sourcedir}/run_pscircle.sh"  "${PATH_TARGET}"
