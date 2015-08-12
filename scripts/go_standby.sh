#!/bin/sh

( slock && xset dpms 0 0 300 ) &
xset dpms 0 0 2
sleep 2
xset dpms force off

