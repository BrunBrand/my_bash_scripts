#!/bin/sh

# Get monitor name by using 'xrandr' command
MONITOR=$1


OUTPUT=xinput

ID_STYLUS=$($OUTPUT | grep "Pen stylus" | cut -f 2 | cut -c 4-5)

xinput map-to-output $ID_STYLUS $MONITOR

exit 0
