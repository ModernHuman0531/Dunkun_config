#!/usr/bin/env sh

# A script to control volume using pamixer.
# 
# Usage: 
#   volume_controller.sh <commmand> [value]
#
# Commands:
# up        - Increase volume by 'step'
# down      - Decrease volume by 'step'
# mute      - Toggle mute
# get       - Get current volume percentage
# set       - Set volumen to a specific percentage [value]

set -e # Exit immediately if a command exits with a non-zero status (non-zero return means the command went wrong)

# Declare the variable
COMMAND="$1" # First input parameter
VALUE="$2"   # Second input parameter
STEP=5

case $COMMAND in
    up)
        pamixer -i "${VALUE:-STEP}"
        ;;
    down)
       pamixer -d "${VALUE:-STEP}"
       ;;
    mute)
       pamixer -t
       ;;
    unmute)
       pamixer -u --unmute
       ;;
    get)
       pamixer --get-volume
       ;;
    set)
       if [ -z "$VALUE" ]; then
          echo "Usage: $0 set <0-100>" >&2
          exit 1
       fi
       pamixer --set-volume "$VALUE"
      ;;
    *)
       echo "Usage: $0 <up|down|mute|unmute|get|set> [value]" >&2
       exit 1
       ;;
esac


