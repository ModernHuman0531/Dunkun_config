#!/usr/bin/env zsh
playerctl metadata --format '{{duration(position)}}/{{duration(mpris:length)}}' 2>/dev/null
