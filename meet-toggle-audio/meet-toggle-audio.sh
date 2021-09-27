#!/bin/bash
if ! which xdotool &>/dev/null; then
    notify-send "Did not find xdotool, cannot toggle Meet audio."
fi

xdotool keyup meta

window_active="$(xdotool getwindowfocus)"
sleep 0.05
xdotool search --classname crx_kjgfgldnnfoeklkmfkjfagphfepbbdan windowactivate --sync key --clearmodifiers ctrl+d
sleep 0.05
xdotool keyup ctrl meta alt
sleep 0.05
xdotool windowactivate --sync "${window_active}"
