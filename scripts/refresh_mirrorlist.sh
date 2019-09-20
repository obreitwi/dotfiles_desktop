#!/usr/bin/env zsh

curl -s "https://www.archlinux.org/mirrorlist/?country=AT&country=DK&country=FR&country=DE&country=LU&country=PL&country=ES&country=SE&country=CH&country=GB&protocol=http&protocol=https&ip_version=4" | sed "s:^#Server:Server:" | rankmirrors -n 10 - | sudo tee /etc/pacman.d/mirrorlist
