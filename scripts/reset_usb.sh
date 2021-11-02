#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

usage() {
    echo "Usage: $0 (<vendor>:<product> | <vendor> <product>)" >&2
}

if (( $# < 2 )); then
    vendorproduct="$1"
    shift

    if ! echo "${vendorproduct}" | grep -q ":"; then
        usage
        exit 2
    fi

    vendor="$(echo "${vendorproduct}" | cut -d: -f 1)"
    product="$(echo "${vendorproduct}" | cut -d: -f 2)"
else
    vendor="$1"
    shift
    product="$1"
    shift
fi


for dir in $(find /sys/bus/usb/devices/ -maxdepth 1 -type l); do
  if [[ -f "$dir/idVendor" &&
        -f "$dir/idProduct" &&
        "$(cat "$dir/idVendor")" == $vendor &&
        "$(cat "$dir/idProduct")" == $product ]]; then
    echo 0 > "$dir/authorized"
    sleep 0.5
    echo 1 > "$dir/authorized"
  fi
done
