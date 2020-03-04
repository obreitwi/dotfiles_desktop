#!/bin/bash

set -Eeuo pipefail

PATH_IMAGE="/tmp/wallpaper.png"
PATH_IMAGE_ROT="/tmp/wallpaper-rotated.png"
PATH_BG=${HOME}/wallpaper/brisbinxmonadwall.png

run_cmd() {
    nice -n 19 "$@"
}

SCALE=1.8
SCREEN_WIDTH=1920
SCREEN_HEIGHT=1200

generate_image() {
    # NOTE: --tree-anchor-proc-name/--tree-anchor-proc-angle seem to not work
    # sometimes (despite --tree-rotate not set)

    run_cmd pscircle \
        --output-width="$(echo "scale=0; ${SCREEN_WIDTH} * ${SCALE} / 1" | bc)" \
        --output-height="$(echo "scale=0; ${SCREEN_HEIGHT} * ${SCALE} / 1" | bc)" \
        --background-image-scale="$(echo "scale=5; 1. / ${SCALE}" | bc)" \
        --tree-anchor-proc-name=xinit \
        --tree-anchor-proc-angle=$(echo "0./360. * 2*3.14159265358" | bc -l) \
        --collapse-threads=1 \
        --root-pid=1 \
        --show-root=1 \
        --tree-radius-increment=175 \
        --tree-font-color=EEEEEE99 \
        --tree-font-size=20 \
        --tree-center=-600.0:0.0 \
        "--output=${PATH_IMAGE}" \
        "--background-image=${PATH_BG}"

    run_cmd convert "${PATH_IMAGE}" \
                    -resize ${SCREEN_WIDTH}x${SCREEN_HEIGHT}\
                    "${PATH_IMAGE}"
}

while true; do
    generate_image

    if xrandr | grep -q 1080x1920; then
        # the second screen is rotated
        run_cmd convert "${PATH_IMAGE}" -rotate 90 "${PATH_IMAGE_ROT}"
        run_cmd feh --bg-fill "${PATH_IMAGE}" ${PATH_IMAGE_ROT}
    else
        # just display the image everywhere
        run_cmd feh --bg-fill "${PATH_IMAGE}"
    fi

    # check if we are on AC power and adjust sleep duration
    if [ "$(cat /sys/class/power_supply/AC/online)" -eq 1 ];then 
        sleep 20
    else
        sleep 120
    fi
done
