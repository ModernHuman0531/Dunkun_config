#!/usr/bin/env zsh
# ------------------------------------------------
# The scroll runner comes from: constantly call: `get_music_info.sh --np`
# 
# Usage: music-feeder.sh | scroll.py 26 0.2
# 
# In eww, use deflisten to monitor the whole pipeline:
# (deflisten music-marquee :initial "No music playing" "~/.config/eww/scripts/music-feeder.sh | ~/.config/eww/scripts/scroll.py 26 0.2")
# ---------------------------------------------

# $0 : means the current script's name
# :A : Means the absolute path, turn ./ into real path
# :h : Means cut off the last file's name like myscript.sh, only remain the previous path

FIELD="${1:-np}"
SCRIPT_DIR="${0:A:h}"
INFO_SCRIPT="$SCRIPT_DIR/get_music_info.sh"

# now and last varibale means the playing media's title and artist
last=""
while true; do
    now=$("$INFO_SCRIPT" --"$FIELD")
    # If the content really change the output new  line
    if [ "$now" != "$last" ]; then
        echo "$now"
        last="$now"
    fi
    # Check every 1s
    sleep 1
done
