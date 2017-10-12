#!/bin/zsh

# does not work reliably yet! --obreitwi, 04-10-17 20:49:19

setopt extended_glob
setopt glob_subst

watchpath="/sys/devices/pci0000:00/0000:00:02.0/drm/card0/card0-*/status"

while true; do
inotifywatch -e modify ${watchpath}
echo "Refreshing mintors.."
case "$(hostname)" in
abed)
if xrandr | grep -q "HDMI2 connected"; then
    # "setup @ home"
    xrandr --output eDP1 --auto --output HDMI2 --primary --auto --right-of eDP1
elif xrandr | grep -q "DP2-2 connected"; then
    # "setup @ office"
    xrandr --output eDP1 --auto --output DP2-1 --primary --auto --right-of eDP1 \
           --output DP2-2 --auto --right-of DP2-1
else
    # "setup @ mobile"
    xrandr --output eDP1 --primary --auto
fi

;;
esac
sleep 1
done

