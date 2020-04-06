#!/bin/bash

ln -svf "$(dirname "$(readlink -m "$0")")/sink_select.sh" "${HOME}/.local/bin/pa-sink"
