#!/bin/sh
# Adapted from: http://pzel.name/til/2019/11/25/Muting-and-unmuting-Zoom-from-anywhere-on-the-linux-desktop.html

if ! which xdotool &>/dev/null; then
    notify-send "Did not find xdotool, cannot toggle ZOOM audio."
fi

window_active="$(xdotool getwindowfocus)"
window_zoom="$(xdotool search --limit 1 --name "Zoom Meeting")"
xdotool windowactivate --sync "${window_zoom}"
xdotool key --clearmodifiers "alt+a"
xdotool windowactivate --sync "${window_active}"
