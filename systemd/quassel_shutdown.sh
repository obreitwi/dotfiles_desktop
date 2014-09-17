#!/bin/zsh

if [[ $(/usr/bin/pgrep quasselclient) ]]; then
	/usr/bin/kill $(pgrep quasselclient)
fi

